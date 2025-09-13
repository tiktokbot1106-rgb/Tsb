local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local playerName = player.Name

-- Config
local invisActive = false
local noclipActive = false
local isFarming = false
local toolGoal = 200

-- Funções auxiliares
local function simulateKeyPress(key)
	local vim = game:GetService("VirtualInputManager")
	vim:SendKeyEvent(true, Enum.KeyCode[key], false, game)
	vim:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

local function teleportToObject(object)
	local part = object:IsA("BasePart") and object or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
	if part then
		hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
		return true
	end
	return false
end

local function countTools()
	local count = 0
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then count += 1 end
	end
	return count
end

local function findOwnedFarm()
	local rootFarm = workspace:FindFirstChild("Farm")
	if not rootFarm then return nil end
	for _, farm in ipairs(rootFarm:GetChildren()) do
		if farm:IsA("Folder") and farm.Name == "Farm" then
			local important = farm:FindFirstChild("Important")
			if important then
				local data = important:FindFirstChild("Data")
				if data then
					local owner = data:FindFirstChild("Owner")
					if owner and owner:IsA("StringValue") and owner.Value == playerName then
						return farm
					end
				end
			end
		end
	end
	return nil
end

local myFarm = findOwnedFarm()
if not myFarm then return warn("Você não possui um farm.") end

-- Criar GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AutoFarmGUI"
screenGui.ResetOnSpawn = false

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0,150,0,40)
toggleButton.Position = UDim2.new(0,10,0,10)
toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggleButton.TextColor3 = Color3.fromRGB(255,255,255)
toggleButton.Text = "Abrir Painel"
toggleButton.Font = Enum.Font.Gotham
toggleButton.TextSize = 16
toggleButton.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,220,0,350)
mainFrame.Position = UDim2.new(0,10,0,60)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.Visible = false
mainFrame.Parent = screenGui

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,0,1,0)
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1
scrollFrame.Parent = mainFrame

toggleButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	toggleButton.Text = mainFrame.Visible and "Fechar Painel" or "Abrir Painel"
end)

-- Função para criar botões e atualizar CanvasSize
local function createButton(text,posY)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-10,0,35)
	btn.Position = UDim2.new(0,5,0,posY)
	btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.Text = text
	btn.Parent = scrollFrame
	scrollFrame.CanvasSize = UDim2.new(0,0,0,posY + 45)
	return btn
end

-- Adicionar botões
local pos = 0

local speedButton = createButton("Velocidade: OFF",pos)
pos += 45
speedButton.MouseButton1Click:Connect(function()
	if humanoid.WalkSpeed == 16 then
		humanoid.WalkSpeed = 50
		speedButton.Text = "Velocidade: ON"
	else
		humanoid.WalkSpeed = 16
		speedButton.Text = "Velocidade: OFF"
	end
end)

local jumpButton = createButton("Super Pulo: OFF",pos)
pos += 45
jumpButton.MouseButton1Click:Connect(function()
	if humanoid.JumpPower == 50 then
		humanoid.JumpPower = 100
		jumpButton.Text = "Super Pulo: ON"
	else
		humanoid.JumpPower = 50
		jumpButton.Text = "Super Pulo: OFF"
	end
end)

local noclipButton = createButton("Noclip: OFF",pos)
pos += 45
local RunService = game:GetService("RunService")
noclipButton.MouseButton1Click:Connect(function()
	noclipActive = not noclipActive
	noclipButton.Text = noclipActive and "Noclip: ON" or "Noclip: OFF"
end)
RunService.Stepped:Connect(function()
	if noclipActive then
		for _,part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end
end)

local invisButton = createButton("Invisibilidade: OFF",pos)
pos += 45
invisButton.MouseButton1Click:Connect(function()
	invisActive = not invisActive
	invisButton.Text = invisActive and "Invisibilidade: ON" or "Invisibilidade: OFF"
	for _,part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = invisActive and 1 or 0
			part.CanCollide = not invisActive
		end
	end
end)

-- Botão Farm 200 Fruits
local farmBtn = createButton("Farm 200 Fruits",pos)
pos += 45
local isFarming = false
farmBtn.MouseButton1Click:Connect(function()
	if isFarming then return end
	isFarming = true
	local plantsFolder = myFarm:FindFirstChild("Important"):FindFirstChild("Plants_Physical")
	if plantsFolder then
		local toolCount = countTools()
		for _,plant in ipairs(plantsFolder:GetChildren()) do
			if toolCount >= toolGoal then break end
			local fruits = plant:FindFirstChild("Fruits")
			if fruits and #fruits:GetChildren() > 0 then
				for _,fruit in ipairs(fruits:GetChildren()) do
					if toolCount >= toolGoal then break end
					if teleportToObject(fruit) then
						task.wait(0)
						simulateKeyPress("E")
						task.wait(0)
						toolCount = countTools()
					end
				end
			else
				if teleportToObject(plant) then
					task.wait(0)
					simulateKeyPress("E")
					task.wait(0)
					toolCount = countTools()
				end
			end
		end
	end
	isFarming = false
end)

-- ESP Jogadores
local espButton = createButton("ESP Jogadores: OFF",pos)
pos += 45
local espOn = false
local espLabels = {}

espButton.MouseButton1Click:Connect(function()
	espOn = not espOn
	espButton.Text = espOn and "ESP Jogadores: ON" or "ESP Jogadores: OFF"

	if espOn then
		for _, plr in ipairs(game.Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				if not espLabels[plr] then
					local billboard = Instance.new("BillboardGui")
					billboard.Name = "ESPLabel"
					billboard.Size = UDim2.new(0,100,0,50)
					billboard.Adornee = plr.Character.HumanoidRootPart
					billboard.AlwaysOnTop = true
					local label = Instance.new("TextLabel", billboard)
					label.Size = UDim2.new(1,0,1,0)
					label.BackgroundTransparency = 1
					label.TextColor3 = Color3.new(1,0,0)
					label.TextStrokeTransparency = 0
					label.Text = plr.Name
					label.Font = Enum.Font.SourceSansBold
					label.TextSize = 14
					billboard.Parent = plr.Character
					espLabels[plr] = billboard
				end
			end
		end
	else
		for plr, gui in pairs(espLabels) do
			if gui then gui:Destroy() end
		end
		espLabels = {}
	end
end)

local fairyBtn = createButton("Teleport Fairy World",pos)
pos += 45
fairyBtn.MouseButton1Click:Connect(function()
	local portal = workspace:FindFirstChild("FairyWorldPortalDestination")
	if portal and hrp then
		hrp.CFrame = portal.CFrame
	end
end)
