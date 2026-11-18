local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

-- ===== Remotes =====
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local actionEvent = makeRemote("Action")
local updateEvent = makeRemote("Update")
local notifyEvent = makeRemote("Notify")

-- ===== Estado =====
local PLOT_SPACING = 60
local SLOT_OFFSETS = {
	Vector3.new(-12, 0, -8), Vector3.new(0, 0, -8), Vector3.new(12, 0, -8),
	Vector3.new(-12, 0, 8), Vector3.new(0, 0, 8), Vector3.new(12, 0, 8),
}
local plots = {}
local playerPlot = {}
local lastAction = {}
local stealCooldown = {}
local shuttingDown = false
local activeTransfers = {}
local loadingPlayers = {}

-- ===== Helpers =====
local function notify(player, msg)
	notifyEvent:FireClient(player, msg)
end

local function sendUpdate(player)
	local d = DataManager.get(player)
	if not d then
		return
	end
	updateEvent:FireClient(player, {
		coins = math.floor(d.coins),
		income = DataManager.income(d),
		placed = d.placed,
		inventory = d.inventory,
	})
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Coins") then
		stats.Coins.Value = math.floor(d.coins)
	end
end

local function refreshSlot(plot, i)
	local slot = plot.slots[i]
	local prompt = slot:FindFirstChildOfClass("ProximityPrompt")
	local info = slot:FindFirstChild("Info")
	local text = info and info:FindFirstChild("Text")
	local d = plot.owner and DataManager.get(plot.owner)
	local name = (d and d.placed[i]) or ""

	if name ~= "" then
		local _, rarity = Config.info(name)
		slot.Color = rarity.color
		slot.Material = Enum.Material.Neon
		text.Text = name .. "\n" .. rarity.name .. " · +" .. rarity.income .. "/s"
		info.Enabled = true
		prompt.ObjectText = name
		prompt.Enabled = true
	else
		slot.Color = Color3.fromRGB(230, 230, 230)
		slot.Material = Enum.Material.SmoothPlastic
		info.Enabled = false
		prompt.Enabled = false
	end
end

local function refreshPlot(plot)
	for i = 1, #plot.slots do
		refreshSlot(plot, i)
	end
end

local function setOwnerTag(plot)
	plot.tagText.Text = plot.owner and (plot.owner.Name .. " · Base") or "Base livre"
end

local function pickup(player, plot, i)
	local d = DataManager.get(player)
	if not d or typeof(i) ~= "number" or i % 1 ~= 0 or i < 1 or i > Config.MaxSlots then
		return
	end
	if typeof(d.placed[i]) ~= "string" or d.placed[i] == "" or not Config.info(d.placed[i]) then
		return
	end
	table.insert(d.inventory, d.placed[i])
	d.placed[i] = ""
	refreshSlot(plot, i)
	notify(player, "Você guardou o brainrot no inventário.")
	sendUpdate(player)
end

local function steal(thief, plot, i)
	if not Config.StealingEnabled or typeof(DataManager.transfer) ~= "function" then
		notify(thief, "O roubo está temporariamente desativado enquanto protegemos a transferência de criaturas.")
		return
	end
	if typeof(i) ~= "number" or i % 1 ~= 0 or i < 1 or i > Config.MaxSlots or not plot.slots[i] then
		return
	end
	local victim = plot.owner
	if not victim or victim == thief then
		return
	end
	if not thief.Parent or not victim.Parent or playerPlot[thief] == nil or playerPlot[victim] ~= plot then
		return
	end
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or (root.Position - plot.slots[i].Position).Magnitude > 10 then
		return
	end
	local vd = DataManager.get(victim)
	local td = DataManager.get(thief)
	if not vd or not td then
		return
	end
	if not playerPlot[thief] or playerPlot[victim] ~= plot then
		return
	end
	local name = vd.placed[i]
	if typeof(name) ~= "string" or name == "" or not Config.info(name) then
		return
	end
	local transferKey = tostring(victim.UserId) .. ":" .. tostring(i)
	if activeTransfers[transferKey] then
		return
	end

	local now = os.time()
	if now < (vd.shieldUntil or 0) then
		notify(thief, "Essa base está protegida agora!")
		return
	end
	if now < (stealCooldown[thief] or 0) then
		notify(thief, "Espere um pouco antes de roubar de novo.")
		return
	end

	activeTransfers[transferKey] = true
	if vd.placed[i] ~= name or plot.owner ~= victim then
		activeTransfers[transferKey] = nil
		return
	end

	local transferred = DataManager.transfer(victim, thief, i, name)
	activeTransfers[transferKey] = nil
	if not transferred then
		if thief.Parent then
			notify(thief, "A transferência não pôde ser confirmada. Seus dados foram protegidos; tente novamente mais tarde.")
		end
		return
	end

	local completedAt = os.time()
	local currentVictimData = DataManager.get(victim)
	if currentVictimData then
		currentVictimData.shieldUntil = completedAt + Config.ShieldTime
	end
	if thief.Parent then
		stealCooldown[thief] = completedAt + Config.StealCooldown
	end

	refreshSlot(plot, i)
	if thief.Parent then
		notify(thief, "Você roubou " .. name .. "!")
		sendUpdate(thief)
	end
	if victim.Parent then
		notify(victim, thief.Name .. " roubou " .. name .. "! Base protegida por " .. Config.ShieldTime .. "s.")
		sendUpdate(victim)
	end
end

local function onSlotPrompt(player, plot, i)
	if shuttingDown or not player.Parent or playerPlot[player] == nil or not DataManager.get(player) then
		return
	end
	local slot = plot.slots[i]
	if not slot or not slot:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or (root.Position - slot.Position).Magnitude > 10 then
		return
	end
	if plot.owner == player and playerPlot[player] == plot then
		pickup(player, plot, i)
	else
		steal(player, plot, i)
	end
end

-- ===== Construção das bases =====
local function buildPlot(index)
	local origin = Vector3.new((index - 1) * PLOT_SPACING, 0, 0)

	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder.Parent = Workspace

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(44, 1, 40)
	floor.Position = origin + Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(110, 190, 110)
	floor.Material = Enum.Material.Grass
	floor.Parent = folder

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(240, 40)
	tag.StudsOffset = Vector3.new(0, 8, 0)
	tag.AlwaysOnTop = true
	tag.Adornee = floor
	tag.Parent = floor

	local tagText = Instance.new("TextLabel")
	tagText.Size = UDim2.fromScale(1, 1)
	tagText.BackgroundTransparency = 1
	tagText.TextScaled = true
	tagText.Font = Enum.Font.GothamBold
	tagText.TextColor3 = Color3.new(1, 1, 1)
	tagText.TextStrokeTransparency = 0
	tagText.Text = "Base livre"
	tagText.Parent = tag

	local plot = {
		index = index,
		owner = nil,
		slots = {},
		spawn = origin + Vector3.new(0, 3, -17),
		tagText = tagText,
		folder = folder,
	}

	for i, offset in SLOT_OFFSETS do
		local slot = Instance.new("Part")
		slot.Name = "Slot" .. i
		slot.Anchored = true
		slot.Size = Vector3.new(6, 1, 6)
		slot.Position = origin + offset + Vector3.new(0, 1.5, 0)
		slot.Color = Color3.fromRGB(230, 230, 230)
		slot.Parent = folder

		local info = Instance.new("BillboardGui")
		info.Name = "Info"
		info.Size = UDim2.fromOffset(180, 50)
		info.StudsOffset = Vector3.new(0, 4, 0)
		info.AlwaysOnTop = true
		info.Enabled = false
		info.Adornee = slot
		info.Parent = slot

		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.Font = Enum.Font.GothamBold
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0
		text.Text = ""
		text.Parent = info

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pegar"
		prompt.ObjectText = "Brainrot"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 8
		prompt.Enabled = false
		prompt.Parent = slot
		prompt.Triggered:Connect(function(player)
			onSlotPrompt(player, plot, i)
		end)

		plot.slots[i] = slot
	end

	return plot
end

-- ===== Ações do jogador =====
actionEvent.OnServerEvent:Connect(function(player, action)
	if shuttingDown or typeof(action) ~= "string" then
		return
	end
	local now = os.clock()
	if lastAction[player] and now - lastAction[player] < 0.25 then
		return
	end
	lastAction[player] = now

	local d = DataManager.get(player)
	local plot = playerPlot[player]
	if not d or not plot then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	if action == "Egg" then
		if d.coins < Config.EggPrice then
			notify(player, "Moedas insuficientes! O ovo custa " .. Config.EggPrice .. ".")
			return
		end
		d.coins -= Config.EggPrice
		local name = Config.rollCreature()
		table.insert(d.inventory, name)
		local _, rarity = Config.info(name)
		notify(player, "Você chocou " .. name .. " (" .. rarity.name .. ")!")
	elseif action == "Place" then
		if #d.inventory == 0 then
			notify(player, "Você não tem brainrots no inventário.")
			return
		end
		local free = nil
		for slotIndex, value in d.placed do
			if value == "" then
				free = slotIndex
				break
			end
		end
		if not free then
			notify(player, "Sua base está cheia! Venda ou guarde algo.")
			return
		end
		d.placed[free] = table.remove(d.inventory, 1)
		refreshSlot(plot, free)
	elseif action == "Sell" then
		if #d.inventory == 0 then
			notify(player, "Nada para vender.")
			return
		end
		local name = table.remove(d.inventory, 1)
		local value = Config.sellValue(name)
		d.coins += value
		notify(player, "Vendeu " .. name .. " por " .. value .. " moedas.")
	else
		return
	end

	sendUpdate(player)
end)

-- ===== Entrada e saída de jogadores =====
local function onPlayerAdded(player)
	if loadingPlayers[player] then
		return
	end
	loadingPlayers[player] = true
	local plot = nil
	for _, p in plots do
		if p.owner == nil then
			plot = p
			break
		end
	end
	if not plot then
		loadingPlayers[player] = nil
		player:Kick("Este servidor está cheio. Tente entrar novamente para buscar um servidor disponível.")
		return
	end
	-- Reserve before the yielding DataStore load so simultaneous joins cannot share a plot.
	plot.owner = player
	playerPlot[player] = plot
	setOwnerTag(plot)

	local d, loadError = DataManager.load(player)
	if not d then
		if plot.owner == player then
			plot.owner = nil
			playerPlot[player] = nil
			setOwnerTag(plot)
			refreshPlot(plot)
		end
		loadingPlayers[player] = nil
		player:Kick("Não foi possível carregar seus dados ou adquirir sua sessão. Tente novamente em instantes.")
		warn("[Main] Entrada cancelada para " .. player.Name .. ": " .. tostring(loadError))
		return
	end

	if player.Parent ~= Players or shuttingDown then
		DataManager.save(player, true)
		if plot.owner == player then
			plot.owner = nil
			playerPlot[player] = nil
			setOwnerTag(plot)
			refreshPlot(plot)
		end
		loadingPlayers[player] = nil
		return
	end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local coinsStat = Instance.new("IntValue")
	coinsStat.Name = "Coins"
	coinsStat.Parent = stats
	loadingPlayers[player] = nil

	refreshPlot(plot)

	local function spawnCharacter(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp and plot then
			character:PivotTo(CFrame.new(plot.spawn))
		end
	end
	player.CharacterAdded:Connect(spawnCharacter)
	if player.Character then
		task.spawn(spawnCharacter, player.Character)
	end

	sendUpdate(player)
end

Players.PlayerRemoving:Connect(function(player)
	loadingPlayers[player] = nil
	local saved = DataManager.save(player, true)
	local plot = playerPlot[player]
	if plot then
		plot.owner = nil
		playerPlot[player] = nil
		setOwnerTag(plot)
		refreshPlot(plot)
	end
	if not saved then
		-- Keep the DataStore session lock until timeout rather than allowing a second writer.
		warn("[Main] Sessão de " .. player.Name .. " não foi liberada após falha de save; lock expira por timeout")
	end
	lastAction[player] = nil
	stealCooldown[player] = nil
end)

game:BindToClose(function()
	shuttingDown = true
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			DataManager.save(player, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + Config.ShutdownSaveTimeout
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

-- ===== Loops =====
task.spawn(function() -- renda por segundo
	while not shuttingDown do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local d = DataManager.get(player)
			if d then
				d.coins += DataManager.income(d)
				sendUpdate(player)
			end
		end
	end
end)

task.spawn(function() -- autosave e heartbeat de sessão
	while not shuttingDown do
		task.wait(Config.SessionHeartbeatInterval)
		for _, player in Players:GetPlayers() do
			task.spawn(DataManager.save, player, false)
		end
	end
end)

-- ===== Inicialização =====
for i = 1, 6 do
	plots[i] = buildPlot(i)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
