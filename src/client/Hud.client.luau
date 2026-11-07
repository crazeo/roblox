-- Coin counter, speed upgrade button, and "+N" popups.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer
local buySpeed = ReplicatedStorage:WaitForChild("BuySpeed")
local coinCollected = ReplicatedStorage:WaitForChild("CoinCollected")

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = parent
end

local counter = Instance.new("TextLabel")
counter.AnchorPoint = Vector2.new(0.5, 0)
counter.Position = UDim2.new(0.5, 0, 0, 12)
counter.Size = UDim2.fromOffset(200, 44)
counter.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
counter.BackgroundTransparency = 0.2
counter.TextColor3 = Color3.fromRGB(255, 220, 90)
counter.Font = Enum.Font.GothamBold
counter.TextSize = 24
counter.Text = "Coins: 0"
counter.Parent = gui
corner(counter)

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -16, 1, -16)
button.Size = UDim2.fromOffset(220, 56)
button.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Parent = gui
corner(button)

local function refreshButton()
	local level = player:GetAttribute("SpeedLevel") or 0
	if level >= Config.MaxSpeedLevel then
		button.Text = "Speed MAX"
	else
		button.Text = ("Speed Lv %d → %d  (%d)"):format(level, level + 1, Config.UpgradeCost(level))
	end
end

local busy = false
button.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	local ok, message = buySpeed:InvokeServer()
	if not ok then
		button.Text = message
		task.wait(1)
	end
	refreshButton()
	busy = false
end)

player:GetAttributeChangedSignal("SpeedLevel"):Connect(refreshButton)
refreshButton()

local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local function refreshCounter()
	counter.Text = "Coins: " .. coins.Value
end
coins.Changed:Connect(refreshCounter)
refreshCounter()

-- Floating "+N" text where the coin was.
coinCollected.OnClientEvent:Connect(function(value: number, position: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace

	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(100, 40)
	board.AlwaysOnTop = true
	board.Adornee = anchor
	board.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "+" .. value
	label.TextColor3 = value > Config.CoinValue and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(255, 230, 120)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = board

	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.8, function()
		anchor:Destroy()
	end)
end)
