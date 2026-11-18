local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local transferStore = DataStoreService:GetDataStore(Config.TransferDataStoreName)

local DataManager = {}
local sessions = {}

local allowedDataFields = {
	coins = true,
	inventory = true,
	placed = true,
	lastOfflineClaim = true,
	lastSeen = true,
	version = true,
	revision = true,
	session = true,
	lastReleasedSession = true,
	shieldUntil = true,
	pendingTransfer = true,
	lastAppliedTransferId = true,
}

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

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value > -math.huge
		and value < math.huge
end

local function isNonNegativeFiniteNumber(value)
	return isFiniteNumber(value) and value >= 0
end

local function isNonNegativeInteger(value)
	return isNonNegativeFiniteNumber(value) and value % 1 == 0
end

local function isCreatureName(value)
	return typeof(value) == "string" and Config.info(value) ~= nil
end

local function validData(data)
	if typeof(data) ~= "table"
		or not isNonNegativeFiniteNumber(data.coins)
		or typeof(data.inventory) ~= "table"
		or typeof(data.placed) ~= "table"
		or (data.version ~= nil and data.version ~= Config.DataVersion)
		or (data.lastOfflineClaim ~= nil and not isNonNegativeFiniteNumber(data.lastOfflineClaim))
		or (data.lastSeen ~= nil and not isNonNegativeFiniteNumber(data.lastSeen))
		or (data.revision ~= nil and not isNonNegativeInteger(data.revision))
		or (data.lastReleasedSession ~= nil
			and (typeof(data.lastReleasedSession) ~= "string" or data.lastReleasedSession == ""))
		or (data.shieldUntil ~= nil and not isNonNegativeFiniteNumber(data.shieldUntil))
		or (data.pendingTransfer ~= nil and (typeof(data.pendingTransfer) ~= "string" or data.pendingTransfer == ""))
		or (data.lastAppliedTransferId ~= nil and (typeof(data.lastAppliedTransferId) ~= "string" or data.lastAppliedTransferId == ""))
		or (data.session ~= nil and (typeof(data.session) ~= "table"
			or typeof(data.session.id) ~= "string" or data.session.id == ""
			or not isNonNegativeFiniteNumber(data.session.heartbeat))) then
		return false
	end

	-- Version-less records are the supported legacy format. Any explicit version
	-- other than Config.DataVersion is rejected until a migration is implemented.
	-- Unknown top-level fields are rejected until an explicit migration
	-- defines how they are preserved. shieldUntil is transient and reset on load.
	for key in data do
		if typeof(key) ~= "string" or not allowedDataFields[key] then
			return false
		end
	end

	if data.session then
		for key in data.session do
			if key ~= "id" and key ~= "heartbeat" then
				return false
			end
		end
	end

	-- Inventory is a dense, one-based array. Sparse entries, dictionary keys,
	-- invalid creature names, and extra keys are rejected instead of being lost.
	local inventoryCount = 0
	local highestInventoryIndex = 0
	for index, name in data.inventory do
		if not isNonNegativeInteger(index) or index < 1 or not isCreatureName(name) then
			return false
		end
		inventoryCount += 1
		if index > highestInventoryIndex then
			highestInventoryIndex = index
		end
	end
	if highestInventoryIndex ~= inventoryCount then
		return false
	end

	-- Legacy saves may omit some of the six slot indexes; load() fills those
	-- missing indexes with empty strings. Keys outside the supported range fail.
	for index, name in data.placed do
		if not isNonNegativeInteger(index) or index < 1 or index > Config.MaxSlots then
			return false
		end
		if name ~= "" and not isCreatureName(name) then
			return false
		end
	end

	return true
end

local function isRetryableDataStoreError(reason)
	local message = string.lower(tostring(reason))
	local retryableMarkers = {
		"throttle",
		"datastorethrottled",
		"keythrottled",
		"internalservererror",
		"requestrejected",
		"updateasyncthrottle",
		"transformthrottle",
		"501:",
		"502:",
		"503:",
		"504:",
	}
	for _, marker in retryableMarkers do
		if string.find(message, marker, 1, true) then
			return true
		end
	end
	return false
end

local function retry(operation)
	local lastError
	for attempt = 1, Config.DataStoreMaxAttempts do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		if not isRetryableDataStoreError(lastError) then
			return false, lastError
		end
		if attempt < Config.DataStoreMaxAttempts then
			local backoff = math.min(Config.DataStoreRetryDelay * (2 ^ (attempt - 1)), Config.DataStoreRetryMaxDelay)
			task.wait(backoff + math.random() * Config.DataStoreRetryJitter)
		end
	end
	return false, lastError
end

local function readUncached(key)
	local options = Instance.new("DataStoreGetOptions")
	options.UseCache = false
	return pcall(function()
		return store:GetAsync(key, options)
	end)
end

local function sameArray(left, right)
	for key, value in left do
		if right[key] ~= value then
			return false
		end
	end
	for key, value in right do
		if left[key] ~= value then
			return false
		end
	end
	return true
end

local function matchesSavedPayload(current, snapshot)
	return current.coins == snapshot.coins
		and current.version == snapshot.version
		and current.revision > snapshot.revision
		and current.pendingTransfer == snapshot.pendingTransfer
		and current.lastAppliedTransferId == snapshot.lastAppliedTransferId
		and sameArray(current.inventory, snapshot.inventory)
		and sameArray(current.placed, snapshot.placed)
end

local function dataPayload(data)
	return {
		coins = math.floor(data.coins),
		inventory = table.clone(data.inventory),
		placed = table.clone(data.placed),
		version = Config.DataVersion,
		revision = data.revision or 0,
		pendingTransfer = data.pendingTransfer,
		lastAppliedTransferId = data.lastAppliedTransferId,
	}
end

local function markLost(player, session, reason)
	if not session.active then
		return
	end
	session.active = false
	session.transferBusy = false
	if sessions[player] == session then
		sessions[player] = nil
	end
	warn("[DataManager] Sessão invalidada para " .. player.Name .. ": " .. tostring(reason))
	if player.Parent then
		player:Kick("Sua sessão de dados foi interrompida. Entre novamente para proteger seu progresso.")
	end
end


local function transferKey(id)
	return "t_" .. id
end

local function validTransferRecord(record)
	if typeof(record) ~= "table"
		or typeof(record.id) ~= "string" or record.id == ""
		or record.schemaVersion ~= 1
		or (record.status ~= "PREPARING" and record.status ~= "COMMITTED"
			and record.status ~= "APPLIED" and record.status ~= "COMPLETED"
			and record.status ~= "ABORTED")
		or not isNonNegativeInteger(record.victimUserId) or record.victimUserId < 1
		or not isNonNegativeInteger(record.thiefUserId) or record.thiefUserId < 1
		or record.victimUserId == record.thiefUserId
		or not isNonNegativeInteger(record.slotIndex)
		or record.slotIndex < 1 or record.slotIndex > Config.MaxSlots
		or not isCreatureName(record.creatureName)
		or not isNonNegativeInteger(record.destinationInventoryCount)
		or not isNonNegativeFiniteNumber(record.createdAt)
		or (record.recoverySessionId ~= nil
			and (typeof(record.recoverySessionId) ~= "string" or record.recoverySessionId == ""))
		or (record.recoveryHeartbeat ~= nil and not isNonNegativeFiniteNumber(record.recoveryHeartbeat))
		or ((record.recoverySessionId == nil) ~= (record.recoveryHeartbeat == nil)) then
		return false
	end

	for key in record do
		if key ~= "id" and key ~= "schemaVersion" and key ~= "status"
			and key ~= "victimUserId" and key ~= "thiefUserId"
			and key ~= "slotIndex" and key ~= "creatureName"
			and key ~= "destinationInventoryCount" and key ~= "createdAt"
			and key ~= "recoverySessionId" and key ~= "recoveryHeartbeat" then
			return false
		end
	end
	return true
end

local function readTransferUncached(id)
	local options = Instance.new("DataStoreGetOptions")
	options.UseCache = false
	return pcall(function()
		return transferStore:GetAsync(transferKey(id), options)
	end)
end

local function readTransferRecord(id)
	local ok, record = readTransferUncached(id)
	if not ok or not validTransferRecord(record) or record.id ~= id then
		return nil, record
	end
	return record
end

local function sameTransferIdentity(left, right)
	return validTransferRecord(left)
		and left.id == right.id
		and left.victimUserId == right.victimUserId
		and left.thiefUserId == right.thiefUserId
		and left.slotIndex == right.slotIndex
		and left.creatureName == right.creatureName
		and left.destinationInventoryCount == right.destinationInventoryCount
end

local function createTransferRecord(record)
	local ok, result = retry(function()
		return transferStore:UpdateAsync(transferKey(record.id), function(old)
			if old ~= nil then
				if sameTransferIdentity(old, record) then
					return old
				end
				return nil
			end
			return table.clone(record)
		end)
	end)

	if ok and sameTransferIdentity(result, record) then
		return true, result
	end

	local verified = readTransferRecord(record.id)
	if verified and sameTransferIdentity(verified, record) then
		return true, verified
	end
	return false, result
end

local function transitionTransfer(id, expectedStatus, nextStatus, recoverySessionId)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return transferStore:UpdateAsync(transferKey(id), function(old)
			if not validTransferRecord(old) then
				return nil
			end
			if recoverySessionId and old.recoverySessionId ~= recoverySessionId then
				return nil
			end
			if old.status == nextStatus then
				return old
			end
			if old.status ~= expectedStatus then
				return nil
			end
			local updated = table.clone(old)
			updated.status = nextStatus
			if recoverySessionId then
				updated.recoveryHeartbeat = operationNow
			end
			return updated
		end)
	end)

	if ok and validTransferRecord(result) and result.status == nextStatus then
		return true, result
	end

	local verified = readTransferRecord(id)
	if verified and verified.status == nextStatus
		and (not recoverySessionId or verified.recoverySessionId == recoverySessionId) then
		return true, verified
	end
	return false, result or verified
end


local function acquireTransferRecoveryLease(id, recoverySessionId)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return transferStore:UpdateAsync(transferKey(id), function(old)
			if not validTransferRecord(old) then
				return nil
			end
			if old.recoverySessionId and old.recoverySessionId ~= recoverySessionId
				and operationNow - old.recoveryHeartbeat < Config.SessionLockTimeout then
				return nil
			end
			local updated = table.clone(old)
			updated.recoverySessionId = recoverySessionId
			updated.recoveryHeartbeat = operationNow
			return updated
		end)
	end)

	if ok and validTransferRecord(result) and result.recoverySessionId == recoverySessionId then
		return true, result
	end

	local verified = readTransferRecord(id)
	if verified and verified.recoverySessionId == recoverySessionId then
		return true, verified
	end
	return false, result or verified
end

local function releaseTransferRecoveryLease(id, recoverySessionId)
	local ok, result = retry(function()
		return transferStore:UpdateAsync(transferKey(id), function(old)
			if not validTransferRecord(old) then
				return nil
			end
			if old.recoverySessionId ~= recoverySessionId then
				return old
			end
			local updated = table.clone(old)
			updated.recoverySessionId = nil
			updated.recoveryHeartbeat = nil
			return updated
		end)
	end)

	if ok and validTransferRecord(result)
		and result.recoverySessionId ~= recoverySessionId then
		return true
	end

	local verified = readTransferRecord(id)
	if verified and verified.recoverySessionId ~= recoverySessionId then
		return true
	end
	return false, result or verified
end

local function updateProfileForSession(userId, sessionId, transform, verify)
	local key = "u_" .. tostring(userId)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			if not old or not validData(old) or not old.session
				or old.session.id ~= sessionId
				or operationNow - old.session.heartbeat >= Config.SessionLockTimeout - Config.SessionHeartbeatInterval then
				return nil
			end
			return transform(old, operationNow)
		end)
	end)

	if ok and result and validData(result) and verify(result) then
		return true, result
	end

	local verifyOk, verified = readUncached(key)
	if verifyOk and verified and validData(verified) and verify(verified) then
		return true, verified
	end
	return false, result or verified
end

local function copyPersistedProfileToSession(session, persisted)
	local shieldUntil = session.data.shieldUntil or 0
	local updatedData = table.clone(persisted)
	updatedData.session = nil
	updatedData.shieldUntil = shieldUntil
	session.data = updatedData
	if persisted.session and isNonNegativeFiniteNumber(persisted.session.heartbeat) then
		local age = math.max(0, os.time() - persisted.session.heartbeat)
		session.confirmedAt = os.clock() - age
	end
end

local function reserveProfileForTransfer(player, session, transferId)
	local snapshot = dataPayload(session.data)
	return updateProfileForSession(player.UserId, session.id, function(old, operationNow)
		if not old or not validData(old) or not old.session or old.session.id ~= session.id then
			return nil
		end
		if old.pendingTransfer == transferId then
			return old
		end
		if old.pendingTransfer ~= nil then
			return nil
		end

		local updated = table.clone(snapshot)
		updated.pendingTransfer = transferId
		updated.revision = (old.revision or 0) + 1
		updated.lastSeen = operationNow
		updated.lastOfflineClaim = operationNow
		updated.session = { id = session.id, heartbeat = operationNow }
		return updated
	end, function(current)
		return current.session ~= nil
			and current.session.id == session.id
			and current.pendingTransfer == transferId
	end)
end

local function applyTransferToProfile(userId, sessionId, record, side)
	return updateProfileForSession(userId, sessionId, function(old, operationNow)
		if not old or not validData(old) or not old.session or old.session.id ~= sessionId
			or old.pendingTransfer ~= record.id then
			return nil
		end

		if old.lastAppliedTransferId == record.id then
			if side == "source" then
				return if old.placed[record.slotIndex] == "" then old else nil
			end
			return if side == "destination" and #old.inventory == record.destinationInventoryCount + 1 then old else nil
		end

		local updated = table.clone(old)
		if side == "source" then
			if updated.placed[record.slotIndex] ~= record.creatureName then
				return nil
			end
			updated.placed = table.clone(updated.placed)
			updated.placed[record.slotIndex] = ""
		elseif side == "destination" then
			if #updated.inventory ~= record.destinationInventoryCount then
				return nil
			end
			updated.inventory = table.clone(updated.inventory)
			table.insert(updated.inventory, record.creatureName)
		else
			return nil
		end

		updated.lastAppliedTransferId = record.id
		updated.revision = (old.revision or 0) + 1
		updated.lastSeen = operationNow
		-- Preserve lastOfflineClaim so recovery does not discard income accrued while transfer was pending.
		updated.session = { id = sessionId, heartbeat = operationNow }
		return updated
	end, function(current)
		if not current.session or current.session.id ~= sessionId
			or current.pendingTransfer ~= record.id
			or current.lastAppliedTransferId ~= record.id then
			return false
		end
		if side == "source" then
			return current.placed[record.slotIndex] == ""
		end
		if side == "destination" then
			return #current.inventory == record.destinationInventoryCount + 1
		end
		return false
	end)
end

local function clearProfileTransferReservation(userId, sessionId, transferId)
	return updateProfileForSession(userId, sessionId, function(old, operationNow)
		if not old or not validData(old) or not old.session or old.session.id ~= sessionId then
			return nil
		end
		if old.pendingTransfer == nil then
			return old
		end
		if old.pendingTransfer ~= transferId then
			return nil
		end

		local updated = table.clone(old)
		updated.pendingTransfer = nil
		updated.revision = (old.revision or 0) + 1
		updated.lastSeen = operationNow
		updated.session = { id = sessionId, heartbeat = operationNow }
		return updated
	end, function(current)
		return current.session ~= nil
			and current.session.id == sessionId
			and current.pendingTransfer == nil
	end)
end

local function releaseProfileLock(userId, sessionId)
	local key = "u_" .. tostring(userId)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			if not old or not validData(old) then
				return nil
			end
			if old.lastReleasedSession == sessionId and (not old.session or old.session.id ~= sessionId) then
				return old
			end
			if not old.session or old.session.id ~= sessionId then
				return nil
			end
			local updated = table.clone(old)
			updated.session = nil
			updated.lastReleasedSession = sessionId
			updated.lastSeen = operationNow
			return updated
		end)
	end)

	if ok and result and validData(result)
		and result.lastReleasedSession == sessionId
		and (not result.session or result.session.id ~= sessionId) then
		return true
	end

	local verifyOk, verified = readUncached(key)
	if verifyOk and verified and validData(verified)
		and verified.lastReleasedSession == sessionId
		and (not verified.session or verified.session.id ~= sessionId) then
		return true
	end
	return false, result or verified
end

local function acquireRecoveryProfile(userId, recoverySessionId, transferId)
	local key = "u_" .. tostring(userId)
	local operationNow = os.time()
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			if not old or not validData(old) or old.pendingTransfer ~= transferId then
				return nil
			end
			if old.session and old.session.id ~= recoverySessionId
				and operationNow - old.session.heartbeat < Config.SessionLockTimeout then
				return nil
			end
			if old.session and old.session.id == recoverySessionId then
				return old
			end

			local updated = table.clone(old)
			updated.session = { id = recoverySessionId, heartbeat = operationNow }
			return updated
		end)
	end)

	if not ok or not result or not validData(result) or not result.session
		or result.session.id ~= recoverySessionId or result.pendingTransfer ~= transferId then
		local verifyOk, verified = readUncached(key)
		if verifyOk and verified and validData(verified) and verified.session
			and verified.session.id == recoverySessionId and verified.pendingTransfer == transferId then
			result = verified
		else
			return nil, result or verified
		end
	end

	local age = math.max(0, os.time() - result.session.heartbeat)
	if age >= Config.SessionLockTimeout - Config.SessionHeartbeatInterval then
		return nil, "Lease de recuperação expirou antes da confirmação"
	end
	return result
end

local function claimOfflineForSession(player, session)
	local key = "u_" .. tostring(player.UserId)
	local operationNow = os.time()
	local startingRevision = session.data.revision or 0
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			if not old or not validData(old) or not old.session
				or old.session.id ~= session.id or old.pendingTransfer ~= nil then
				return nil
			end

			local updated = table.clone(old)
			local lastClaim = old.lastOfflineClaim or old.lastSeen or operationNow
			local elapsed = math.clamp(operationNow - lastClaim, 0, Config.MaxOfflineSeconds)
			updated.coins += math.floor(elapsed * DataManager.income(old))
			updated.lastOfflineClaim = operationNow
			updated.lastSeen = operationNow
			updated.revision = (old.revision or 0) + 1
			updated.session = { id = session.id, heartbeat = operationNow }
			return updated
		end)
	end)

	if not ok or not result or not validData(result) or not result.session
		or result.session.id ~= session.id or result.pendingTransfer ~= nil
		or result.lastOfflineClaim ~= operationNow or result.revision <= startingRevision then
		local verifyOk, verified = readUncached(key)
		if not verifyOk or not verified or not validData(verified)
			or not verified.session or verified.session.id ~= session.id
			or verified.pendingTransfer ~= nil
			or verified.lastOfflineClaim ~= operationNow
			or verified.revision <= startingRevision then
			return false, result or verified
		end
		result = verified
	end

	copyPersistedProfileToSession(session, result)
	return true
end

local function recoverPendingTransfer(player, session)
	local transferId = session.data.pendingTransfer
	local record, readError = readTransferRecord(transferId)
	if not record then
		return false, "Journal de transferência ausente/inválido: " .. tostring(readError)
	end

	local userId = player.UserId
	local isVictim = record.victimUserId == userId
	local isThief = record.thiefUserId == userId
	if not isVictim and not isThief then
		return false, "O perfil não corresponde a um participante do journal"
	end

	if record.status == "PREPARING" then
		local aborted = transitionTransfer(transferId, "PREPARING", "ABORTED")
		if not aborted then
			record = readTransferRecord(transferId)
		else
			record.status = "ABORTED"
		end
	end

	if record and record.status == "ABORTED" then
		local cleared, persisted = clearProfileTransferReservation(userId, session.id, transferId)
		if not cleared then
			return false, "Não foi possível limpar a reserva de uma transferência abortada"
		end
		copyPersistedProfileToSession(session, persisted)
		return true
	end

	if record and (record.status == "APPLIED" or record.status == "COMPLETED") then
		if session.data.lastAppliedTransferId ~= transferId then
			return false, "Journal aplicado, mas o perfil não confirma a aplicação"
		end
		local cleared, persisted = clearProfileTransferReservation(userId, session.id, transferId)
		if not cleared then
			return false, "Não foi possível limpar a reserva de uma transferência aplicada"
		end
		copyPersistedProfileToSession(session, persisted)

		if record.status == "APPLIED" then
			local otherUserId = if isVictim then record.thiefUserId else record.victimUserId
			local otherOk, otherProfile = readUncached("u_" .. tostring(otherUserId))
			if otherOk and otherProfile and validData(otherProfile)
				and otherProfile.pendingTransfer ~= transferId then
				transitionTransfer(transferId, "APPLIED", "COMPLETED")
			end
		end
		return true
	end

	if not record or record.status ~= "COMMITTED" then
		return false, "Estado de journal não recuperável: " .. tostring(record and record.status)
	end

	local otherUserId = if isVictim then record.thiefUserId else record.victimUserId
	local recoverySessionId = game.JobId .. ":transfer-recovery:" .. HttpService:GenerateGUID(false)
	local otherProfile, lockError = acquireRecoveryProfile(otherUserId, recoverySessionId, transferId)
	if not otherProfile then
		return false, "Não foi possível adquirir o outro perfil para recuperação: " .. tostring(lockError)
	end

	local ownSide = if isVictim then "source" else "destination"
	local otherSide = if isVictim then "destination" else "source"
	local ownApplied = applyTransferToProfile(userId, session.id, record, ownSide)
	local otherApplied = applyTransferToProfile(otherUserId, recoverySessionId, record, otherSide)

	local ownVerifyOk, ownVerify = readUncached("u_" .. tostring(userId))
	local otherVerifyOk, otherVerify = readUncached("u_" .. tostring(otherUserId))
	local bothApplied = ownApplied and otherApplied
		and ownVerifyOk and otherVerifyOk
		and ownVerify and otherVerify
		and validData(ownVerify) and validData(otherVerify)
		and ownVerify.session and ownVerify.session.id == session.id
		and otherVerify.session and otherVerify.session.id == recoverySessionId
		and ownVerify.pendingTransfer == transferId
		and otherVerify.pendingTransfer == transferId
		and ownVerify.lastAppliedTransferId == transferId
		and otherVerify.lastAppliedTransferId == transferId

	if not bothApplied then
		releaseProfileLock(otherUserId, recoverySessionId)
		return false, "A recuperação não confirmou a aplicação nos dois perfis"
	end

	local advanced = transitionTransfer(transferId, "COMMITTED", "APPLIED")
	if not advanced then
		record = readTransferRecord(transferId)
		if not record or (record.status ~= "APPLIED" and record.status ~= "COMPLETED") then
			releaseProfileLock(otherUserId, recoverySessionId)
			return false, "Não foi possível confirmar o estado APPLIED do journal"
		end
	end

	local ownCleared, ownPersisted = clearProfileTransferReservation(userId, session.id, transferId)
	local otherCleared = clearProfileTransferReservation(otherUserId, recoverySessionId, transferId)
	releaseProfileLock(otherUserId, recoverySessionId)

	if not ownCleared then
		return false, "A transferência foi aplicada, mas a reserva do perfil atual não pôde ser removida"
	end

	copyPersistedProfileToSession(session, ownPersisted)
	if otherCleared then
		local otherOk, otherFinal = readUncached("u_" .. tostring(otherUserId))
		local ownOk, ownFinal = readUncached("u_" .. tostring(userId))
		if ownOk and otherOk and ownFinal and otherFinal
			and validData(ownFinal) and validData(otherFinal)
			and ownFinal.pendingTransfer == nil and otherFinal.pendingTransfer == nil then
			transitionTransfer(transferId, "APPLIED", "COMPLETED")
		end
	end
	return true
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
				return nil -- Preserve malformed or unsupported-version records unchanged.
			end
			if old and old.session and old.session.id ~= sessionId
				and operationNow - old.session.heartbeat < Config.SessionLockTimeout then
				return nil -- Another active session owns this key.
			end
			if old and old.session and old.session.id == sessionId then
				return old -- Idempotent recovery after an unknown response.
			end

			local data = old and table.clone(old) or defaultData()
			data.inventory = table.clone(data.inventory)
			data.placed = table.clone(data.placed)
			for i = 1, Config.MaxSlots do
				if data.placed[i] == nil then
					data.placed[i] = ""
				end
			end

			-- Offline income is calculated only after any pending transfer is recovered.
			-- This prevents using a half-applied inventory as the income source.
			data.lastOfflineClaim = data.lastOfflineClaim or data.lastSeen or operationNow
			data.lastSeen = operationNow
			data.version = Config.DataVersion
			data.revision = (data.revision or 0) + 1
			data.session = { id = sessionId, heartbeat = operationNow }
			return data
		end)
	end)

	if not ok then
		local verifyOk, verified = readUncached(key)
		if verifyOk and verified and validData(verified) and verified.session
			and verified.session.id == sessionId then
			result = verified
			ok = true
			warn("[DataManager] Aquisição de sessão confirmada por leitura sem cache após resposta ambígua para " .. player.Name)
		else
			warn("[DataManager] Falha/resultado desconhecido ao adquirir sessão para " .. player.Name .. ": " .. tostring(result))
			return nil, result
		end
	end
	if not result or not validData(result) or not result.session or result.session.id ~= sessionId then
		return nil, "Sessão ocupada ou registro inválido"
	end
	local confirmedAge = math.max(0, os.time() - result.session.heartbeat)
	if confirmedAge >= Config.SessionLockTimeout - Config.SessionHeartbeatInterval then
		return nil, "Lease expirou antes da confirmação local"
	end

	result.session = nil -- The lock remains only in the stored record.
	result.shieldUntil = 0
	local session = {
		data = result,
		id = sessionId,
		active = true,
		busy = false,
		transferBusy = false,
		confirmedAt = os.clock() - confirmedAge,
	}
	sessions[player] = session

	if session.data.pendingTransfer then
		local recovered, recoveryError = recoverPendingTransfer(player, session)
		if not recovered then
			releaseProfileLock(player.UserId, sessionId)
			session.active = false
			sessions[player] = nil
			return nil, recoveryError
		end
	end

	local offlineClaimed, offlineError = claimOfflineForSession(player, session)
	if not offlineClaimed then
		releaseProfileLock(player.UserId, sessionId)
		session.active = false
		sessions[player] = nil
		return nil, "Não foi possível confirmar o crédito offline: " .. tostring(offlineError)
	end

	return session.data
end

function DataManager.get(player)
	local session = sessions[player]
	if session and session.active and session.transferBusy then
		return nil
	end
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
	for index = 1, Config.MaxSlots do
		local name = data.placed[index]
		if name ~= nil and name ~= "" then
			local _, rarity = Config.info(name)
			if rarity then
				total += rarity.income
			end
		end
	end
	return total
end


local function performTransfer(victim, thief, slotIndex, creatureName)
	if not Config.StealingEnabled then
		return false, "Roubo desativado até a validação do protocolo de transferência"
	end
	if victim == thief or not victim.Parent or not thief.Parent
		or not isNonNegativeInteger(slotIndex) or slotIndex < 1 or slotIndex > Config.MaxSlots
		or not isCreatureName(creatureName) then
		return false, "Argumentos de transferência inválidos"
	end

	local victimSession = sessions[victim]
	local thiefSession = sessions[thief]
	if not victimSession or not thiefSession or not victimSession.active or not thiefSession.active then
		return false, "Sessão de um participante indisponível"
	end

	while (victimSession.busy or thiefSession.busy) and victimSession.active and thiefSession.active do
		if victimSession.transferBusy or thiefSession.transferBusy then
			return false, "Um dos participantes já está em outra transferência"
		end
		task.wait(0.05)
	end

	if not victimSession.active or not thiefSession.active
		or sessions[victim] ~= victimSession or sessions[thief] ~= thiefSession
		or victimSession.transferBusy or thiefSession.transferBusy
		or not DataManager.get(victim) or not DataManager.get(thief) then
		return false, "Sessão indisponível para iniciar a transferência"
	end

	if victimSession.data.placed[slotIndex] ~= creatureName then
		return false, "A criatura não está mais no slot informado"
	end

	victimSession.transferBusy = true
	thiefSession.transferBusy = true

	local transferId = HttpService:GenerateGUID(false)
	local record = {
		id = transferId,
		schemaVersion = 1,
		status = "PREPARING",
		victimUserId = victim.UserId,
		thiefUserId = thief.UserId,
		slotIndex = slotIndex,
		creatureName = creatureName,
		destinationInventoryCount = #thiefSession.data.inventory,
		createdAt = os.time(),
	}

	local function unlockBoth()
		if sessions[victim] == victimSession and victimSession.active then
			victimSession.transferBusy = false
		end
		if sessions[thief] == thiefSession and thiefSession.active then
			thiefSession.transferBusy = false
		end
	end

	local function invalidateBoth(reason)
		victimSession.transferBusy = false
		thiefSession.transferBusy = false
		markLost(victim, victimSession, reason)
		markLost(thief, thiefSession, reason)
		return false, reason
	end

	local function abortPreparing(reason)
		local aborted = transitionTransfer(transferId, "PREPARING", "ABORTED")
		local currentRecord = readTransferRecord(transferId)
		if not aborted and (not currentRecord or currentRecord.status ~= "ABORTED") then
			return invalidateBoth("Não foi possível confirmar o cancelamento seguro: " .. tostring(reason))
		end

		local victimCleared, victimPersisted = clearProfileTransferReservation(
			victim.UserId, victimSession.id, transferId
		)
		local thiefCleared, thiefPersisted = clearProfileTransferReservation(
			thief.UserId, thiefSession.id, transferId
		)
		if not victimCleared or not thiefCleared then
			return invalidateBoth("Transferência abortada, mas não foi possível limpar todas as reservas")
		end

		copyPersistedProfileToSession(victimSession, victimPersisted)
		copyPersistedProfileToSession(thiefSession, thiefPersisted)
		unlockBoth()
		return false, reason
	end

	local journalCreated = createTransferRecord(record)
	if not journalCreated then
		unlockBoth()
		return false, "Não foi possível criar o registro persistente da transferência"
	end

	local victimReserved, victimReservation = reserveProfileForTransfer(victim, victimSession, transferId)
	if not victimReserved then
		return abortPreparing("Não foi possível reservar o perfil da vítima")
	end
	copyPersistedProfileToSession(victimSession, victimReservation)

	local thiefReserved, thiefReservation = reserveProfileForTransfer(thief, thiefSession, transferId)
	if not thiefReserved then
		return abortPreparing("Não foi possível reservar o perfil do ladrão")
	end
	copyPersistedProfileToSession(thiefSession, thiefReservation)

	local committed = transitionTransfer(transferId, "PREPARING", "COMMITTED")
	if not committed then
		local currentRecord = readTransferRecord(transferId)
		if currentRecord and currentRecord.status == "COMMITTED" then
			committed = true
		elseif currentRecord and currentRecord.status == "PREPARING" then
			return abortPreparing("A decisão COMMITTED não foi persistida")
		else
			return invalidateBoth("Resultado ambíguo ao confirmar a transferência")
		end
	end

	local victimApplied, victimPersisted = applyTransferToProfile(
		victim.UserId, victimSession.id, record, "source"
	)
	local thiefApplied, thiefPersisted = applyTransferToProfile(
		thief.UserId, thiefSession.id, record, "destination"
	)
	if not victimApplied or not thiefApplied then
		return invalidateBoth("Transferência confirmada, mas a aplicação precisa ser recuperada")
	end

	local victimVerifyOk, victimVerify = readUncached("u_" .. tostring(victim.UserId))
	local thiefVerifyOk, thiefVerify = readUncached("u_" .. tostring(thief.UserId))
	local bothApplied = victimVerifyOk and thiefVerifyOk
		and victimVerify and thiefVerify
		and validData(victimVerify) and validData(thiefVerify)
		and victimVerify.session and victimVerify.session.id == victimSession.id
		and thiefVerify.session and thiefVerify.session.id == thiefSession.id
		and victimVerify.pendingTransfer == transferId
		and thiefVerify.pendingTransfer == transferId
		and victimVerify.lastAppliedTransferId == transferId
		and thiefVerify.lastAppliedTransferId == transferId
		and victimVerify.placed[slotIndex] == ""
		and #thiefVerify.inventory == record.destinationInventoryCount + 1
	if not bothApplied then
		return invalidateBoth("Não foi possível verificar a aplicação nos dois perfis")
	end

	local applied = transitionTransfer(transferId, "COMMITTED", "APPLIED")
	if not applied then
		local currentRecord = readTransferRecord(transferId)
		if not currentRecord or (currentRecord.status ~= "APPLIED" and currentRecord.status ~= "COMPLETED") then
			return invalidateBoth("A transferência foi aplicada, mas o estado APPLIED não foi confirmado")
		end
	end

	local victimCleared, victimFinal = clearProfileTransferReservation(
		victim.UserId, victimSession.id, transferId
	)
	local thiefCleared, thiefFinal = clearProfileTransferReservation(
		thief.UserId, thiefSession.id, transferId
	)

	if victimCleared then
		copyPersistedProfileToSession(victimSession, victimFinal)
	else
		victimSession.transferBusy = false
		markLost(victim, victimSession, "Transferência aplicada; reserva da vítima será recuperada na próxima entrada")
	end

	if thiefCleared then
		copyPersistedProfileToSession(thiefSession, thiefFinal)
	else
		thiefSession.transferBusy = false
		markLost(thief, thiefSession, "Transferência aplicada; reserva do ladrão será recuperada na próxima entrada")
	end

	if victimCleared and thiefCleared then
		local victimOk, victimCheck = readUncached("u_" .. tostring(victim.UserId))
		local thiefOk, thiefCheck = readUncached("u_" .. tostring(thief.UserId))
		if victimOk and thiefOk and victimCheck and thiefCheck
			and validData(victimCheck) and validData(thiefCheck)
			and victimCheck.pendingTransfer == nil and thiefCheck.pendingTransfer == nil then
			transitionTransfer(transferId, "APPLIED", "COMPLETED")
		end
	end

	unlockBoth()
	return true
end

function DataManager.transfer(victim, thief, slotIndex, creatureName)
	local victimSession = sessions[victim]
	local thiefSession = sessions[thief]
	local ok, transferred, reason = pcall(
		performTransfer,
		victim,
		thief,
		slotIndex,
		creatureName
	)
	if not ok then
		warn("[DataManager] Erro inesperado durante transferência: " .. tostring(transferred))
		if victimSession and victimSession.active then
			victimSession.transferBusy = false
			markLost(victim, victimSession, "Erro interno durante transferência; recuperação obrigatória")
		end
		if thiefSession and thiefSession.active then
			thiefSession.transferBusy = false
			markLost(thief, thiefSession, "Erro interno durante transferência; recuperação obrigatória")
		end
		return false, "Erro interno; os dois perfis foram bloqueados para recuperação"
	end
	return transferred, reason
end

function DataManager.save(player, releaseSession)
	local session = sessions[player]
	if not session or not session.active then
		return false
	end
	while (session.busy or session.transferBusy) and session.active do
		task.wait(0.05)
	end
	if not session.active or sessions[player] ~= session or not DataManager.get(player) then
		return false
	end
	session.busy = true

	if not validData(session.data) then
		session.busy = false
		markLost(player, session, "Dados em memória inválidos; salvamento cancelado")
		return false
	end

	local key = "u_" .. player.UserId
	local sessionId = session.id
	local snapshot = dataPayload(session.data)
	local saveStartedAt = os.time()
	local operationNow = saveStartedAt
	local ok, result = retry(function()
		operationNow = os.time()
		return store:UpdateAsync(key, function(old)
			-- Pure callback: no yielding, notifications, cache mutation, or side effects.
			if not old or not validData(old) then
				return nil -- Never overwrite a missing or malformed record.
			end
			if releaseSession and old.lastReleasedSession == sessionId
				and (not old.session or old.session.id ~= sessionId) then
				return old -- An earlier attempt already released this session; do not touch a newer lock.
			end
			if not old.session or old.session.id ~= sessionId then
				return nil -- Never overwrite a record owned by another session.
			end
			if old.pendingTransfer ~= nil or snapshot.pendingTransfer ~= nil then
				return nil -- A normal save must never modify a profile reserved by a transfer.
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

	if not ok then
		local verifyOk, verified = readUncached(key)
		if verifyOk and verified and validData(verified) then
			if releaseSession and verified.lastReleasedSession == sessionId
				and (not verified.session or verified.session.id ~= sessionId) then
				result = verified
				ok = true
				warn("[DataManager] Liberação de sessão confirmada por leitura sem cache após resposta ambígua para " .. player.Name)
			elseif not releaseSession and verified.session and verified.session.id == sessionId
				and verified.session.heartbeat >= saveStartedAt
				and matchesSavedPayload(verified, snapshot) then
				result = verified
				ok = true
				warn("[DataManager] Salvamento confirmado por leitura sem cache após resposta ambígua para " .. player.Name)
			end
		end
	end

	local ownsResult = ok and result ~= nil and result.lastReleasedSession == sessionId
	if not releaseSession and ok and result and result.session and result.session.id == sessionId
		and isNonNegativeFiniteNumber(result.session.heartbeat) then
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
	if not session.active or sessions[player] ~= session then
		-- Another path invalidated this session while the DataStore request was yielding.
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
