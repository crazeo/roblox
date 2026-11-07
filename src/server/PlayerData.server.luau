-- Creates leaderstats and saves coins + speed level with DataStores.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local store = DataStoreService:GetDataStore("CoinRush_v1")

local function applySpeed(player: Player)
	local level = player:GetAttribute("SpeedLevel") or 0
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.BaseWalkSpeed + level * Config.SpeedPerLevel
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local ok, data = pcall(store.GetAsync, store, tostring(player.UserId))
	if ok and type(data) == "table" then
		coins.Value = data.Coins or 0
		player:SetAttribute("SpeedLevel", data.SpeedLevel or 0)
	else
		player:SetAttribute("SpeedLevel", 0)
		if not ok then
			warn("Could not load data for", player.Name, data)
		end
	end
	-- Only save later if loading worked, so a failed load can't wipe progress.
	player:SetAttribute("Loaded", ok)

	leaderstats.Parent = player
	player.CharacterAdded:Connect(function()
		task.defer(applySpeed, player)
	end)
	player:GetAttributeChangedSignal("SpeedLevel"):Connect(function()
		applySpeed(player)
	end)
	applySpeed(player)
end

local function save(player: Player)
	if not player:GetAttribute("Loaded") then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), {
		Coins = leaderstats.Coins.Value,
		SpeedLevel = player:GetAttribute("SpeedLevel") or 0,
	})
	if not ok then
		warn("Could not save data for", player.Name, err)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(save)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(3)
end)
