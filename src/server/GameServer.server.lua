local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local rng = Random.new()
local roundNumber = 0
local activeRound = false
local sun = nil
local actionTimes = {}
local playerTouches = {}

-- Remotes are created by the server so the place requires no manual Studio setup.
local remotes = ReplicatedStorage:FindFirstChild("SunRemotes") or Instance.new("Folder")
remotes.Name = "SunRemotes"
remotes.Parent = ReplicatedStorage

local actionRemote = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes

local stateRemote = remotes:FindFirstChild("State") or Instance.new("RemoteEvent")
stateRemote.Name = "State"
stateRemote.Parent = remotes

local function broadcast(phase, message, timeLeft, data)
	stateRemote:FireAllClients({
		phase = phase,
		message = message,
		timeLeft = timeLeft,
		data = data,
	})
end

local function makePart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createArena()
	local existing = workspace:FindFirstChild("SunArena")
	if existing then
		return existing
	end

	local arena = Instance.new("Folder")
	arena.Name = "SunArena"
	arena.Parent = workspace

	makePart(arena, "Floor", Vector3.new(150, 2, 150), Vector3.new(0, 0, 0), Color3.fromRGB(30, 38, 55), Enum.Material.Slate)

	for index = 1, 8 do
		local angle = (math.pi * 2 / 8) * index
		local position = Vector3.new(math.cos(angle) * 48, 3, math.sin(angle) * 48)
		local pad = makePart(arena, "LaunchPad", Vector3.new(12, 1, 12), position, Color3.fromRGB(255, 178, 46), Enum.Material.Neon)
		pad.CFrame *= CFrame.Angles(0, -angle, 0)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ArenaSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 3, 45)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.35
	spawn.Parent = arena

	return arena
end

local arena = createArena()

local function createSun()
	if sun then
		sun:Destroy()
	end

	local ball = Instance.new("Part")
	ball.Name = "TheSun"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * Config.SunSize
	ball.Position = Vector3.new(0, Config.SunSpawnHeight, 0)
	ball.Color = Color3.fromRGB(255, 190, 45)
	ball.Material = Enum.Material.Neon
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.35, 0.65, 1, 1)
	ball:SetAttribute("IsSun", true)
	ball.Parent = workspace
	ball:SetNetworkOwner(nil)

	local light = Instance.new("PointLight")
	light.Name = "SunLight"
	light.Color = Color3.fromRGB(255, 193, 92)
	light.Brightness = 4
	light.Range = 40
	light.Shadows = true
	light.Parent = ball

	local attachment = Instance.new("Attachment")
	attachment.Parent = ball
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "SolarFlares"
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(ball.Color)
	particles.Lifetime = NumberRange.new(0.3, 0.7)
	particles.Rate = 18
	particles.Speed = NumberRange.new(1, 3)
	particles.Parent = attachment

	sun = ball
	return ball
end

local function resetCharacters()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local angle = rng:NextNumber(0, math.pi * 2)
			local position = Vector3.new(math.cos(angle) * 35, 6, math.sin(angle) * 35)
			root.CFrame = CFrame.lookAt(position, Vector3.new(0, 6, 0))
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

local function clampSunSpeed()
	if not sun or not sun.Parent then
		return
	end
	local velocity = sun.AssemblyLinearVelocity
	if velocity.Magnitude > Config.MaximumSunSpeed then
		sun.AssemblyLinearVelocity = velocity.Unit * Config.MaximumSunSpeed
	end
end

actionRemote.OnServerEvent:Connect(function(player, direction)
	if not activeRound or not sun or typeof(direction) ~= "Vector3" then
		return
	end

	local now = os.clock()
	if now - (actionTimes[player] or 0) < Config.ActionCooldown then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or (root.Position - sun.Position).Magnitude > Config.ActionDistance then
		return
	end

	actionTimes[player] = now
	playerTouches[player] = true

	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.1 then
		local look = root.CFrame.LookVector
		flatDirection = Vector3.new(look.X, 0, look.Z)
	end
	flatDirection = flatDirection.Unit

	-- Setting velocity rather than trusting client physics keeps hits fair and predictable.
	sun.AssemblyLinearVelocity = flatDirection * Config.HitHorizontalSpeed + Vector3.yAxis * Config.HitVerticalSpeed
	sun:SetNetworkOwner(nil)
	clampSunSpeed()
	stateRemote:FireAllClients({ phase = "hit", userId = player.UserId })
end)

Players.PlayerRemoving:Connect(function(player)
	actionTimes[player] = nil
	playerTouches[player] = nil
end)

local challenges = {
	{
		name = "Keep It Up",
		instruction = "Keep the sun off the ground until time expires!",
		completed = function()
			return false
		end,
	},
	{
		name = "Everyone Shines",
		instruction = "Every player must hit the sun at least once!",
		completed = function()
			for _, player in Players:GetPlayers() do
				if not playerTouches[player] then
					return false
				end
			end
			return #Players:GetPlayers() > 0
		end,
	},
}

local modifiers = {
	{
		name = "Normal Sun",
		apply = function() end,
	},
	{
		name = "Heavy Sun",
		apply = function(ball)
			ball.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.35, 0.35, 1, 1)
		end,
	},
	{
		name = "Bouncy Sun",
		apply = function(ball)
			ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.2, 1, 1, 1)
		end,
	},
}

local function waitForPlayers()
	while #Players:GetPlayers() < Config.MinimumPlayers do
		broadcast("waiting", "Waiting for a player...", 0)
		task.wait(1)
	end
end

local function countdown(phase, message, seconds)
	for remaining = seconds, 1, -1 do
		broadcast(phase, message, remaining)
		task.wait(1)
	end
end

local function runRound()
	roundNumber += 1
	playerTouches = {}
	resetCharacters()

	local ball = createSun()
	local challenge = challenges[rng:NextInteger(1, #challenges)]
	local modifier = modifiers[rng:NextInteger(1, #modifiers)]
	modifier.apply(ball)
	activeRound = true

	local droppedFor = 0
	local won = false
	local reason = "The sun froze the arena!"

	for remaining = Config.RoundSeconds, 0, -1 do
		if not sun or not sun.Parent then
			reason = "The sun disappeared!"
			break
		end

		clampSunSpeed()
		if sun.Position.Y <= Config.SunMinimumHeight then
			droppedFor += 1
		else
			droppedFor = 0
		end

		if droppedFor >= Config.SunRecoverSeconds then
			break
		end

		if challenge.name ~= "Keep It Up" and challenge.completed() then
			won = true
			reason = "Challenge complete!"
			break
		end

		broadcast("round", challenge.instruction, remaining, {
			challenge = challenge.name,
			modifier = modifier.name,
			danger = droppedFor,
			round = roundNumber,
		})
		task.wait(1)

		if remaining == 0 then
			won = true
			reason = "You kept the sun alive!"
		end
	end

	activeRound = false
	if sun then
		sun.Anchored = true
	end
	broadcast(won and "victory" or "defeat", reason, Config.ResultSeconds)
	task.wait(Config.ResultSeconds)
	if sun then
		sun:Destroy()
		sun = nil
	end
end

RunService.Heartbeat:Connect(clampSunSpeed)

while true do
	waitForPlayers()
	countdown("intermission", "The sun arrives soon...", Config.IntermissionSeconds)
	if #Players:GetPlayers() >= Config.MinimumPlayers then
		runRound()
	end
end
