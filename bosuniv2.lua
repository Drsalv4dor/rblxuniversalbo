local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- CONFIG
local FOV_RADIUS = 100
local AIM_KEY = Enum.UserInputType.MouseButton2
local toggleKey = Enum.KeyCode.K

-- Shared Settings Table
local settings = {
	aimbot = true,
	esp = true,
	tracers = true,
	triggerbot = false,
	antiaim = false,
	boxes = true,
}

-- UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "CheatHub"

local frame = Instance.new("Frame", ScreenGui)
frame.Position = UDim2.new(0.75, 0, 0.4, 0)
frame.Size = UDim2.new(0, 200, 0, 240)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "cheat hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

local credit = Instance.new("TextLabel", frame)
credit.Position = UDim2.new(0, 0, 1, -20)
credit.Size = UDim2.new(1, 0, 0, 20)
credit.BackgroundTransparency = 1
credit.Text = "discord.gg/TdA3egXnB3"
credit.TextColor3 = Color3.fromRGB(200, 0, 0)
credit.Font = Enum.Font.SourceSans
credit.TextSize = 14

local function createToggle(text, order, settingKey)
	local btn = Instance.new("TextButton", frame)
	btn.Position = UDim2.new(0, 0, 0, 30 + (order * 30))
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 16
	btn.Text = text .. ": " .. (settings[settingKey] and "ON" or "OFF")

	btn.MouseButton1Click:Connect(function()
		settings[settingKey] = not settings[settingKey]
		btn.Text = text .. ": " .. (settings[settingKey] and "ON" or "OFF")
	end)
end

createToggle("Aimbot", 0, "aimbot")
createToggle("ESP", 1, "esp")
createToggle("Tracers", 2, "tracers")
createToggle("Triggerbot", 3, "triggerbot")
createToggle("Anti-Aim", 4, "antiaim")
createToggle("Boxes", 5, "boxes")

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == toggleKey then
		frame.Visible = not frame.Visible
	end
end)

-- Drawing FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOV_RADIUS
fovCircle.Thickness = 1
fovCircle.Transparency = 0.6
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Filled = false

local tracerLines = {}
local boxDrawings = {}

local function applyHighlight(char)
	if char:FindFirstChild("ESP_Highlight") then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = char
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0.5
	highlight.Parent = char
end

local function getClosestHead()
	local closest = nil
	local shortestDistance = FOV_RADIUS

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local head = player.Character:FindFirstChild("Head")
			if head then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local mousePos = UserInputService:GetMouseLocation()
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if dist < shortestDistance then
						shortestDistance = dist
						closest = head
					end
				end
			end
		end
	end

	return closest
end

local function snapCameraTo(part)
	if part then
		local dir = (part.Position - camera.CFrame.Position).Unit
		camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + dir)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer and player.Character then
		applyHighlight(player.Character)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		repeat task.wait() until char:FindFirstChild("HumanoidRootPart")
		applyHighlight(char)
	end)
end)

task.spawn(function()
	while true do
		for player, tracer in pairs(tracerLines) do
			if not player or not player.Parent or not Players:FindFirstChild(player.Name) then
				tracer:Remove()
				tracerLines[player] = nil
			end
		end
		for player, box in pairs(boxDrawings) do
			box.box:Remove()
			box.healthBar:Remove()
			boxDrawings[player] = nil
		end
		task.wait(1)
	end
end)

local lastTriggerTime = 0

task.spawn(function()
	while true do
		if settings.triggerbot then
			local now = tick()
			if now - lastTriggerTime >= 0.25 then
				local target = getClosestHead()
				if target then
					local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
					if onScreen then
						local mousePos = UserInputService:GetMouseLocation()
						local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
						if dist < 5 then
							VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
							VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
							lastTriggerTime = now
						end
					end
				end
			end
		end
		task.wait()
	end
end)

local lastYOffset = 0
local floatSpeed = 2

RunService.RenderStepped:Connect(function()
	fovCircle.Position = UserInputService:GetMouseLocation()

	if settings.aimbot and UserInputService:IsMouseButtonPressed(AIM_KEY) then
		local target = getClosestHead()
		if target then
			snapCameraTo(target)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local head = player.Character:FindFirstChild("Head")
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

			if hrp and head and humanoid then
				local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
				local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
				local footPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))

				if settings.esp then
					applyHighlight(player.Character)
				else
					local existing = player.Character:FindFirstChild("ESP_Highlight")
					if existing then existing:Destroy() end
				end

				if not tracerLines[player] then
					local line = Drawing.new("Line")
					line.Thickness = 1
					line.Color = Color3.fromRGB(255, 0, 0)
					line.Transparency = 0.5
					tracerLines[player] = line
				end

				local tracer = tracerLines[player]
				if settings.tracers and onScreen then
					tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
					tracer.To = Vector2.new(pos.X, pos.Y)
					tracer.Visible = true
				else
					tracer.Visible = false
				end

				if not boxDrawings[player] then
					boxDrawings[player] = {
						box = Drawing.new("Square"),
						healthBar = Drawing.new("Line"),
					}
					boxDrawings[player].box.Thickness = 1
					boxDrawings[player].box.Color = Color3.fromRGB(255, 0, 0)
					boxDrawings[player].box.Filled = false
					boxDrawings[player].box.Transparency = 1

					boxDrawings[player].healthBar.Color = Color3.fromRGB(0, 255, 0)
					boxDrawings[player].healthBar.Thickness = 2
					boxDrawings[player].healthBar.Transparency = 1
				end

				local height = math.abs(headPos.Y - footPos.Y)
				local width = height / 2
				local box = boxDrawings[player].box
				local healthBar = boxDrawings[player].healthBar

				if settings.boxes and onScreen then
					box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
					box.Size = Vector2.new(width, height)
					box.Visible = true

					local hpRatio = humanoid.Health / humanoid.MaxHealth
					local barHeight = height * hpRatio
					local barX = pos.X - width / 2 - 4

					healthBar.From = Vector2.new(barX, pos.Y + height / 2)
					healthBar.To = Vector2.new(barX, pos.Y + height / 2 - barHeight)
					healthBar.Visible = true
				else
					box.Visible = false
					healthBar.Visible = false
				end
			end
		end
	end

	if settings.antiaim and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = localPlayer.Character.HumanoidRootPart
		local t = tick()
		local yOffset = math.sin(t * floatSpeed) * 0.25
		local randomY = math.rad(math.random(-180, 180))
		hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + (yOffset - lastYOffset), hrp.Position.Z) * CFrame.Angles(0, randomY, 0)
		lastYOffset = yOffset
	end
end)
