local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionEvent = remotes:WaitForChild("Action")
local updateEvent = remotes:WaitForChild("Update")
local notifyEvent = remotes:WaitForChild("Notify")

local function make(className, props, parent)
	local obj = Instance.new(className)
	for k, v in props do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local gui = make("ScreenGui", { Name = "BrainrotHUD", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local frame = make("Frame", {
	Size = UDim2.fromOffset(290, 340),
	Position = UDim2.new(0, 16, 0, 16),
	BackgroundColor3 = Color3.fromRGB(25, 25, 35),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, frame)

local coinsLabel = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.fromOffset(10, 8),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextColor3 = Color3.fromRGB(255, 220, 80),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Moedas: 0",
}, frame)

local incomeLabel = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 20),
	Position = UDim2.fromOffset(10, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(180, 255, 180),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "+0 moedas/s",
}, frame)

local placedLabel = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 100),
	Position = UDim2.fromOffset(10, 66),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Text = "",
}, frame)

local invLabel = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 90),
	Position = UDim2.fromOffset(10, 176),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(200, 200, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Text = "",
}, frame)

local function button(text, x, color, action)
	local b = make("TextButton", {
		Size = UDim2.fromOffset(86, 44),
		Position = UDim2.fromOffset(x, 280),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextWrapped = true,
		Text = text,
	}, frame)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	b.MouseButton1Click:Connect(function()
		actionEvent:FireServer(action)
	end)
end

button("Ovo\n100 moedas", 10, Color3.fromRGB(70, 130, 230), "Egg")
button("Colocar\n1º item", 102, Color3.fromRGB(60, 170, 90), "Place")
button("Vender\n1º item", 194, Color3.fromRGB(200, 90, 70), "Sell")

-- Aviso (toast) no topo
local toast = make("TextLabel", {
	Size = UDim2.fromOffset(560, 46),
	Position = UDim2.new(0.5, 0, 0, 20),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	TextWrapped = true,
	Text = "",
	Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, toast)

local toastId = 0
notifyEvent.OnClientEvent:Connect(function(msg)
	toastId += 1
	local myId = toastId
	toast.Text = msg
	toast.Visible = true
	task.delay(3.5, function()
		if toastId == myId then
			toast.Visible = false
		end
	end)
end)

updateEvent.OnClientEvent:Connect(function(data)
	coinsLabel.Text = "Moedas: " .. data.coins
	incomeLabel.Text = "+" .. data.income .. " moedas/s"

	local lines = {}
	for i, name in data.placed do
		local text = "Base " .. i .. ": "
		if name ~= "" then
			text = text .. name
		else
			text = text .. "(vazio)"
		end
		table.insert(lines, text)
	end
	placedLabel.Text = table.concat(lines, "\n")

	local shown = {}
	for i, name in data.inventory do
		if i > 6 then
			break
		end
		table.insert(shown, name)
	end
	local more = #data.inventory - #shown
	local invText = "Inventário (" .. #data.inventory .. "):\n" .. table.concat(shown, ", ")
	if more > 0 then
		invText = invText .. "\n+" .. more .. " mais"
	end
	invLabel.Text = invText
end)
