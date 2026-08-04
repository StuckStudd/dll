-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Загрузка Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "TWKS Hub - Jailbreak Max Suite",
	LoadingTitle = "TWKS Interface",
	LoadingSubtitle = "All Features Unlocked",
	ConfigurationSaving = { Enabled = false },
	KeySystem = true,
	KeySettings = {
		Title = "TWKS Verification",
		Subtitle = "Key System",
		Note = "Введите ключ доступа (получите его на вашем сайте)",
		FileName = "TWKS_Key_Save",
		SaveKey = true,
		GrabKeyFromSite = false,
		Key = {"TWKS-KEY-2026", "FREE-KEY-PASS"}
	}
})

-- Разделы интерфейса
local CombatTab  = Window:CreateTab("Combat", 4483345998)
local RobberyTab = Window:CreateTab("Robbery", 4483345998)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local OtherTab   = Window:CreateTab("Other", 4483345998)
local CameraTab  = Window:CreateTab("Camera", 4483345998)

-- =======================================================
-- ПЕРЕМЕННЫЕ И СОСТОЯНИЯ
-- =======================================================

-- Combat / Aimbot & Gun Mods
local aimbotEnabled = false
local aimbotTargetPart = "Head"
local aimbotKeyHold = false

local useFov = true
local fovRadius = 150
local fovColor = Color3.fromRGB(255, 255, 255)
local fovCircle = Drawing and Drawing.new("Circle") or nil
if fovCircle then
	fovCircle.Thickness = 1.5
	fovCircle.Color = fovColor
	fovCircle.Transparency = 1
	fovCircle.Filled = false
	fovCircle.Visible = false
end

local hitboxEnabled = false
local hitboxSize = 4

local noRecoilEnabled = false
local fastReloadEnabled = false
local cachedGunTables = {}

-- Robbery (ATMs & Airdrops)
local atmHighlightEnabled = false
local atmHighlights = {}
local atmColor = Color3.fromRGB(0, 255, 128)

local airdropHighlightEnabled = false
local airdropHighlights = {}
local airdropColor = Color3.fromRGB(255, 215, 0)

-- Other (Doors & Anti-AFK)
local doorHighlightEnabled = false
local doorTracerEnabled = false
local doorHighlights = {}
local doorTracers = {}
local doorColor = Color3.fromRGB(255, 0, 0)

local slideDoorHighlightEnabled = false
local slideDoorHighlights = {}
local slideDoorColor = Color3.fromRGB(255, 170, 0)

local doubleDoorHighlightEnabled = false
local doubleDoorHighlights = {}
local doubleDoorColor = Color3.fromRGB(0, 170, 255)

local antiAfkEnabled = false

-- Visuals
local playerEspEnabled = false
local playerHighlights = {}

local skeletonEspEnabled = false
local skeletonLines = {}

local fullBrightEnabled = false
local originalLightingProps = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
}

local originalAtmosphereDensity = nil
local skyboxes = {
	["Vaporwave"]      = {"1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643"},
	["Redshift"]       = {"401664839", "401664862", "401664960", "401664881", "401664901", "401664936"},
	["Desert"]         = {"1013852", "1013853", "1013850", "1013851", "1013849", "1013854"},
	["Blaze"]          = {"150939022", "150939038", "150939047", "150939056", "150939063", "150939082"},
	["Among Us"]       = {"5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190"},
	["Space Wave2"]    = {"1233158420", "1233158838", "1233157105", "1233157640", "1233157995", "1233159158"},
	["Turquoise Wave"] = {"47974894", "47974690", "47974821", "47974776", "47974859", "47974909"},
	["Dark Night"]     = {"6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635"},
	["Bright Pink"]    = {"271042516", "271077243", "271042556", "271042310", "271042467", "271077958"},
	["Oblivion Lost"]  = {"5103110171", "5102993828", "5103111020", "5103112417", "5103113734", "5102993828"},
	["Setting Sun"]    = {"626460377", "626460216", "626460513", "626473032", "626458639", "626460625"},
}

-- FreeCam
local freecamEnabled = false
local freecamSpeed = 1
local freecamConnection = nil
local freecamToggleRef = nil
local cameraYaw = 0
local cameraPitch = 0
local cameraPos = Vector3.new()

-- =======================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ПОИСКА ОБЪЕКТОВ
-- =======================================================

local function getTargetDoors()
	local targets = {}
	pcall(function()
		local searchRoots = {Workspace}
		if getgenv and getgenv().Ugc then table.insert(searchRoots, getgenv().Ugc)
		elseif typeof(Ugc) == "table" then table.insert(searchRoots, Ugc) end

		for _, root in ipairs(searchRoots) do
			for _, obj in ipairs(root:GetChildren()) do
				if obj.Name == "SwingDoor" then
					table.insert(targets, obj)
				elseif #obj.Name >= 30 and string.find(obj.Name, "-") then
					local door = obj:FindFirstChild("SwingDoor")
					if door then table.insert(targets, door) end
				end
			end
		end
	end)
	return targets
end

local function getTargetSlideDoors()
	local targets = {}
	pcall(function()
		local searchRoots = {Workspace}
		if getgenv and getgenv().Ugc then table.insert(searchRoots, getgenv().Ugc)
		elseif typeof(Ugc) == "table" then table.insert(searchRoots, Ugc) end

		for _, root in ipairs(searchRoots) do
			for _, obj in ipairs(root:GetChildren()) do
				if obj.Name == "SlideDoor" then
					table.insert(targets, obj)
				elseif #obj.Name >= 30 and string.find(obj.Name, "-") then
					local door = obj:FindFirstChild("SlideDoor")
					if door then table.insert(targets, door) end
				end
			end
			for _, obj in ipairs(root:GetDescendants()) do
				if obj.Name == "SlideDoor" and not table.find(targets, obj) then
					table.insert(targets, obj)
				end
			end
		end
	end)
	return targets
end

local function getTargetDoubleDoors()
	local targets = {}
	pcall(function()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			local nameLower = obj.Name:lower()
			if (nameLower:find("doubledoor") or nameLower:find("double_door") or nameLower == "doubleswingdoor") and not table.find(targets, obj) then
				table.insert(targets, obj)
			end
		end
	end)
	return targets
end

local function getTargetATMs()
	local targets = {}
	pcall(function()
		local searchRoots = {Workspace}
		if getgenv and getgenv().Ugc then table.insert(searchRoots, getgenv().Ugc)
		elseif typeof(Ugc) == "table" then table.insert(searchRoots, Ugc) end

		for _, root in ipairs(searchRoots) do
			local mapFolder = root:FindFirstChild("0c5fafdd-228e-415c-83eb-bf2e7a79cfc6") or root:FindFirstChild("Map")
			if mapFolder then
				local atms = mapFolder:FindFirstChild("ATMs", true) or mapFolder:FindFirstChild("Map", true)
				if atms then
					for _, atm in ipairs(atms:GetDescendants()) do
						if atm.Name == "ATM" then table.insert(targets, atm) end
					end
				end
			end
			for _, obj in ipairs(root:GetDescendants()) do
				if obj.Name == "ATM" and not table.find(targets, obj) then
					table.insert(targets, obj)
				end
			end
		end
	end)
	return targets
end

local function getTargetAirdrops()
	local targets = {}
	pcall(function()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			local nameLower = obj.Name:lower()
			-- Исключаем карты, вышки, горы и оил-риги
			if not (nameLower:find("oil") or nameLower:find("rig") or nameLower:find("mountain") or nameLower:find("sand") or nameLower:find("terrain") or nameLower:find("map")) then
				if (nameLower:find("airdrop") or nameLower:find("briefcase") or nameLower == "dropcrate" or nameLower == "drop") and (obj:IsA("Model") or obj:IsA("BasePart")) then
					if not table.find(targets, obj) and not obj:IsDescendantOf(LocalPlayer.Character or Workspace) then
						table.insert(targets, obj)
					end
				end
			end
		end
	end)
	return targets
end

-- =======================================================
-- 1. COMBAT TAB
-- =======================================================

CombatTab:CreateToggle({
	Name = "Camera Aimbot",
	CurrentValue = false,
	Flag = "AimbotToggle",
	Callback = function(Value)
		aimbotEnabled = Value
	end,
})

CombatTab:CreateDropdown({
	Name = "Target Part",
	Options = {"Head", "Torso / Root"},
	CurrentOption = "Head",
	Flag = "AimbotPartDropdown",
	Callback = function(Option)
		if Option == "Torso / Root" then
			aimbotTargetPart = "HumanoidRootPart"
		else
			aimbotTargetPart = "Head"
		end
	end,
})

CombatTab:CreateKeybind({
	Name = "Aimbot Keybind",
	CurrentKeybind = "E",
	HoldToInteract = true,
	Flag = "AimbotKeybindFlag",
	Callback = function(KeyHeld)
		aimbotKeyHold = KeyHeld
	end,
})

CombatTab:CreateToggle({
	Name = "Use FOV Limit",
	CurrentValue = true,
	Flag = "AimbotUseFovToggle",
	Callback = function(Value)
		useFov = Value
		if fovCircle then fovCircle.Visible = Value end
	end,
})

CombatTab:CreateSlider({
	Name = "FOV Radius",
	Range = {50, 500},
	Increment = 5,
	Suffix = "px",
	CurrentValue = 150,
	Flag = "AimbotFovRadiusSlider",
	Callback = function(Value)
		fovRadius = Value
		if fovCircle then fovCircle.Radius = Value end
	end,
})

CombatTab:CreateColorPicker({
	Name = "FOV Circle Color",
	Color = Color3.fromRGB(255, 255, 255),
	Flag = "AimbotFovColorPicker",
	Callback = function(Value)
		fovColor = Value
		if fovCircle then fovCircle.Color = Value end
	end
})

CombatTab:CreateToggle({
	Name = "Head Hitbox Expander",
	CurrentValue = false,
	Flag = "HitboxExpanderToggle",
	Callback = function(Value)
		hitboxEnabled = Value
		if not hitboxEnabled then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
					player.Character.Head.Size = Vector3.new(1.2, 1.2, 1.2)
					player.Character.Head.Transparency = 0
					player.Character.Head.CanCollide = true
				end
			end
		end
	end,
})

CombatTab:CreateSlider({
	Name = "Head Hitbox Size",
	Range = {2, 15},
	Increment = 0.5,
	Suffix = "Studs",
	CurrentValue = 4,
	Flag = "HitboxSizeSlider",
	Callback = function(Value)
		hitboxSize = Value
	end,
})

CombatTab:CreateToggle({
	Name = "No Recoil / No Spread",
	CurrentValue = false,
	Flag = "NoRecoilToggle",
	Callback = function(Value)
		noRecoilEnabled = Value
	end,
})

CombatTab:CreateToggle({
	Name = "Fast Reload / Inf Ammo",
	CurrentValue = false,
	Flag = "FastReloadToggle",
	Callback = function(Value)
		fastReloadEnabled = Value
	end,
})

-- Оптимизированное кеширование таблиц оружия для отмены регулярных тяжелых сканирований GC
local function updateGunTablesCache()
	if not getgc then return end
	cachedGunTables = {}
	pcall(function()
		for _, v in pairs(getgc(true)) do
			if type(v) == "table" and (rawget(v, "MagSize") or rawget(v, "Recoil") or rawget(v, "ReloadTime")) then
				table.insert(cachedGunTables, v)
			end
		end
	end)
end

task.spawn(function()
	updateGunTablesCache()
	while task.wait(1.5) do
		if noRecoilEnabled or fastReloadEnabled then
			if #cachedGunTables == 0 then updateGunTablesCache() end
			for _, v in ipairs(cachedGunTables) do
				if noRecoilEnabled then
					if rawget(v, "Recoil") then rawset(v, "Recoil", 0) end
					if rawget(v, "Spread") then rawset(v, "Spread", 0) end
					if rawget(v, "MinSpread") then rawset(v, "MinSpread", 0) end
					if rawget(v, "MaxSpread") then rawset(v, "MaxSpread", 0) end
					if rawget(v, "CamShake") then rawset(v, "CamShake", 0) end
				end
				if fastReloadEnabled then
					if rawget(v, "ReloadTime") then rawset(v, "ReloadTime", 0.01) end
					if rawget(v, "MagSize") then rawset(v, "MagSize", 999) end
					if rawget(v, "Ammo") then rawset(v, "Ammo", 999) end
				end
			end
		end
	end
end)

local function getClosestPlayerInFOV()
	local closestPlayer = nil
	local shortestDistance = useFov and fovRadius or math.huge
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			local targetPart = player.Character:FindFirstChild(aimbotTargetPart) or player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Head")
			if targetPart then
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestPlayer = targetPart
					end
				end
			end
		end
	end
	return closestPlayer
end

-- =======================================================
-- 2. ROBBERY TAB
-- =======================================================

RobberyTab:CreateToggle({
	Name = "Highlight ATMs",
	CurrentValue = false,
	Flag = "ATMHighlightToggle",
	Callback = function(Value)
		atmHighlightEnabled = Value
		for _, hl in ipairs(atmHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		atmHighlights = {}

		if atmHighlightEnabled then
			for _, atm in ipairs(getTargetATMs()) do
				local highlight = Instance.new("Highlight")
				highlight.Name = "TWKS_ATMHighlight"
				highlight.Adornee = atm
				highlight.FillColor = atmColor
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.3
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = atm
				table.insert(atmHighlights, highlight)
			end
		end
	end,
})

RobberyTab:CreateColorPicker({
	Name = "ATM Color",
	Color = Color3.fromRGB(0, 255, 128),
	Flag = "ATMColorPicker",
	Callback = function(Value)
		atmColor = Value
		for _, hl in ipairs(atmHighlights) do
			if hl and hl.Parent then hl.FillColor = atmColor end
		end
	end
})

RobberyTab:CreateToggle({
	Name = "Airdrop & Crate ESP",
	CurrentValue = false,
	Flag = "AirdropHighlightToggle",
	Callback = function(Value)
		airdropHighlightEnabled = Value
		for _, hl in ipairs(airdropHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		airdropHighlights = {}

		if airdropHighlightEnabled then
			for _, drop in ipairs(getTargetAirdrops()) do
				local highlight = Instance.new("Highlight")
				highlight.Name = "TWKS_AirdropHighlight"
				highlight.Adornee = drop
				highlight.FillColor = airdropColor
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.3
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = drop
				table.insert(airdropHighlights, highlight)
			end
		end
	end,
})

RobberyTab:CreateColorPicker({
	Name = "Airdrop Color",
	Color = Color3.fromRGB(255, 215, 0),
	Flag = "AirdropColorPicker",
	Callback = function(Value)
		airdropColor = Value
		for _, hl in ipairs(airdropHighlights) do
			if hl and hl.Parent then hl.FillColor = airdropColor end
		end
	end
})

-- =======================================================
-- 3. OTHER TAB
-- =======================================================

local function clearDoorTracers()
	for _, tracer in ipairs(doorTracers) do
		if tracer then
			tracer.Visible = false
			tracer:Remove()
		end
	end
	doorTracers = {}
end

OtherTab:CreateToggle({
	Name = "Highlight Swing Doors",
	CurrentValue = false,
	Flag = "DoorHighlightToggle",
	Callback = function(Value)
		doorHighlightEnabled = Value
		for _, hl in ipairs(doorHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		doorHighlights = {}

		if doorHighlightEnabled then
			for _, doorObj in ipairs(getTargetDoors()) do
				local highlight = Instance.new("Highlight")
				highlight.Name = "TWKS_DoorHighlight"
				highlight.Adornee = doorObj
				highlight.FillColor = doorColor
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.3
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = doorObj
				table.insert(doorHighlights, highlight)
			end
		end
	end,
})

OtherTab:CreateToggle({
	Name = "Highlight Slide Doors",
	CurrentValue = false,
	Flag = "SlideDoorHighlightToggle",
	Callback = function(Value)
		slideDoorHighlightEnabled = Value
		for _, hl in ipairs(slideDoorHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		slideDoorHighlights = {}

		if slideDoorHighlightEnabled then
			for _, doorObj in ipairs(getTargetSlideDoors()) do
				local highlight = Instance.new("Highlight")
				highlight.Name = "TWKS_SlideDoorHighlight"
				highlight.Adornee = doorObj
				highlight.FillColor = slideDoorColor
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.3
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = doorObj
				table.insert(slideDoorHighlights, highlight)
			end
		end
	end,
})

OtherTab:CreateToggle({
	Name = "Highlight Double Doors",
	CurrentValue = false,
	Flag = "DoubleDoorHighlightToggle",
	Callback = function(Value)
		doubleDoorHighlightEnabled = Value
		for _, hl in ipairs(doubleDoorHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		doubleDoorHighlights = {}

		if doubleDoorHighlightEnabled then
			for _, doorObj in ipairs(getTargetDoubleDoors()) do
				local highlight = Instance.new("Highlight")
				highlight.Name = "TWKS_DoubleDoorHighlight"
				highlight.Adornee = doorObj
				highlight.FillColor = doubleDoorColor
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.3
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = doorObj
				table.insert(doubleDoorHighlights, highlight)
			end
		end
	end,
})

OtherTab:CreateToggle({
	Name = "Tracer to Swing Doors",
	CurrentValue = false,
	Flag = "DoorTracerToggle",
	Callback = function(Value)
		doorTracerEnabled = Value
		if not doorTracerEnabled then clearDoorTracers() end
	end,
})

OtherTab:CreateColorPicker({
	Name = "Swing Door Color",
	Color = Color3.fromRGB(255, 0, 0),
	Flag = "DoorColorPicker",
	Callback = function(Value)
		doorColor = Value
		for _, hl in ipairs(doorHighlights) do
			if hl and hl.Parent then hl.FillColor = doorColor end
		end
	end
})

OtherTab:CreateColorPicker({
	Name = "Slide Door Color",
	Color = Color3.fromRGB(255, 170, 0),
	Flag = "SlideDoorColorPicker",
	Callback = function(Value)
		slideDoorColor = Value
		for _, hl in ipairs(slideDoorHighlights) do
			if hl and hl.Parent then hl.FillColor = slideDoorColor end
		end
	end
})

OtherTab:CreateColorPicker({
	Name = "Double Door Color",
	Color = Color3.fromRGB(0, 170, 255),
	Flag = "DoubleDoorColorPicker",
	Callback = function(Value)
		doubleDoorColor = Value
		for _, hl in ipairs(doubleDoorHighlights) do
			if hl and hl.Parent then hl.FillColor = doubleDoorColor end
		end
	end
})

OtherTab:CreateToggle({
	Name = "Anti-AFK Protection",
	CurrentValue = false,
	Flag = "AntiAfkToggle",
	Callback = function(Value)
		antiAfkEnabled = Value
	end,
})

LocalPlayer.Idled:Connect(function()
	if antiAfkEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- =======================================================
-- 4. VISUALS TAB
-- =======================================================

VisualsTab:CreateToggle({
	Name = "Highlight Players (Cop/Crim)",
	CurrentValue = false,
	Flag = "PlayerEspToggle",
	Callback = function(Value)
		playerEspEnabled = Value
		if not playerEspEnabled then
			for _, hl in pairs(playerHighlights) do
				if hl and hl.Parent then hl:Destroy() end
			end
			playerHighlights = {}
		end
	end,
})

VisualsTab:CreateToggle({
	Name = "Skeleton WallHack",
	CurrentValue = false,
	Flag = "SkeletonEspToggle",
	Callback = function(Value)
		skeletonEspEnabled = Value
		if not skeletonEspEnabled then
			for _, lines in pairs(skeletonLines) do
				for _, line in ipairs(lines) do
					line.Visible = false
					line:Remove()
				end
			end
			skeletonLines = {}
		end
	end,
})

VisualsTab:CreateToggle({
	Name = "FullBright / Night Vision",
	CurrentValue = false,
	Flag = "FullBrightToggle",
	Callback = function(Value)
		fullBrightEnabled = Value
		if not fullBrightEnabled then
			Lighting.Brightness = originalLightingProps.Brightness
			Lighting.ClockTime = originalLightingProps.ClockTime
			Lighting.FogEnd = originalLightingProps.FogEnd
			Lighting.GlobalShadows = originalLightingProps.GlobalShadows
			Lighting.Ambient = originalLightingProps.Ambient
			Lighting.OutdoorAmbient = originalLightingProps.OutdoorAmbient
		end
	end,
})

local skyNames = {"Default"}
for name, _ in pairs(skyboxes) do table.insert(skyNames, name) end

VisualsTab:CreateDropdown({
	Name = "Select Skybox",
	Options = skyNames,
	CurrentOption = "Default",
	Flag = "SkyboxDropdown",
	Callback = function(Option)
		local currentAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		
		for _, v in pairs(Lighting:GetChildren()) do
			if v:IsA("Sky") then v:Destroy() end
		end

		if Option == "Default" or not skyboxes[Option] then
			if currentAtmosphere and originalAtmosphereDensity then
				currentAtmosphere.Density = originalAtmosphereDensity
			end
			return
		end

		if currentAtmosphere then
			if not originalAtmosphereDensity then
				originalAtmosphereDensity = currentAtmosphere.Density
			end
			currentAtmosphere.Density = 0
		end

		local ids = skyboxes[Option]
		local newSky = Instance.new("Sky")
		newSky.Name = "TWKS_CustomSky"
		newSky.SkyboxBk = "rbxassetid://" .. ids[1]
		newSky.SkyboxDn = "rbxassetid://" .. ids[2]
		newSky.SkyboxFt = "rbxassetid://" .. ids[3]
		newSky.SkyboxLf = "rbxassetid://" .. ids[4]
		newSky.SkyboxRt = "rbxassetid://" .. ids[5]
		newSky.SkyboxUp = "rbxassetid://" .. ids[6]
		newSky.Parent = Lighting
	end,
})

local function drawSkeletonForCharacter(character, playerKey)
	if not Drawing then return end
	
	local joints = {
		{"Head", "UpperTorso"},
		{"UpperTorso", "LowerTorso"},
		{"UpperTorso", "LeftUpperArm"},
		{"LeftUpperArm", "LeftLowerArm"},
		{"LeftLowerArm", "LeftHand"},
		{"UpperTorso", "RightUpperArm"},
		{"RightUpperArm", "RightLowerArm"},
		{"RightLowerArm", "RightHand"},
		{"LowerTorso", "LeftUpperLeg"},
		{"LeftUpperLeg", "LeftLowerLeg"},
		{"LeftLowerLeg", "LeftFoot"},
		{"LowerTorso", "RightUpperLeg"},
		{"RightUpperLeg", "RightLowerLeg"},
		{"RightLowerLeg", "RightFoot"}
	}

	if not skeletonLines[playerKey] then
		skeletonLines[playerKey] = {}
		for i = 1, #joints do
			local line = Drawing.new("Line")
			line.Thickness = 1.5
			line.Color = Color3.fromRGB(255, 255, 255)
			line.Transparency = 1
			table.insert(skeletonLines[playerKey], line)
		end
	end

	for idx, pair in ipairs(joints) do
		local partA = character:FindFirstChild(pair[1])
		local partB = character:FindFirstChild(pair[2])
		local line = skeletonLines[playerKey][idx]

		if partA and partB and line then
			local posA, visA = Camera:WorldToViewportPoint(partA.Position)
			local posB, visB = Camera:WorldToViewportPoint(partB.Position)

			if visA and visB then
				line.From = Vector2.new(posA.X, posA.Y)
				line.To = Vector2.new(posB.X, posB.Y)
				line.Visible = true
			else
				line.Visible = false
			end
		elseif line then
			line.Visible = false
		end
	end
end

-- =======================================================
-- 5. CAMERA TAB
-- =======================================================

local function toggleFreecam(state)
	if state == nil then
		freecamEnabled = not freecamEnabled
	else
		freecamEnabled = state
	end

	if freecamEnabled then
		Camera.CameraType = Enum.CameraType.Scriptable
		cameraPos = Camera.CFrame.Position
		local rx, ry, rz = Camera.CFrame:ToOrientation()
		cameraYaw = ry
		cameraPitch = rx

		freecamConnection = RunService.RenderStepped:Connect(function()
			if not freecamEnabled then return end
			
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end

			local rotCFrame = CFrame.Angles(0, cameraYaw, 0) * CFrame.Angles(cameraPitch, 0, 0)
			local moveVector = Vector3.new()

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + rotCFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - rotCFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - rotCFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + rotCFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector = moveVector + rotCFrame.UpVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - rotCFrame.UpVector end

			local currentSpeed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and (freecamSpeed * 3) or freecamSpeed
			cameraPos = cameraPos + (moveVector * currentSpeed)
			Camera.CFrame = CFrame.new(cameraPos) * rotCFrame
		end)
	else
		if freecamConnection then
			freecamConnection:Disconnect()
			freecamConnection = nil
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		Camera.CameraType = Enum.CameraType.Custom
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
			Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		end
	end
end

UserInputService.InputChanged:Connect(function(input)
	if freecamEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Delta
			local sensitivity = 0.003
			cameraYaw = cameraYaw - (delta.X * sensitivity)
			cameraPitch = math.clamp(cameraPitch - (delta.Y * sensitivity), math.rad(-89), math.rad(89))
		end
	end
end)

freecamToggleRef = CameraTab:CreateToggle({
	Name = "FreeCamera Enabled",
	CurrentValue = false,
	Flag = "FreecamToggle",
	Callback = function(Value)
		if Value ~= freecamEnabled then toggleFreecam(Value) end
	end,
})

CameraTab:CreateKeybind({
	Name = "Toggle FreeCamera Bind",
	CurrentKeybind = "P",
	HoldToInteract = false,
	Flag = "FreecamKeybind",
	Callback = function()
		toggleFreecam()
		if freecamToggleRef then freecamToggleRef:Set(freecamEnabled) end
	end,
})

CameraTab:CreateSlider({
	Name = "FreeCam Speed",
	Range = {0.1, 5},
	Increment = 0.1,
	Suffix = "Speed",
	CurrentValue = 1,
	Flag = "FreecamSpeedSlider",
	Callback = function(Value)
		freecamSpeed = Value
	end,
})

-- =======================================================
-- ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ
-- =======================================================

RunService.RenderStepped:Connect(function()
	-- FullBright обработка
	if fullBrightEnabled then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 786433
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	end

	-- FOV Circle
	if fovCircle then
		local mousePos = UserInputService:GetMouseLocation()
		fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
		fovCircle.Visible = useFov and aimbotEnabled
	end

	-- Aimbot
	if aimbotEnabled and aimbotKeyHold and not freecamEnabled then
		local targetPart = getClosestPlayerInFOV()
		if targetPart then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
		end
	end

	-- Hitbox Expander без лага персонажа (проверка изменений вместо перезаписи каждого кадра)
	if hitboxEnabled then
		local targetSize = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				local head = player.Character:FindFirstChild("Head")
				if head and head.Size ~= targetSize then
					head.Size = targetSize
					head.Transparency = 0.5
					head.CanCollide = false
					head.Massless = true
				end
			end
		end
	end

	-- Player ESP
	if playerEspEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				local char = player.Character
				local hl = playerHighlights[player]
				if not hl or hl.Parent ~= char then
					hl = Instance.new("Highlight")
					hl.Name = "TWKS_PlayerESP"
					hl.Adornee = char
					hl.FillTransparency = 0.4
					hl.OutlineTransparency = 0
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = char
					playerHighlights[player] = hl
				end

				local teamName = player.Team and player.Team.Name or ""
				if string.find(teamName:lower(), "police") or string.find(teamName:lower(), "cop") then
					hl.FillColor = Color3.fromRGB(0, 150, 255)
				else
					hl.FillColor = Color3.fromRGB(255, 50, 50)
				end
			elseif playerHighlights[player] then
				playerHighlights[player]:Destroy()
				playerHighlights[player] = nil
			end
		end
	end

	-- Door Tracers
	if doorTracerEnabled then
		local doors = getTargetDoors()
		if #doors > 0 and Drawing then
			for index, door in ipairs(doors) do
				local tracer = doorTracers[index]
				if not tracer then
					tracer = Drawing.new("Line")
					tracer.Thickness = 2
					tracer.Transparency = 1
					doorTracers[index] = tracer
				end

				local doorPos = door:IsA("Model") and door:GetPivot().Position or (door:IsA("BasePart") and door.Position or nil)
				if doorPos then
					local screenPos, onScreen = Camera:WorldToViewportPoint(doorPos)
					if onScreen then
						tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
						tracer.To = Vector2.new(screenPos.X, screenPos.Y)
						tracer.Color = doorColor
						tracer.Visible = true
					else
						tracer.Visible = false
					end
				else
					tracer.Visible = false
				end
			end
		end
	else
		clearDoorTracers()
	end

	-- Skeleton ESP
	if skeletonEspEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				drawSkeletonForCharacter(player.Character, player.Name)
			elseif skeletonLines[player.Name] then
				for _, line in ipairs(skeletonLines[player.Name]) do
					line.Visible = false
				end
			end
		end
	end
end)