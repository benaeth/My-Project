local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SunRemotes")
local actionRemote = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")

local gui = Instance.new("ScreenGui")
gui.Name = "SunHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Status"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.035)
panel.Size = UDim2.fromOffset(470, 112)
panel.BackgroundColor3 = Color3.fromRGB(18, 23, 36)
panel.BackgroundTransparency = 0.12
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 180, 55)
stroke.Thickness = 2
stroke.Transparency = 0.2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.new(1, -36, 0, 35)
title.Font = Enum.Font.GothamBlack
title.Text = "DON'T DROP THE SUN"
title.TextColor3 = Color3.fromRGB(255, 199, 74)
title.TextScaled = true
title.Parent = panel

local message = Instance.new("TextLabel")
message.BackgroundTransparency = 1
message.Position = UDim2.fromOffset(18, 49)
message.Size = UDim2.new(1, -100, 0, 48)
message.Font = Enum.Font.GothamMedium
message.Text = "Waiting for the round..."
message.TextColor3 = Color3.fromRGB(240, 243, 255)
message.TextSize = 17
message.TextWrapped = true
message.TextXAlignment = Enum.TextXAlignment.Left
message.Parent = panel

local timer = Instance.new("TextLabel")
timer.BackgroundTransparency = 1
timer.AnchorPoint = Vector2.new(1, 0.5)
timer.Position = UDim2.new(1, -15, 0.65, 0)
timer.Size = UDim2.fromOffset(65, 52)
timer.Font = Enum.Font.GothamBlack
timer.Text = "--"
timer.TextColor3 = Color3.fromRGB(255, 255, 255)
timer.TextScaled = true
timer.Parent = panel

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.fromScale(0.5, 0.96)
hint.Size = UDim2.fromOffset(430, 36)
hint.Font = Enum.Font.GothamBold
hint.Text = "Get close and press E or tap HIT THE SUN"
hint.TextColor3 = Color3.fromRGB(255, 226, 150)
hint.TextSize = 18
hint.Parent = gui

local function performAction(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	local camera = workspace.CurrentCamera
	if camera then
		actionRemote:FireServer(camera.CFrame.LookVector)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("HitTheSun", performAction, true, Enum.KeyCode.E, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("HitTheSun", "HIT SUN")
ContextActionService:SetPosition("HitTheSun", UDim2.fromScale(0.82, 0.72))

stateRemote.OnClientEvent:Connect(function(state)
	if state.phase == "hit" then
		local original = panel.Size
		panel.Size = UDim2.fromOffset(485, 116)
		TweenService:Create(panel, TweenInfo.new(0.18), { Size = original }):Play()
		return
	end

	message.Text = state.message or ""
	timer.Text = state.timeLeft and tostring(state.timeLeft) or "--"

	if state.phase == "victory" then
		title.Text = "THE SUN SURVIVED!"
		title.TextColor3 = Color3.fromRGB(115, 255, 146)
	elseif state.phase == "defeat" then
		title.Text = "THE SUN WENT OUT"
		title.TextColor3 = Color3.fromRGB(145, 202, 255)
	else
		title.Text = "DON'T DROP THE SUN"
		title.TextColor3 = Color3.fromRGB(255, 199, 74)
	end

	if state.data then
		message.Text = string.format("%s\n%s · %s", state.message, state.data.challenge, state.data.modifier)
		timer.TextColor3 = state.data.danger > 0 and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 255, 255)
	end
end)
