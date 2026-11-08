-- Game settings shared by server and client.
local Config = {
	MaxCoins = 25, -- coins on the map at once
	SpawnInterval = 1.5, -- seconds between spawn attempts
	SpawnRadius = 80, -- studs from the map center
	CoinValue = 1,
	GoldenChance = 0.1, -- chance a coin is golden
	GoldenValue = 10,

	BaseWalkSpeed = 16,
	SpeedPerLevel = 2,
	MaxSpeedLevel = 10,
	UpgradeBaseCost = 15,
}

function Config.UpgradeCost(level: number): number
	return math.floor(Config.UpgradeBaseCost * 1.6 ^ level)
end

return Config
