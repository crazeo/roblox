# Coin Rush

A small Roblox game: run around, collect coins (gold ones are worth 10), and spend them on speed upgrades. Coins and upgrades save between sessions.

## Setup

1. Install [Rojo](https://rojo.space) and its Studio plugin.
2. Run `rojo serve` in this folder.
3. Open a baseplate in Studio and click **Connect** in the Rojo plugin.
4. To keep progress saving in Studio, turn on **Game Settings → Security → Enable Studio Access to API Services**.

## Files

| File | What it does |
| --- | --- |
| `src/shared/Config.luau` | All tuning numbers (coin counts, values, upgrade prices) |
| `src/server/CoinSpawner.server.luau` | Spawns spinning coins and pays the player who touches one |
| `src/server/PlayerData.server.luau` | Leaderboard, saving/loading, applying walk speed |
| `src/server/Shop.server.luau` | Checks and applies speed upgrade purchases |
| `src/client/Hud.client.luau` | Coin counter, upgrade button, "+N" popups |
