local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local store = DataStoreService:GetDataStore(Config.DataStoreName)

local DataManager = {}
local sessions = {}

local function defaultData()
	return {
		coins = Config.StartingCoins,
		inventory = { Config.StartingCreature },
		placed = table.create(Config.MaxSlots, ""),
		lastOfflineClaim = os.time(),
		version = Config.DataVersion,
		revision = 0,
	}
end

local function validData(data)
	if typeof(data) ~= "table" or typeof(data.coins) ~= "number" or data.coins < 0
		or typeof(data.inventory) ~= "table" or typeof(data.placed) ~= "table"
		or (data.lastOfflineClaim ~= nil and typeof(data.lastOfflineClaim) ~= "number")
		or (data.lastSeen ~= nil and typeof(data.lastSeen) ~= "number")
		or (data.revision ~= nil and (typeof(data.revision) ~= "number" or data.revision < 0))
		or (data.session ~= nil and (typeof(data.session) ~= "table"
			or typeof(data.session.id) ~= "string" or typeof(data.session.heartbeat) ~= "number")) then
		return false
	end
	for _, name in data.inventory do
		if typeof(name) ~= "string" or not Config.info(name) then
			return false
		end
	end
	for i = 1, Config.MaxSlots do
		local name = data.placed[i]
		if name ~= nil and name ~= "" and (typeof(name) ~= "string" or not Config.info(name)) then
			return false
		end
	end
	return true
end

local function retry(operation)
	local lastError
	for attempt = 1, Config.DataStoreMaxAttempts do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < Config.DataStoreMaxAttempts then
			local backoff = math.min(Config.DataStoreRetryDelay * (2 ^ (attempt - 1)), Config.DataStoreRetryMaxDelay)
			task.wait(backoff + math.random() * Config.DataStoreRetryJitter)
		end
	end
	return false, lastError
end

local function dataPayload(data)
	return {
		coins = math.floor(data.coins),
		inventory = table.clone(data.inventory),
		placed = table.clone(data.placed),
		version = Config.DataVersion,
		revision = data.revision or 0,
	}
end

local function markLost(player, session, reason)
	if not session.active then
		return
	end
	session.active = false
	warn("[DataManager] Sessão invalidada para " .. player.Name .. ": " .. tostring(reason))
	if player.Parent then
		player:Kick("Sua sessão de dados foi interrompida. Entre novamente para proteger seu progresso.")
	end
end

function DataManager.load(player)
	local key = "u_" .. player.UserId
	local sessionId = game.JobId .. ":" .. HttpService:GenerateGUID(false)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			-- UpdateAsync may call this callback repeatedly. It performs only deterministic
			-- calculations and returns a value; it never yields or mutates external state.
			if old ~= nil and not validData(old) then
				return old
			end
			if old and old.session and old.session.id ~= "" and old.session.id ~= sessionId
				and operationNow - old.session.heartbeat < Config.SessionLockTimeout then
				return old
			end
			if old and old.session and old.session.id == sessionId then
				return old -- idempotent recovery after an unknown response
			end

			local data = old and table.clone(old) or defaultData()
			data.inventory = table.clone(data.inventory)
			data.placed = table.clone(data.placed)
			for i = 1, Config.MaxSlots do
				if data.placed[i] == nil then
					data.placed[i] = ""
				end
			end

			data.lastOfflineClaim = data.lastOfflineClaim or data.lastSeen or operationNow
			local elapsed = old and math.clamp(operationNow - data.lastOfflineClaim, 0, Config.MaxOfflineSeconds) or 0
			data.coins += math.floor(elapsed * DataManager.income(data))
			data.lastOfflineClaim = operationNow
			data.lastSeen = operationNow
			data.version = Config.DataVersion
			data.revision = (data.revision or 0) + 1
			data.session = { id = sessionId, heartbeat = operationNow }
			return data
		end)
	end)

	if not ok then
		warn("[DataManager] Falha/resultado desconhecido ao adquirir sessão para " .. player.Name .. ": " .. tostring(result))
		return nil, result
	end
	if not result or not validData(result) or not result.session or result.session.id ~= sessionId then
		return nil, "Sessão ocupada ou registro inválido"
	end
	local confirmedAge = math.max(0, os.time() - result.session.heartbeat)
	if confirmedAge >= Config.SessionLockTimeout - Config.SessionHeartbeatInterval then
		return nil, "Lease expirou antes da confirmação local"
	end

	result.session = nil -- the lock remains only in the stored record
	result.shieldUntil = 0
	sessions[player] = {
		data = result,
		id = sessionId,
		active = true,
		busy = false,
		confirmedAt = os.clock() - confirmedAge,
	}
	return result
end

function DataManager.get(player)
	local session = sessions[player]
	if session and session.active
		and os.clock() - session.confirmedAt < Config.SessionLockTimeout - Config.SessionHeartbeatInterval then
		return session.data
	end
	if session and session.active then
		markLost(player, session, "Lease sem renovação confirmada dentro da margem segura")
	end
	return nil
end

function DataManager.isActive(player)
	return DataManager.get(player) ~= nil
end

function DataManager.income(data)
	local total = 0
	for _, name in data.placed do
		if name ~= "" then
			local _, rarity = Config.info(name)
			if rarity then
				total += rarity.income
			end
		end
	end
	return total
end

function DataManager.save(player, releaseSession)
	local session = sessions[player]
	if not session or not session.active or not DataManager.get(player) then
		return false
	end
	while session.busy and session.active do
		task.wait(0.05)
	end
	if not session.active or sessions[player] ~= session then
		return false
	end
	session.busy = true

	local key = "u_" .. player.UserId
	local sessionId = session.id
	local snapshot = dataPayload(session.data)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			-- Pure callback: no yielding, notifications, cache mutation, or side effects.
			if not old or not old.session or old.session.id ~= sessionId then
				return old
			end
			local nextData = table.clone(snapshot)
			nextData.revision = (old.revision or 0) + 1
			nextData.lastSeen = operationNow
			nextData.lastOfflineClaim = operationNow
			if releaseSession then
				nextData.session = nil
				nextData.lastReleasedSession = sessionId
			else
				nextData.session = { id = sessionId, heartbeat = operationNow }
			end
			return nextData
		end)
	end)

	local ownsResult = ok and result ~= nil and result.lastReleasedSession == sessionId
	if not releaseSession and ok and result and result.session and result.session.id == sessionId
		and typeof(result.session.heartbeat) == "number" then
		ownsResult = true
	end
	local confirmedAge = 0
	if ownsResult and not releaseSession then
		confirmedAge = math.max(0, os.time() - result.session.heartbeat)
		if confirmedAge >= Config.SessionLockTimeout - Config.SessionHeartbeatInterval then
			ownsResult = false
		end
	end
	if not ownsResult then
		markLost(player, session, result or "Resultado desconhecido ao salvar/renovar sessão")
		session.busy = false
		return false
	end

	if releaseSession then
		session.active = false
		sessions[player] = nil
	else
		session.data.revision = result.revision or session.data.revision
		session.data.lastSeen = operationNow
		session.data.lastOfflineClaim = operationNow
		session.confirmedAt = os.clock() - confirmedAge
	end
	session.busy = false
	return true
end

return DataManager
