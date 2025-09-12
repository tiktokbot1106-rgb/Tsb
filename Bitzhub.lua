local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local playerName = player.Name

-- Config
local invisActive = false
local noclipActive = false
local isFarming = false
local isFarmingSpecific = false
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
noclipButton.MouseButton1Click:Connect(function()
	noclipActive = not noclipActive
	noclipButton.Text = noclipActive and "Noclip: ON" or "Noclip: OFF"
end)

game:GetService("RunService").Stepped:Connect(function()
	if noclipActive then
		for _,part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
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

-- Botão Farm Todas Frutas
local farmBtn = createButton("Farm 200 Fruits",pos)
pos += 45
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

-- Botão Farm Plant Específica
local label = Instance.new("TextLabel", scrollFrame)
label.Position = UDim2.new(0,5,0,pos)
label.Size = UDim2.new(1,-10,0,20)
label.Text = "Nome da Planta (Case Sensitive):"
label.TextColor3 = Color3.fromRGB(255,255,255)
label.BackgroundTransparency = 1
pos += 25

local textBox = Instance.new("TextBox", scrollFrame)
textBox.Position = UDim2.new(0,5,0,pos)
textBox.Size = UDim2.new(1,-10,0,25)
textBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
textBox.TextColor3 = Color3.fromRGB(255,255,255)
textBox.PlaceholderText = "Ex: Tomato"
textBox.Text = ""
pos += 35
scrollFrame.CanvasSize = UDim2.new(0,0,0,pos)

local farmSpecificBtn = createButton("Farm Planta Específica",pos)
pos += 45
farmSpecificBtn.MouseButton1Click:Connect(function()
	if isFarmingSpecific then return end
	local plantName = textBox.Text
	if plantName == "" then return end
	isFarmingSpecific = true
	local plantsFolder = myFarm:FindFirstChild("Important"):FindFirstChild("Plants_Physical")
	if plantsFolder then
		local toolCount = countTools()
		for _,plant in ipairs(plantsFolder:GetChildren()) do
			if plant.Name == plantName then
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
			if toolCount >= toolGoal then break end
		end
	end
	isFarmingSpecific = false
end)

-- Teleporte NPCs
local npcLabel = createButton("=== TELEPORT NPCs ===",pos)
npcLabel.Active = false
pos += 45

local gearBtn = createButton("Gear Shop",pos)
pos += 45
local questBtn = createButton("Quest Giver",pos)
pos += 45

local gearShopCFrame = CFrame.new(-261.29, 2.99, -26.67)
local questGiverCFrame = CFrame.new(-263.65, 3, -1.12)

gearBtn.MouseButton1Click:Connect(function() hrp.CFrame = gearShopCFrame end)
questBtn.MouseButton1Click:Connect(function() hrp.CFrame = questGiverCFrame end)
