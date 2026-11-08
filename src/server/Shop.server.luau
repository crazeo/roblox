-- Handles speed upgrade purchases. The server checks the price, never the client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local buy = Instance.new("RemoteFunction")
buy.Name = "BuySpeed"
buy.Parent = ReplicatedStorage

buy.OnServerInvoke = function(player: Player)
	local stats = player:FindFirstChild("leaderstats")
	local level = player:GetAttribute("SpeedLevel")
	if not stats or not level then
		return false, "Still loading"
	end
	if level >= Config.MaxSpeedLevel then
		return false, "Max level"
	end
	local cost = Config.UpgradeCost(level)
	if stats.Coins.Value < cost then
		return false, "Need " .. cost .. " coins"
	end
	stats.Coins.Value -= cost
	player:SetAttribute("SpeedLevel", level + 1)
	return true, "Speed up!"
end
