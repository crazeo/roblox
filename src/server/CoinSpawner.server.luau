-- Spawns coins around the map and pays players who touch them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local folder = Instance.new("Folder")
folder.Name = "Coins"
folder.Parent = workspace

local collected = Instance.new("RemoteEvent")
collected.Name = "CoinCollected"
collected.Parent = ReplicatedStorage

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = { folder }
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Pick a random point on the ground (skips characters and other models).
local function findSpot(): Vector3?
	local angle = math.random() * math.pi * 2
	local dist = math.sqrt(math.random()) * Config.SpawnRadius
	local origin = Vector3.new(math.cos(angle) * dist, 200, math.sin(angle) * dist)
	local hit = workspace:Raycast(origin, Vector3.new(0, -400, 0), rayParams)
	if hit and not hit.Instance:FindFirstAncestorOfClass("Model") then
		return hit.Position + Vector3.new(0, 3, 0)
	end
	return nil
end

local function spawnCoin()
	local position = findSpot()
	if not position then
		return
	end

	local golden = math.random() < Config.GoldenChance
	local coin = Instance.new("Part")
	coin.Name = golden and "GoldenCoin" or "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = golden and Vector3.new(0.5, 4, 4) or Vector3.new(0.4, 2.5, 2.5)
	coin.Color = golden and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(255, 230, 120)
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	coin:SetAttribute("Value", golden and Config.GoldenValue or Config.CoinValue)

	local taken = false
	coin.Touched:Connect(function(hit)
		if taken then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stats = player and player:FindFirstChild("leaderstats")
		if not stats then
			return
		end
		taken = true
		local value = coin:GetAttribute("Value")
		stats.Coins.Value += value
		collected:FireClient(player, value, coin.Position)
		coin:Destroy()
	end)

	coin.Parent = folder
end

-- Spin every coin from one loop.
task.spawn(function()
	while true do
		local dt = task.wait()
		for _, coin in folder:GetChildren() do
			coin.CFrame *= CFrame.Angles(dt * 2, 0, 0)
		end
	end
end)

while true do
	if #folder:GetChildren() < Config.MaxCoins then
		spawnCoin()
	end
	task.wait(Config.SpawnInterval)
end
