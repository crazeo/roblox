-- Animated apples: they float, bob, spin and wobble, then play a
-- squash-and-pop animation when a player grabs one.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local coinCollected = ReplicatedStorage:WaitForChild("CoinCollected")

local MAX_APPLES = 5
local APPLE_VALUE = 5
local RESPAWN_TIME = 4

local folder = Instance.new("Folder")
folder.Name = "Apples"
folder.Parent = workspace

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function findSpot(): Vector3?
	rayParams.FilterDescendantsInstances = { folder, workspace:FindFirstChild("Coins") }
	local angle = math.random() * math.pi * 2
	local dist = math.sqrt(math.random()) * Config.SpawnRadius
	local origin = Vector3.new(math.cos(angle) * dist, 200, math.sin(angle) * dist)
	local hit = workspace:Raycast(origin, Vector3.new(0, -400, 0), rayParams)
	if hit and not hit.Instance:FindFirstAncestorOfClass("Model") then
		return hit.Position + Vector3.new(0, 3.5, 0)
	end
	return nil
end

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	for k, v in props do
		p[k] = v
	end
	return p
end

-- Build an apple from parts: red body, brown stem, green leaf.
local function buildApple(): Model
	local model = Instance.new("Model")
	model.Name = "Apple"

	local body = part({
		Name = "Body",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.4, 2.4, 2.4),
		Color = Color3.fromRGB(215, 30, 40),
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.1,
	})
	body.Parent = model
	model.PrimaryPart = body

	-- Small dent on top so it reads as an apple, not a ball.
	local dent = part({
		Name = "Dent",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.9, 0.5, 0.9),
		Color = Color3.fromRGB(150, 20, 25),
		CFrame = body.CFrame * CFrame.new(0, 1.05, 0),
	})
	dent.Parent = model

	local stem = part({
		Name = "Stem",
		Size = Vector3.new(0.18, 0.7, 0.18),
		Color = Color3.fromRGB(95, 60, 30),
		Material = Enum.Material.Wood,
		CFrame = body.CFrame * CFrame.new(0.05, 1.45, 0) * CFrame.Angles(0, 0, math.rad(-12)),
	})
	stem.Parent = model

	local leaf = part({
		Name = "Leaf",
		Size = Vector3.new(0.7, 0.08, 0.35),
		Color = Color3.fromRGB(70, 170, 60),
		Material = Enum.Material.Grass,
		CFrame = body.CFrame * CFrame.new(0.4, 1.6, 0) * CFrame.Angles(0, 0, math.rad(25)),
	})
	leaf.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 120, 120)
	glow.Range = 8
	glow.Brightness = 0.6
	glow.Parent = body

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 200))
	sparkles.Size = NumberSequence.new(0.3, 0)
	sparkles.Lifetime = NumberRange.new(0.6, 1)
	sparkles.Rate = 4
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = body

	return model
end

-- apple model -> its animation state
local apples: { [Model]: { home: Vector3, phase: number, popping: boolean } } = {}

-- Squash, stretch, then pop with a burst of juice.
local function playPop(apple: Model)
	local state = apples[apple]
	state.popping = true
	local body = apple.PrimaryPart

	local juice = Instance.new("ParticleEmitter")
	juice.Color = ColorSequence.new(Color3.fromRGB(230, 40, 50))
	juice.Size = NumberSequence.new(0.4, 0)
	juice.Lifetime = NumberRange.new(0.3, 0.6)
	juice.Speed = NumberRange.new(8, 14)
	juice.SpreadAngle = Vector2.new(180, 180)
	juice.Acceleration = Vector3.new(0, -30, 0)
	juice.Rate = 0
	juice.Parent = body

	body.Sparkles.Enabled = false

	local base = apple:GetPivot()
	local start = os.clock()
	local duration = 0.45
	while true do
		local t = math.min((os.clock() - start) / duration, 1)
		-- 0 - 0.4: squash down, 0.4 - 0.7: stretch up, 0.7 - 1: shrink away
		local scale
		if t < 0.4 then
			scale = 1 - 0.25 * (t / 0.4)
		elseif t < 0.7 then
			scale = 0.75 + 0.55 * ((t - 0.4) / 0.3)
		else
			scale = 1.3 * (1 - (t - 0.7) / 0.3)
		end
		apple:ScaleTo(math.max(scale, 0.01))
		apple:PivotTo(base * CFrame.new(0, t * 2, 0) * CFrame.Angles(0, t * math.pi * 3, 0))
		if t >= 0.7 and juice.Rate == 0 then
			juice.Rate = 1 -- mark as fired
			juice:Emit(25)
		end
		if t >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end

	for _, p in apple:GetDescendants() do
		if p:IsA("BasePart") then
			p.Transparency = 1
		end
	end
	task.wait(0.6) -- let the juice particles finish
	apples[apple] = nil
	apple:Destroy()
end

local function spawnApple()
	local spot
	for _ = 1, 20 do
		spot = findSpot()
		if spot then
			break
		end
	end
	if not spot then
		return
	end
	local apple = buildApple()
	apple:PivotTo(CFrame.new(spot))
	apples[apple] = { home = spot, phase = math.random() * math.pi * 2, popping = false }

	local taken = false
	apple.PrimaryPart.Touched:Connect(function(hit)
		if taken then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stats = player and player:FindFirstChild("leaderstats")
		if not stats then
			return
		end
		taken = true
		stats.Coins.Value += APPLE_VALUE
		coinCollected:FireClient(player, APPLE_VALUE, apple:GetPivot().Position)
		task.spawn(playPop, apple)
		task.delay(RESPAWN_TIME, spawnApple)
	end)

	apple.Parent = folder
end

-- Idle animation: bob up and down, spin, and wobble side to side.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for apple, state in apples do
		if not state.popping then
			local t = now + state.phase
			local bob = math.sin(t * 2) * 0.5
			local wobble = math.sin(t * 3) * math.rad(8)
			apple:PivotTo(
				CFrame.new(state.home + Vector3.new(0, bob, 0))
					* CFrame.Angles(0, t * 1.2, 0)
					* CFrame.Angles(wobble, 0, 0)
			)
		end
	end
end)

for _ = 1, MAX_APPLES do
	spawnApple()
end
