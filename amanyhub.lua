--[[
	YOKAI UI - FINAL INTEGRATED SCRIPT (v12)
	RightControl = GUIを開く/閉じる
	Kill Sound: GitHubアセットリスト + ポップアップ + 小数点音量 + 自動取得
]]

local uis = game:GetService("UserInputService")
local hs = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local REMOTE_CONFIG_BASE = "https://raw.githubusercontent.com/amanycham/8PA3Jgw4wZYndsHE7L8M/refs/heads/main/"
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--==================== UTILITY ====================--
local utility = { is_dragging_blocked = false }

do
	local newInstance = Instance.new
	utility.setDraggable = function(object)
		local dragging = false
		object.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not utility.is_dragging_blocked then
				local mouse = uis:GetMouseLocation()
				local sx, sy = mouse.X, mouse.Y
				local ox, oy = object.Position.X.Offset, object.Position.Y.Offset
				dragging = true
				task.spawn(function()
					while dragging and not utility.is_dragging_blocked do
						mouse = uis:GetMouseLocation()
						object.Position = UDim2.new(0, ox - (sx - mouse.X), 0, oy - (sy - mouse.Y))
						task.wait()
					end
				end)
			end
		end)
		object.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end
	utility.newObject = function(class, props)
		local obj = newInstance(class)
		for k,v in pairs(props) do obj[k] = v end
		obj.Name = hs:GenerateGUID(false)
		return obj
	end
end

--==================== RGB ====================--
local rainbowBoxes = {}
task.spawn(function()
	while true do
		local hue = (tick() * 0.45) % 1
		local color = Color3.fromHSV(hue, 0.92, 1)
		for i = #rainbowBoxes, 1, -1 do
			local b = rainbowBoxes[i]
			if b and b.Parent then b.BackgroundColor3 = color
			else table.remove(rainbowBoxes, i) end
		end
		task.wait(1/30)
	end
end)
local function enableRainbow(box)
	for _,v in ipairs(rainbowBoxes) do if v == box then return end end
	table.insert(rainbowBoxes, box)
end
local function disableRainbow(box)
	for i,v in ipairs(rainbowBoxes) do
		if v == box then table.remove(rainbowBoxes, i) break end
	end
	box.BackgroundColor3 = Color3.fromRGB(30,30,30)
end

--==================== CONFIG ====================--
local CONFIG_FOLDER = "YokaiConfigs"
if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end

local settings = { AutoLoad = false, SilentLoad = false, LastConfig = "" }
if isfile(CONFIG_FOLDER.."/settings.json") then
	pcall(function() settings = hs:JSONDecode(readfile(CONFIG_FOLDER.."/settings.json")) end)
end
local function saveSettings()
	writefile(CONFIG_FOLDER.."/settings.json", hs:JSONEncode(settings))
end
local selectedConfig = settings.LastConfig or ""

--==================== UI CORE ====================--
local menu, window, tab, section = {}, {}, {}, {}
window.__index = window
tab.__index = tab
section.__index = section

local _screenGui

do
	local newObject = utility.newObject
	_screenGui = newObject("ScreenGui", {
		Parent = player:WaitForChild("PlayerGui"),
		ResetOnSpawn = false,
		Enabled = not settings.SilentLoad
	})

	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightControl then
			_screenGui.Enabled = not _screenGui.Enabled
		end
	end)

	function menu:init(tabs)
		local Border = newObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(60,60,60),
			BorderColor3 = Color3.fromRGB(12,12,12),
			Position = UDim2.new(0.5,-329,0.5,-279),
			Size = UDim2.new(0,658,0,558),
			Parent = _screenGui
		})
		local Border2 = newObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(40,40,40),
			BorderColor3 = Color3.fromRGB(40,40,40),
			Position = UDim2.new(0,2,0,2),
			Size = UDim2.new(1,-4,1,-4),
			Parent = Border
		})
		local Background = newObject("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderColor3 = Color3.fromRGB(60,60,60),
			Position = UDim2.new(0,3,0,3),
			Size = UDim2.new(1,-6,1,-6),
			Image = "rbxassetid://15453092054",
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.new(0,4,0,548),
			Parent = Border2
		})
		local TabHolder = newObject("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0,0,0,14),
			Size = UDim2.new(0,73,0,0),
			Parent = Background
		})
		newObject("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = TabHolder
		})
		newObject("Frame", {BackgroundColor3=Color3.fromRGB(12,12,12), Size=UDim2.new(0,73,0,14), Parent=Background})
		newObject("Frame", {BackgroundColor3=Color3.fromRGB(12,12,12), Position=UDim2.new(0,0,1,-22), Size=UDim2.new(0,73,0,22), Parent=Background})

		utility.setDraggable(Border)

		local win = { tab_holder = TabHolder, active_tab = nil, background = Background, tabs = {}, tabCount = #tabs }
		setmetatable(win, window)

		local first = true
		for i=1,#tabs do
			win:_registerTab(i, tabs[i], first)
			first = false
		end
		return win
	end

	function window:_registerTab(int, info, isFirst)
		local new_tab = { sections = {} }
		local Button = newObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(12,12,12),
			Size = UDim2.new(0,73,0,math.floor(448/self.tabCount)),
			Parent = self.tab_holder
		})
		local Icon = newObject("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,1,0),
			Image = info.icon,
			ImageColor3 = Color3.fromRGB(109,109,109),
			Parent = Button
		})
		if info.name then
			newObject("TextLabel", {
				BackgroundColor3=Color3.fromRGB(12,12,12), BorderSizePixel=0,
				Position=UDim2.new(0,0,1,-18), Size=UDim2.new(1,0,0,18),
				Text=info.name, Font=Enum.Font.SourceSansBold, TextSize=13,
				TextColor3=Color3.fromRGB(220,220,220), Parent=Button
			})
		end
		local _Tab = newObject("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0,96,0,23),
			Size = UDim2.new(0,532,0,506),
			Visible = false,
			Parent = self.background
		})

		Button.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and self.active_tab ~= int then
				self:_setActiveTab(int)
			end
		end)
		Button.MouseEnter:Connect(function()
			if self.active_tab ~= int then Icon.ImageColor3 = Color3.fromRGB(204,204,204) end
		end)
		Button.MouseLeave:Connect(function()
			if self.active_tab ~= int then Icon.ImageColor3 = Color3.fromRGB(109,109,109) end
		end)

		new_tab.button = Button
		new_tab.icon = Icon
		new_tab.frame = _Tab
		setmetatable(new_tab, tab)
		self.tabs[int] = new_tab
		if isFirst then self:_setActiveTab(int) end
		return new_tab
	end

	function window:_setActiveTab(int)
		self.active_tab = int
		for i=1,self.tabCount do
			local t = self.tabs[i]
			if t then
				local active = (i == int)
				t.icon.ImageColor3 = active and Color3.fromRGB(255,255,255) or Color3.fromRGB(109,109,109)
				t.button.BackgroundTransparency = active and 1 or 0
				t.frame.Visible = active
			end
		end
	end

	function window:getTab(i) return self.tabs[i] end

	function tab:newSection(info)
		local Section = newObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(12,12,12),
			Size = UDim2.new(0.5,-9, info.scale, -9),
			Parent = self.frame
		})
		local Inside = newObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(40,40,40),
			Position = UDim2.new(0,1,0,1),
			Size = UDim2.new(1,-2,1,-2),
			Parent = Section
		})
		local Inside2 = newObject("Frame", {
			BackgroundColor3 = Color3.fromRGB(23,23,23),
			Position = UDim2.new(0,1,0,1),
			Size = UDim2.new(1,-2,1,-2),
			Parent = Inside
		})
		newObject("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0,12,0,-2),
			Font = Enum.Font.SourceSansBold,
			Text = info.name,
			TextColor3 = Color3.fromRGB(198,198,198),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Inside2
		})
		local ns = { frame = Section, container = Inside2 }
		setmetatable(ns, section)
		if info.is_changeable then
			newObject("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(1,-5,1,-5),
				Size = UDim2.new(0,5,0,5),
				Image = "rbxassetid://15501723105",
				Parent = Inside2
			})
		end
		self.sections[info.name] = ns
		return ns
	end
end

local window = menu:init({
	[1] = {icon="rbxassetid://15453302474"},
	[2] = {icon="rbxassetid://15453313321"},
	[3] = {icon="rbxassetid://15453335745"},
	[4] = {icon="rbxassetid://15453344494"},
	[5] = {icon="rbxassetid://15453349637"},
	[6] = {icon="rbxassetid://15453359751"},
	[7] = {icon="rbxassetid://15453364412"}
})

--==================== HELPER ====================--
local function makeToggle(parent, text, y, callback)
	utility.newObject("TextLabel", {
		BackgroundTransparency=1, Position=UDim2.new(0,12,0,y), Size=UDim2.new(0,140,0,16),
		Font=Enum.Font.SourceSans, Text=text, TextColor3=Color3.fromRGB(198,198,198), TextSize=14,
		TextXAlignment=Enum.TextXAlignment.Left, Parent=parent
	})
	local box = utility.newObject("Frame", {
		BackgroundColor3=Color3.fromRGB(30,30,30), BorderColor3=Color3.fromRGB(80,80,80),
		BorderSizePixel=1, Position=UDim2.new(0,160,0,y+1), Size=UDim2.new(0,14,0,14), Parent=parent
	})
	local toggle = {
		state = false,
		setState = function(self, newState)
			if self.state ~= newState then
				self.state = newState
				if newState then enableRainbow(box) else disableRainbow(box) end
				callback(newState)
			end
		end
	}
	box.InputBegan:Connect(function(i,g)
		if g then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			toggle.state = not toggle.state
			if toggle.state then enableRainbow(box) else disableRainbow(box) end
			callback(toggle.state)
		end
	end)
	return toggle
end

-- ★ decimals: 小数点以下の桁数 (0=整数, 1=0.1刻み, 2=0.01刻み)
local function makeSlider(parent, y, min, max, default, cb, decimals)
	decimals = decimals or 0
	local function fmt(v)
		if decimals == 0 then
			return tostring(math.floor(v + 0.5))
		end
		return string.format("%." .. decimals .. "f", v)
	end
	local function round(v)
		if decimals == 0 then return math.floor(v + 0.5) end
		local mult = 10 ^ decimals
		return math.floor(v * mult + 0.5) / mult
	end
	local bg=utility.newObject("Frame",{BackgroundColor3=Color3.fromRGB(40,40,40),BorderColor3=Color3.fromRGB(70,70,70),BorderSizePixel=1,Position=UDim2.new(0,12,0,y),Size=UDim2.new(0,170,0,8),Parent=parent})
	local fill=utility.newObject("Frame",{BackgroundColor3=Color3.fromRGB(100,160,255),BorderSizePixel=0,Size=UDim2.new((default-min)/(max-min),0,1,0),Parent=bg})
	local val=utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,190,0,y-4),Size=UDim2.new(0,50,0,16),Font=Enum.Font.SourceSans,Text=fmt(default),TextColor3=Color3.fromRGB(200,200,200),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Parent=parent})
	local sliding=false
	bg.InputBegan:Connect(function(i,g) if g then return end; if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; utility.is_dragging_blocked=true end end)
	uis.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false; utility.is_dragging_blocked=false end end)
	uis.InputChanged:Connect(function(i)
		if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
			local m=uis:GetMouseLocation()
			local r=math.clamp((m.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
			local v=min+r*(max-min)
			v = round(v)
			fill.Size=UDim2.new((v-min)/(max-min),0,1,0)
			val.Text=fmt(v)
			cb(v)
		end
	end)
end

--==================== HTTP (エグゼキューター対応) ====================--
local function httpGet(url)
	if typeof(game.HttpGet) == "function" then
		local ok, res = pcall(function() return game:HttpGet(url, true) end)
		if ok and res and #res > 0 then return res end
	end
	if typeof(request) == "function" then
		local ok, res = pcall(function()
			local r = request({ Url = url, Method = "GET" })
			return r and r.Body
		end)
		if ok and res and #res > 0 then return res end
	end
	if typeof(syn) == "table" and typeof(syn.request) == "function" then
		local ok, res = pcall(function()
			local r = syn.request({ Url = url, Method = "GET" })
			return r and r.Body
		end)
		if ok and res and #res > 0 then return res end
	end
	if typeof(http_request) == "function" then
		local ok, res = pcall(function()
			local r = http_request({ Url = url, Method = "GET" })
			return r and r.Body
		end)
		if ok and res and #res > 0 then return res end
	end
	local ok, res = pcall(function() return hs:GetAsync(url) end)
	if ok and res and #res > 0 then return res end
	return nil
end

--==================== TRANSFORM MANAGER ====================--
local TransformManager = {
	activeTransform = nil,
	modelCache = {},
	originalData = nil,
	hasBackedUp = false
}

local ARM_NAMES = {"LeftArm", "RightArm", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm"}

local BODY_PART_NAMES = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftArm", "RightArm", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
	"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"
}

local transformIds = {
	Amany = 4015261840,
	Riz = 5029936365,
	Yokai = 62536494
}

local function backupCharacter(char)
	if TransformManager.hasBackedUp then return end
	TransformManager.originalData = { parts = {}, clothing = {}, accessories = {} }

	for _, name in ipairs(BODY_PART_NAMES) do
		local part = char:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			TransformManager.originalData.parts[name] = {
				MeshId = part.MeshId or "",
				TextureID = part.TextureID or "",
				Color = part.Color,
				Material = part.Material,
				Transparency = part.Transparency,
				Mesh = part:FindFirstChildOfClass("SpecialMesh") and part:FindFirstChildOfClass("SpecialMesh"):Clone() or nil
			}
		end
	end

	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
			TransformManager.originalData.clothing[obj.Name] = obj:Clone()
		elseif obj:IsA("Accessory") then
			TransformManager.originalData.accessories[obj.Name] = obj:Clone()
		end
	end

	TransformManager.hasBackedUp = true
	print("📦 バックアップ完了")
end

local function restoreCharacter(char)
	if not char or not TransformManager.originalData then
		print("⚠️ 復元スキップ: データなし")
		return
	end

	for _, name in ipairs(BODY_PART_NAMES) do
		local part = char:FindFirstChild(name)
		local data = TransformManager.originalData.parts[name]
		if part and data then
			pcall(function()
				if part:IsA("MeshPart") then
					part.MeshId = data.MeshId
					part.TextureID = data.TextureID
				end
				part.Color = data.Color
				part.Material = data.Material
				part.Transparency = data.Transparency
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("SpecialMesh") then child:Destroy() end
				end
				if data.Mesh then
					local newMesh = data.Mesh:Clone()
					newMesh.Parent = part
				end
			end)
		end
	end

	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("Accessory") then
			obj:Destroy()
		end
	end

	for _, clothing in pairs(TransformManager.originalData.clothing) do
		pcall(function() clothing:Clone().Parent = char end)
	end
	for _, accessory in pairs(TransformManager.originalData.accessories) do
		pcall(function() accessory:Clone().Parent = char end)
	end

	TransformManager.originalData = nil
	TransformManager.hasBackedUp = false
	print("♻️ 復元完了")
end

local function applyArmParts(char, modelClone)
	for _, name in ipairs(ARM_NAMES) do
		local targetPart = modelClone:FindFirstChild(name)
		local charPart = char:FindFirstChild(name)
		if targetPart and charPart and targetPart:IsA("BasePart") and charPart:IsA("BasePart") then
			pcall(function()
				if charPart:IsA("MeshPart") and targetPart:IsA("MeshPart") then
					charPart.MeshId = targetPart.MeshId
					charPart.TextureID = targetPart.TextureID
				end
				local targetMesh = targetPart:FindFirstChildOfClass("SpecialMesh")
				if targetMesh then
					for _, child in ipairs(charPart:GetChildren()) do
						if child:IsA("SpecialMesh") then child:Destroy() end
					end
					local newMesh = targetMesh:Clone()
					newMesh.Parent = charPart
				end
				charPart.Color = targetPart.Color
				charPart.Material = targetPart.Material
				charPart.Transparency = targetPart.Transparency
			end)
		end
	end
end

local function removeHairAccessories(char)
	if not char then return end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle then
				local att = handle:FindFirstChildOfClass("Attachment")
				if att then
					local attName = att.Name
					if string.find(attName, "Hair") or string.find(attName, "hair") then
						handle.Transparency = 1
						for _, desc in ipairs(handle:GetDescendants()) do
							if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("MeshPart") then
								desc.Transparency = 1
							end
						end
						local mesh = handle:FindFirstChildOfClass("SpecialMesh")
						if mesh then mesh.Scale = Vector3.new(0, 0, 0) end
					end
				end
			end
		end
	end
end

-- Accessory attachment lookup must ignore aura/other accessory descendants.
local function findBodyAttachment(char, name)
	for _,bodyPart in ipairs(char:GetChildren()) do
		if bodyPart:IsA("BasePart") then
			local attachment=bodyPart:FindFirstChild(name)
			if attachment and attachment:IsA("Attachment") then return attachment end
		end
	end
end
local function applyTransform(char, userId, transformName)
	if not char then return end
	local model = TransformManager.modelCache[userId]
	if not model then
		task.spawn(function()
			local success, result = pcall(function() return Players:GetCharacterAppearanceAsync(userId) end)
			if success and result then
				TransformManager.modelCache[userId] = result
				if player.Character then applyTransform(player.Character, userId, transformName) end
			else
				warn("❌ モデル取得失敗: " .. transformName)
			end
		end)
		return
	end

	task.spawn(function()
		local ok, err = pcall(function()
			backupCharacter(char)
			local modelClone = model:Clone()
			local itemNames = {}
			for _, child in ipairs(modelClone:GetChildren()) do itemNames[child.Name] = true end

			for _, obj in pairs(char:GetChildren()) do
				if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then obj:Destroy() end
			end
			for _, obj in pairs(char:GetChildren()) do
				if obj:IsA("Accessory") and itemNames[obj.Name] then obj:Destroy() end
			end
			removeHairAccessories(char)

			for _, item in pairs(modelClone:GetChildren()) do
				task.spawn(function()
					pcall(function()
						if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
							item.Parent = char
						elseif item:IsA("Accessory") then
							local handle = item:FindFirstChild("Handle")
							if handle then
								handle.CanCollide = false
								handle.Massless = true
								handle.Anchored = false
								for _,desc in ipairs(item:GetDescendants()) do
									if desc:IsA("BasePart") then
										desc.Anchored=false
										desc.Massless=true
										desc.CanCollide=false
										desc.CanTouch=false
										desc.CanQuery=false
									elseif desc.Name=="AccessoryWeld" and desc:IsA("JointInstance") then
										desc:Destroy()
									end
								end
								handle.CanTouch = false
								handle.CanQuery = false
								handle.Transparency = 0
								local att = handle:FindFirstChildOfClass("Attachment")
								if att then
									local charAtt = findBodyAttachment(char, att.Name)
									if charAtt then
										local weld = Instance.new("Weld")
										weld.Part0 = handle
										weld.Part1 = charAtt.Parent
										weld.C0 = att.CFrame
										weld.C1 = charAtt.CFrame
										weld.Parent = handle
									end
								end
								item.Parent = char
							end
						end
					end)
				end)
			end

			applyArmParts(char, modelClone)
			task.wait(0.5)
			if char and char.Parent then removeHairAccessories(char) end
			task.wait(1.0)
			if char and char.Parent then removeHairAccessories(char) end
			print("✅ " .. transformName .. " 適用完了")
		end)
		if not ok then warn("❌ Transform エラー (" .. transformName .. "): " .. tostring(err)) end
	end)
end

local transformToggles = {}

local function setTransform(name, enable)
	if enable then
		for otherName, toggle in pairs(transformToggles) do
			if otherName ~= name and toggle.state then toggle:setState(false) end
		end
		TransformManager.activeTransform = name
		if player.Character then applyTransform(player.Character, transformIds[name], name) end
	else
		if TransformManager.activeTransform == name then
			TransformManager.activeTransform = nil
			if player.Character then restoreCharacter(player.Character) end
		end
	end
end

player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	TransformManager.originalData = nil
	TransformManager.hasBackedUp = false
	if TransformManager.activeTransform then
		applyTransform(char, transformIds[TransformManager.activeTransform], TransformManager.activeTransform)
	end
end)

task.spawn(function()
	for name, id in pairs(transformIds) do
		local success, model = pcall(function() return Players:GetCharacterAppearanceAsync(id) end)
		if success and model then
			TransformManager.modelCache[id] = model
			print("✅ " .. name .. " 事前キャッシュ取得成功")
		end
	end
end)

--==================== SKIN CHANGER ====================--
local SkinChanger = {
	initialized = false, enabled = false,
	_eq = {}, _favs = {}, _cosLib = nil, _datCtrl = nil, _fightCtrl = nil,
	_cfgFile = "rivals_unlocker_config.json",
	_cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
}

local function _isCosType(cosObj)
	if not cosObj then return false end
	for _, t in ipairs(SkinChanger._cosTypes) do if cosObj.Type == t then return true end end
	return false
end

local function _mkCosmetic(nm, ctype, opts)
	if not SkinChanger._cosLib then return nil end
	local _base = SkinChanger._cosLib.Cosmetics[nm]
	if not _base then return nil end
	local _d = {}
	for k, v in pairs(_base) do _d[k] = v end
	_d.Name = nm; _d.Type = _d.Type or ctype; _d.Seed = _d.Seed or math.random(1, 1000000)
	if opts then
		if opts.inverted ~= nil then _d.Inverted = opts.inverted end
		if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
	end
	return _d
end

local function _stripForSave()
	local _out = {}
	for wn, cos in pairs(SkinChanger._eq) do
		_out[wn] = {}
		for ct, cd in pairs(cos) do
			if cd and cd.Name then _out[wn][ct] = { Name = cd.Name, Inverted = cd.Inverted, OnlyUseFavorites = cd.OnlyUseFavorites } end
		end
	end
	return { equipped = _out, favorites = SkinChanger._favs }
end

local function _saveCfg()
	if not writefile then return end
	task.spawn(function()
		task.wait(1)
		local _ok, _enc = pcall(hs.JSONEncode, hs, _stripForSave())
		if _ok then pcall(writefile, SkinChanger._cfgFile, _enc) end
	end)
end

local function _loadCfg()
	if not isfile or not readfile then return end
	local _ok1, _ex = pcall(isfile, SkinChanger._cfgFile)
	if not _ok1 or not _ex then return end
	local _ok2, _raw = pcall(readfile, SkinChanger._cfgFile)
	if not _ok2 or not _raw or _raw == "" then return end
	local _ok3, _dec = pcall(hs.JSONDecode, hs, _raw)
	if not _ok3 or not _dec then return end
	if _dec.favorites then SkinChanger._favs = _dec.favorites end
	if _dec.equipped and SkinChanger._cosLib then
		SkinChanger._eq = {}
		for wn, cos in pairs(_dec.equipped) do
			SkinChanger._eq[wn] = {}
			for ct, sd in pairs(cos) do
				if sd and sd.Name and SkinChanger._cosLib.Cosmetics[sd.Name] then
					local _cloned = _mkCosmetic(sd.Name, ct, { inverted = sd.Inverted, favoritesOnly = sd.OnlyUseFavorites })
					if _cloned then SkinChanger._eq[wn][ct] = _cloned end
				end
			end
			if not next(SkinChanger._eq[wn]) then SkinChanger._eq[wn] = nil end
		end
	end
end

local function _replicateData()
	if SkinChanger._datCtrl and SkinChanger._datCtrl.CurrentData then
		task.spawn(function()
			pcall(function() SkinChanger._datCtrl.CurrentData:Replicate("WeaponInventory") end)
			pcall(function() SkinChanger._datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
		end)
	end
end

local function initSkinChanger()
	if SkinChanger.initialized then return true end
	local _rs = game:GetService("ReplicatedStorage")
	local _mods = _rs:WaitForChild("Modules", 10)
	pcall(function() local e = require(_mods:WaitForChild("EnumLibrary", 10)); e:WaitForEnumBuilder() end)
	local _cosLibOk, _cosLib = pcall(require, _mods:WaitForChild("CosmeticLibrary", 10))
	if not _cosLibOk then warn("⚠️ CosmeticLibrary が見つかりません"); return false end
	SkinChanger._cosLib = _cosLib
	local _ctrl = player:WaitForChild("PlayerScripts"):WaitForChild("Controllers", 10)
	local _datCtrlOk, _datCtrl = pcall(require, _ctrl:WaitForChild("PlayerDataController", 10))
	if not _datCtrlOk then warn("⚠️ PlayerDataController が見つかりません"); return false end
	SkinChanger._datCtrl = _datCtrl
	pcall(function() SkinChanger._fightCtrl = require(_ctrl:WaitForChild("FighterController", 10)) end)

	_cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep) local c = _cosLib.Cosmetics[nm]; if c and c.Type == "Skin" then return true end; return false end
	_cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep) local c = _cosLib.Cosmetics[nm]; if c and c.Type == "Skin" then return true end; return false end
	_cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep) local c = _cosLib.Cosmetics[nm]; if c and c.Type == "Skin" then return true end; return false end

	local _origOwns = _cosLib.OwnsCosmetic
	_cosLib.OwnsCosmetic = function(self, inv, nm, wep)
		if not SkinChanger.enabled then return _origOwns(self, inv, nm, wep) end
		if nm:find("MISSING") or nm == "Bubble Gun" then return _origOwns(self, inv, nm, wep) end
		local c = _cosLib.Cosmetics[nm]; if c and _isCosType(c) then return true end
		return _origOwns(self, inv, nm, wep)
	end

	local _origGet = _datCtrl.Get
	_datCtrl.Get = function(self, key)
		local _val = _origGet(self, key)
		if not SkinChanger.enabled then return _val end
		if key == "CosmeticInventory" then
			local _prx = {}
			if _val then for k, v in pairs(_val) do local c = _cosLib.Cosmetics[k]; if c and _isCosType(c) then _prx[k] = v end end end
			return setmetatable(_prx, { __index = function(t, k) local c = _cosLib.Cosmetics[k]; if c and _isCosType(c) then return true end; return nil end })
		end
		if key == "FavoritedCosmetics" then
			local _res = _val and table.clone(_val) or {}
			for wep, fv in pairs(SkinChanger._favs) do _res[wep] = _res[wep] or {}; for nm, isFav in pairs(fv) do local c = _cosLib.Cosmetics[nm]; if c and _isCosType(c) then _res[wep][nm] = isFav end end end
			return _res
		end
		return _val
	end

	local _origGetWep = _datCtrl.GetWeaponData
	_datCtrl.GetWeaponData = function(self, wn)
		local _d = _origGetWep(self, wn); if not _d then return nil end
		local _m = {}; for k, v in pairs(_d) do _m[k] = v end; _m.Name = wn
		if SkinChanger.enabled and SkinChanger._eq[wn] then for ct, cd in pairs(SkinChanger._eq[wn]) do _m[ct] = cd end end
		return _m
	end

	if hookmetamethod then
		local _remotes = _rs:FindFirstChild("Remotes")
		local _dataRem = _remotes and _remotes:FindFirstChild("Data")
		local _equipRem = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
		local _favRem = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
		if _equipRem then
			local _onc
			_onc = hookmetamethod(game, "__namecall", function(self, ...)
				if getnamecallmethod() ~= "FireServer" then return _onc(self, ...) end
				local _a = {...}
				if self == _equipRem then
					local _wn, _ct, _cn = _a[1], _a[2], _a[3]; local _opts = _a[4] or {}
					if _cn and _cn ~= "None" and _cn ~= "" then local _inv = _datCtrl:Get("CosmeticInventory"); if _inv and rawget(_inv, _cn) then return _onc(self, ...) end end
					if SkinChanger.enabled then
						SkinChanger._eq[_wn] = SkinChanger._eq[_wn] or {}
						if not _cn or _cn == "None" or _cn == "" then SkinChanger._eq[_wn][_ct] = nil; if not next(SkinChanger._eq[_wn]) then SkinChanger._eq[_wn] = nil end
						else local _cloned = _mkCosmetic(_cn, _ct, { inverted = _opts.IsInverted, favoritesOnly = _opts.OnlyUseFavorites }); if _cloned then SkinChanger._eq[_wn][_ct] = _cloned end end
						task.defer(function() _replicateData() end); _saveCfg()
					end
					return
				end
				if self == _favRem and SkinChanger.enabled then
					local _cos = _cosLib.Cosmetics[_a[2]]
					if _cos then SkinChanger._favs[_a[1]] = SkinChanger._favs[_a[1]] or {}; SkinChanger._favs[_a[1]][_a[2]] = _a[3] or nil; task.spawn(function() _replicateData() end); _saveCfg() end
					return
				end
				return _onc(self, ...)
			end)
		end
	end

	local _cliItem
	pcall(function() _cliItem = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
	local _buildingWep = nil
	if _cliItem and _cliItem._CreateViewModel then
		local _origCVM = _cliItem._CreateViewModel
		_cliItem._CreateViewModel = function(self, vmRef)
			local _wn = self.Name; local _wp = self.ClientFighter and self.ClientFighter.Player
			_buildingWep = (_wp == player) and _wn or nil
			if _wp == player and SkinChanger.enabled and SkinChanger._eq[_wn] then
				local _dk = self:ToEnum("Data")
				if vmRef[_dk] then
					if SkinChanger._eq[_wn].Skin then vmRef[_dk][self:ToEnum("Skin")] = SkinChanger._eq[_wn].Skin; vmRef[_dk][self:ToEnum("Name")] = SkinChanger._eq[_wn].Skin.Name end
					if SkinChanger._eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = SkinChanger._eq[_wn].Charm end
					if SkinChanger._eq[_wn].Wrap then vmRef[_dk][self:ToEnum("Wrap")] = SkinChanger._eq[_wn].Wrap end
				elseif vmRef.Data then
					if SkinChanger._eq[_wn].Skin then vmRef.Data.Skin = SkinChanger._eq[_wn].Skin; vmRef.Data.Name = SkinChanger._eq[_wn].Skin.Name end
					if SkinChanger._eq[_wn].Charm then vmRef.Data.Charm = SkinChanger._eq[_wn].Charm end
					if SkinChanger._eq[_wn].Wrap then vmRef.Data.Wrap = SkinChanger._eq[_wn].Wrap end
				end
			end
			local _r = _origCVM(self, vmRef); _buildingWep = nil; return _r
		end
	end

	local _vmMod = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
	if _vmMod then
		local _CVM = require(_vmMod); local _origNew = _CVM.new
		_CVM.new = function(repData, cliItm)
			local _wp = cliItm.ClientFighter and cliItm.ClientFighter.Player; local _wn = _buildingWep or cliItm.Name
			if _wp == player and SkinChanger.enabled and SkinChanger._eq[_wn] then
				local _RC = require(_rs.Modules.ReplicatedClass); local _dk = _RC:ToEnum("Data"); repData[_dk] = repData[_dk] or {}
				local _cos = SkinChanger._eq[_wn]
				if _cos.Skin then repData[_dk][_RC:ToEnum("Skin")] = _cos.Skin end
				if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
				if _cos.Wrap then repData[_dk][_RC:ToEnum("Wrap")] = _cos.Wrap end
			end
			return _origNew(repData, cliItm)
		end
	end

	_loadCfg(); SkinChanger.initialized = true; print("✅ SkinChanger 初期化完了"); return true
end

local function setSkinChangerEnabled(enable)
	if enable then
		if not SkinChanger.initialized then local ok = initSkinChanger(); if not ok then return end end
		SkinChanger.enabled = true; _loadCfg(); _replicateData(); print("✅ SkinChanger ON")
	else
		SkinChanger.enabled = false; SkinChanger._eq = {}; SkinChanger._favs = {}; _replicateData(); print("✅ SkinChanger OFF")
	end
end

--==================== TAB 1: COMBAT ====================--
local combatTab = window:getTab(1)
local combatSec = combatTab:newSection({name="Combat", is_changeable=true, scale=0.25})

local originalCooldowns = {}
makeToggle(combatSec.container, "Fast Melee & Guns", 22, function(v)
	if game.GameId == 6035872082 then
		local success, Items = pcall(function() return require(game:GetService("ReplicatedStorage").Modules.ItemLibrary).Items end)
		if not success or type(Items) ~= "table" then return end
		local gunExceptions = { ["Sniper"] = true, ["Crossbow"] = true, ["Bow"] = true, ["RPG"] = true }
		for name, data in pairs(Items) do
			if typeof(data) == "table" then
				if v then
					if not originalCooldowns[name] then
						originalCooldowns[name] = { ShootSpread=data.ShootSpread, ShootAccuracy=data.ShootAccuracy, ShootRecoil=data.ShootRecoil, ShootCooldown=data.ShootCooldown, ShootBurstCooldown=data.ShootBurstCooldown, AttackCooldown=data.AttackCooldown, SwingCooldown=data.SwingCooldown, MeleeCooldown=data.MeleeCooldown, Cooldown=data.Cooldown, RecoveryTime=data.RecoveryTime, ResetTime=data.ResetTime }
					end
					if not gunExceptions[name] then
						if data.ShootSpread ~= nil then data.ShootSpread = 0 end
						if data.ShootAccuracy ~= nil then data.ShootAccuracy = 0 end
						if data.ShootRecoil ~= nil then data.ShootRecoil = 0 end
						if data.ShootCooldown ~= nil then data.ShootCooldown = 0.001 end
						if data.ShootBurstCooldown ~= nil then data.ShootBurstCooldown = 0.001 end
					end
					if data.AttackCooldown ~= nil then data.AttackCooldown = 0.001 end
					if data.SwingCooldown ~= nil then data.SwingCooldown = 0.001 end
					if data.MeleeCooldown ~= nil then data.MeleeCooldown = 0.001 end
					if data.Cooldown ~= nil then data.Cooldown = 0.001 end
					if data.RecoveryTime ~= nil then data.RecoveryTime = 0.001 end
					if data.ResetTime ~= nil then data.ResetTime = 0.001 end
				else
					local o = originalCooldowns[name]
					if o then data.ShootSpread=o.ShootSpread; data.ShootAccuracy=o.ShootAccuracy; data.ShootRecoil=o.ShootRecoil; data.ShootCooldown=o.ShootCooldown; data.ShootBurstCooldown=o.ShootBurstCooldown; data.AttackCooldown=o.AttackCooldown; data.SwingCooldown=o.SwingCooldown; data.MeleeCooldown=o.MeleeCooldown; data.Cooldown=o.Cooldown; data.RecoveryTime=o.RecoveryTime; data.ResetTime=o.ResetTime end
				end
			end
		end
	end
end)

makeToggle(combatSec.container, "Skin Changer (Rivals)", 50, function(v) setSkinChangerEnabled(v) end)

--==================== VALORANT REPLACEMENT PACKS ====================--
do
	local AssetService=game:GetService("AssetService")
	local disposed=false
	local sec=combatTab:newSection({name="Valorant Packs",is_changeable=true,scale=0.55})
	sec.frame.Position=UDim2.new(0.5,4,0,0)
	local status=utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,80),Size=UDim2.new(1,-24,0,130),TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.SourceSans,Text="Enable a pack to load its assets. Original assets return when disabled.",TextSize=12,TextColor3=Color3.fromRGB(200,200,200),Parent=sec.container})
	local packs={
		{name="Valorant Weapons",configFile="valorant.json",source="built-in",data=hs:JSONDecode([==[{
  "replacement_rules": [
    {
      "name": "Profile 4",
      "replace_ids": [
        12307734932
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/arm/valorant-leftV2.obj"
    },
    {
      "name": "Profile 5",
      "replace_ids": [
        12307583853
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/arm/valorant-rightV2.obj"
    },
    {
      "name": "Profile 6",
      "replace_ids": [
        144076357
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/arm/FP_Wushu_S0_DF.png"
    },
    {
      "name": "ar",
      "replace_ids": [
        12613283569,
        12613284249,
        14652718299,
        12613284768
      ],
      "mode": "id",
      "enabled": true
    },
    {
      "name": "ar",
      "replace_ids": [
        12613284036
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/Gaia-Vandal-Red/Gaia-Vandal-Red-mergedv2.obj"
    },
    {
      "name": "ar",
      "replace_ids": [
        12613284529
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/Gaia-Vandal-Red/Gaia-Vandal-Red-Mag-mergedv2.obj"
    },
    {
      "name": "ar",
      "replace_ids": [
        13087362838
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/sound/Gaias%20shoot.mp3"
    },
    {
      "name": "sinper",
      "replace_ids": [
        13188892651,
        14002915797,
        14774727092,
        13188893017,
        13188893115,
        14778413014,
        13270206222,
        13455394948,
        13188892855,
        13188893310
      ],
      "mode": "id",
      "enabled": true
    },
    {
      "name": "sinper",
      "replace_ids": [
        13188892761
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/chamber-sinper/main.obj"
    },
    {
      "name": "sinper",
      "replace_ids": [
        13270206087
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/sound/Preview_TourDeForce_Fire_FP_Full.wav"
    },
    {
      "name": "sinper",
      "replace_ids": [
        13188892532
      ],
      "mode": "id",
      "enabled": true
    },
    {
      "name": "sinper",
      "replace_ids": [
        13269934368
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 89426100452654
    },
    {
      "name": "sinper",
      "replace_ids": [
        13188893310,
        13455229188,
        13455229044,
        13455394948,
        13455395017
      ],
      "mode": "id",
      "enabled": true
    },
    {
      "name": "dagg",
      "replace_ids": [
        73385702554774
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/jett-dagger/main.obj"
    },
    {
      "name": "dagg",
      "replace_ids": [
        124614507878585
      ],
      "mode": "id",
      "enabled": true
    },
    {
      "name": "dagg",
      "replace_ids": [
        119886777451265
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 95318866540833
    },
    {
      "name": "dagg",
      "replace_ids": [
        129248911141724
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 92527815421098
    },
    {
      "name": "dagg",
      "replace_ids": [
        107117835992268
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 111373555305620
    },
    {
      "name": "dagg",
      "replace_ids": [
        76331161535117
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 138921174963297
    },
    {
      "name": "dagg",
      "replace_ids": [
        136507313237137
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 95472048087093
    },
    {
      "name": "dagg",
      "replace_ids": [
        91782309305074
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 77149665703840
    },
    {
      "name": "dagg",
      "replace_ids": [
        129248911141724
      ],
      "mode": "id",
      "enabled": true,
      "with_id": 92527815421098
    },
    {
      "name": "dagg",
      "replace_ids": [
        99837158417289
      ],
      "mode": "id",
      "enabled": true
    },
    {
      "name": "dagg",
      "replace_ids": [
        101759165907297
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/sound/Wushu_AbilX_Cast_Dagger_1P_01.wav"
    },
    {
      "name": "dagg",
      "replace_ids": [
        76357741438822
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/sound/Wushu_AbilX_Cast_Dagger_1P_03.wav"
    },
    {
      "name": "ar",
      "replace_ids": [
        17160682738
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/Gaia-Vandal-Red/ar.png"
    },
    {
      "name": "dagger",
      "replace_ids": [
        91885384580845
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/jett-dagger/daggers.png"
    },
    {
      "name": "sinper",
      "replace_ids": [
        17160799574
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/engnyg/123f1/refs/heads/main/valorant/chamber-sinper/sniper.png"
    }
  ]
}]==]),enabled=false,ready=false,loading=false,failed=0,saved={},watchers={},rules={}},
		{name="Valorant Rank Icons",configFile="ValorantRankIcons.json",source="built-in",data=hs:JSONDecode([==[{
  "replacement_rules": [
    {
      "name": "rank: bronze  1-> wood sword",
      "replace_ids": [
        106623367501544
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Bronze_1_Rank.png"
    },
    {
      "name": "rank: silver 1 -> stone sword",
      "replace_ids": [
        80716950169934
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Silver_1_Rank.png"
    },
    {
      "name": "rank: silver 2 -> stone sword",
      "replace_ids": [
        136100661820261
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Silver_2_Rank.png"
    },
    {
      "name": "rank: silver 3 -> stone sword",
      "replace_ids": [
        107898816876115
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Silver_3_Rank.png"
    },
    {
      "name": "rank: gold 1 -> iron sword",
      "replace_ids": [
        134520747948636
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Gold_1_Rank.png"
    },
    {
      "name": "rank: gold 2 -> iron sword",
      "replace_ids": [
        114166096331502
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Gold_2_Rank.png"
    },
    {
      "name": "rank: gold 3 -> iron sword",
      "replace_ids": [
        90039594400813
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Gold_3_Rank.png"
    },
    {
      "name": "rank: plat 1 -> platinum1",
      "replace_ids": [
        133903971285645
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Platinum_1_Rank.png"
    },
    {
      "name": "rank: plat 2 -> platinum2",
      "replace_ids": [
        82834564754747
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Platinum_2_Rank.png"
    },
    {
      "name": "rank: plat 3 -> platinum3",
      "replace_ids": [
        73345783863790
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Platinum_3_Rank.png"
    },
    {
      "name": "rank: diam 1 -> diamond",
      "replace_ids": [
        113997689031026
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Diamond_1_Rank.png"
    },
    {
      "name": "rank: diam 2 -> diamond2",
      "replace_ids": [
        88059506918419
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Diamond_2_Rank.png"
    },
    {
      "name": "rank: diam 3 -> diamond3",
      "replace_ids": [
        112183171942172
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Diamond_3_Rank.png"
    },
    {
      "name": "rank: o1 -> emerald",
      "replace_ids": [
        104871954739030
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Ascendant_1_Rank.png"
    },
    {
      "name": "rank: o2 -> ender eye",
      "replace_ids": [
        109012386782238
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Ascendant_2_Rank.png"
    },
    {
      "name": "rank: o3 -> nether star",
      "replace_ids": [
        127982903682334
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Ascendant_3_Rank.png"
    },
    {
      "name": "arch (top)",
      "replace_ids": [
        133793956251748
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Radiant_Rank.png"
    },
    {
      "name": "nem (top standard)",
      "replace_ids": [
        116941545385923
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Immortal_3_Rank.png"
    },
    {
      "name": "rank: bronze 2-> wood sword",
      "replace_ids": [
        131795064007344
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Bronze_2_Rank.png"
    },
    {
      "name": "rank: bronze 3-> wood sword",
      "replace_ids": [
        73543520622815
      ],
      "mode": "cdn",
      "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/xillyware/rritvri/main/files/ranks/Bronze_3_Rank.png"
    }
  ]
}]==]),enabled=false,ready=false,loading=false,failed=0,saved={},watchers={},rules={}}
	}
	local cache={}
	local function report()
		if disposed then return end
		local lines={}
		for _,pack in ipairs(packs) do
			local state=not pack.enabled and "off" or (pack.loading and "loading..." or (pack.ready and "ready" or "waiting"))
			table.insert(lines,pack.name..": "..state.." ["..pack.source.."]"..(pack.failed>0 and (" / failed: "..pack.failed) or ""))
		end
		table.insert(lines,"OBJ models require EditableMesh access. Failed assets keep the original.")
		status.Text=table.concat(lines,"\n\n")
	end
	local function numericId(value)
		local text=type(value)=="number" and string.format("%.0f",value) or tostring(value or "")
		return text:match("^rbxassetid://(%d+)$") or text:match("[?&]id=(%d+)") or text:match("^(%d+)$")
	end
	-- Parse OBJ geometry, including separate UV/normal indices and negative indices.
	local function importObj(body)
		local editable=AssetService:CreateEditableMesh()
		assert(editable,"EditableMesh unavailable or memory budget exhausted")
		local vertices,uvs,normals,faces={},{},{},{}
		local function indexOf(text,count)
			local n=tonumber(text)
			return n and (n<0 and count+n+1 or n)
		end
		local ok,result=pcall(function()
			local lineCount=0
			for line in body:gmatch("[^\r\n]+") do
				lineCount=lineCount+1
				if lineCount%3000==0 then task.wait(); assert(not disposed,"Disposed") end
				local kind,rest=line:match("^%s*(%S+)%s+(.+)")
				if kind=="v" or kind=="vt" or kind=="vn" then
					local values={}
					for value in rest:gmatch("%S+") do table.insert(values,tonumber(value)) end
					if kind=="v" then table.insert(vertices,editable:AddVertex(Vector3.new(values[1],values[2],values[3])))
					elseif kind=="vt" then table.insert(uvs,editable:AddUV(Vector2.new(values[1],1-values[2])))
					else table.insert(normals,editable:AddNormal(Vector3.new(values[1],values[2],values[3]))) end
				elseif kind=="f" then
					local corners={}
					for token in rest:gmatch("[^%s]+") do
						if token:sub(1,1)=="#" then break end
						local v,u,n=token:match("^([%-]?%d+)/([^/]*)/?(.*)$")
						if not v then v=token end
						table.insert(corners,{v=indexOf(v,#vertices),u=indexOf(u,#uvs),n=indexOf(n,#normals)})
					end
					for i=2,#corners-1 do
						local a,b,c=corners[1],corners[i],corners[i+1]
						local face=editable:AddTriangle(assert(vertices[a.v]),assert(vertices[b.v]),assert(vertices[c.v]))
						if uvs[a.u] and uvs[b.u] and uvs[c.u] then editable:SetFaceUVs(face,{uvs[a.u],uvs[b.u],uvs[c.u]}) end
						if normals[a.n] and normals[b.n] and normals[c.n] then editable:SetFaceNormals(face,{normals[a.n],normals[b.n],normals[c.n]}) end
						table.insert(faces,face)
					end
				end
			end
			assert(#faces>0,"OBJ contains no faces")
			return AssetService:CreateMeshPartAsync(Content.fromObject(editable),{CollisionFidelity=Enum.CollisionFidelity.Box})
		end)
		if not ok then editable:Destroy(); error(result) end
		return {kind="mesh",template=result,editable=editable}
	end
	local function loadResource(rule)
		if rule.mode=="id" then
			local id=numericId(rule.with_id)
			if id then return {kind="id",asset="rbxassetid://"..id} end
			return nil -- Missing replacement ID is not an instruction to delete a part.
		end
		local url=rule.cdn_url
		if rule.mode~="cdn" or type(url)~="string" or not url:match("^https://") then return nil end
		if cache[url]~=nil then return cache[url] or nil end
		local extension=url:match("%.([%w]+)$")
		assert(extension,"Unsupported asset URL")
		extension=extension:lower()
		local body=httpGet(url)
		assert(type(body)=="string" and #body>0,"Download failed")
		assert(not disposed,"Disposed")
		local resource
		if extension=="obj" then resource=importObj(body)
		else
			assert(type(writefile)=="function" and type(getcustomasset)=="function","writefile/getcustomasset unavailable")
			local hash=5381
			for i=1,#url do hash=(hash*33+url:byte(i))%2147483647 end
			local path=CONFIG_FOLDER.."/valorant_"..tostring(hash).."."..extension
			writefile(path,body)
			local asset=getcustomasset(path)
			assert(type(asset)=="string" and asset~="","Custom asset registration failed")
			resource={kind="asset",asset=asset}
		end
		if disposed then
			if resource.template then resource.template:Destroy() end
			if resource.editable then resource.editable:Destroy() end
			error("Disposed")
		end
		cache[url]=resource
		return resource
	end
	local function properties(obj)
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then return {"Image"}
		elseif obj:IsA("Sound") then return {"SoundId"}
		elseif obj:IsA("MeshPart") then return {"MeshId","TextureID"}
		elseif obj:IsA("SpecialMesh") then return {"MeshId","TextureId"}
		elseif obj:IsA("Decal") or obj:IsA("Texture") then return {"Texture"}
		end
	end
	local function restore(pack)
		for _,entry in pairs(pack.watchers) do
			for _,connection in ipairs(entry.connections) do connection:Disconnect() end
		end
		table.clear(pack.watchers)
		for obj,saved in pairs(pack.saved) do
			if saved.mesh then
				pcall(function() obj:ApplyMesh(saved.mesh); obj.Size=saved.size end)
				saved.mesh:Destroy()
			end
			for property,value in pairs(saved.props) do pcall(function() obj[property]=value end) end
		end
		table.clear(pack.saved)
	end
	local function applyObject(pack,obj,props)
		if disposed or not pack.enabled or not obj.Parent then return end
		for _,prop in ipairs(props) do
			local rule=pack.rules[numericId(obj[prop])]
			if rule and rule.resource then
				local resource=rule.resource
				local saved=pack.saved[obj] or {props={}}
				pack.saved[obj]=saved
				if prop=="MeshId" and obj:IsA("MeshPart") then
					if not saved.mesh then
						saved.mesh=obj:Clone()
						assert(saved.mesh,"Mesh backup failed")
						for _,child in ipairs(saved.mesh:GetChildren()) do child:Destroy() end
						saved.size=obj.Size
						saved.props.TextureID=obj.TextureID
					end
					local template=resource.template
					if not template and resource.kind=="id" then
						template=AssetService:CreateMeshPartAsync(Content.fromUri(resource.asset),{CollisionFidelity=Enum.CollisionFidelity.Box})
						resource.template=template
					end
					if template and pack.enabled and not disposed and obj.Parent then
						local texture,size=obj.TextureID,obj.Size
						obj:ApplyMesh(template); obj.Size=size; obj.TextureID=texture
					end
				else
					local asset=resource.asset or (resource.template and resource.template.MeshId)
					if asset then
						if saved.props[prop]==nil then saved.props[prop]=obj[prop] end
						obj[prop]=asset
					end
				end
			end
		end
	end
	local function watch(pack,obj)
		if disposed or not pack.enabled or not pack.ready then return end
		local props=properties(obj)
		if not props or pack.watchers[obj] then return end
		if pack==packs[2] and not (obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("Decal") or obj:IsA("Texture")) then return end
		local entry={connections={},busy=false,pending=false}
		pack.watchers[obj]=entry
		local function apply()
			if entry.busy or not pack.enabled or disposed or pack.watchers[obj]~=entry then return end
			entry.busy=true
			local ok,err=pcall(applyObject,pack,obj,props)
			entry.busy=false
			if not ok and not entry.warned then
				entry.warned=true
				warn("[Valorant Pack] "..tostring(err))
			end
		end
		for _,prop in ipairs(props) do
			table.insert(entry.connections,obj:GetPropertyChangedSignal(prop):Connect(function()
				if entry.busy or entry.pending then return end
				entry.pending=true
				task.defer(function() entry.pending=false; apply() end)
			end))
		end
		table.insert(entry.connections,obj.Destroying:Connect(function()
			for _,connection in ipairs(entry.connections) do connection:Disconnect() end
			pack.watchers[obj]=nil
			local saved=pack.saved[obj]
			if saved and saved.mesh then saved.mesh:Destroy() end
			pack.saved[obj]=nil
		end))
		apply()
	end
	local function scan(pack)
		local roots=pack==packs[2] and {player:FindFirstChild("PlayerGui")} or {workspace,game:GetService("ReplicatedStorage"),game:GetService("SoundService"),player:FindFirstChild("PlayerGui")}
		for _,root in ipairs(roots) do
			for i,obj in ipairs(root:GetDescendants()) do
				if disposed or not pack.enabled then return end
				watch(pack,obj)
				if i%500==0 then task.wait() end
			end
		end
	end
	local function validConfig(data)
		if type(data)~="table" or type(data.replacement_rules)~="table" then return false end
		local rules=data.replacement_rules
		if #rules>2048 then return false end
		for key in pairs(rules) do
			if type(key)~="number" or key%1~=0 or key<1 or key>#rules then return false end
		end
		for _,rule in ipairs(rules) do
			if type(rule)~="table" or type(rule.replace_ids)~="table" or #rule.replace_ids==0 then return false end
			if rule.enabled~=nil and type(rule.enabled)~="boolean" then return false end
			for key,id in pairs(rule.replace_ids) do
				if type(key)~="number" or key%1~=0 or key<1 or key>#rule.replace_ids or not numericId(id) then return false end
			end
			if rule.mode=="cdn" then
				if type(rule.cdn_url)~="string" or not rule.cdn_url:match("^https://") then return false end
			elseif rule.mode=="id" then
				if rule.with_id~=nil and not numericId(rule.with_id) then return false end
			else return false end
		end
		return true
	end
	local function fetchConfig(pack)
		local ok,data=pcall(function()
			local body=httpGet(REMOTE_CONFIG_BASE..pack.configFile)
			assert(type(body)=="string" and #body<=2*1024*1024,"Invalid JSON response")
			local decoded=hs:JSONDecode(body)
			assert(validConfig(decoded),"Invalid replacement_rules")
			return decoded
		end)
		if disposed then return end
		if ok then
			pack.data=data
			pack.source="GitHub"
		else
			pack.source="built-in"
			warn("[Valorant Pack] "..pack.configFile..": using built-in settings ("..tostring(data)..")")
		end
	end

	local function prepare(pack)
		if pack.ready then task.spawn(scan,pack); return end
		if pack.loading then return end
		pack.loading=true; report()
		task.spawn(function()
			fetchConfig(pack)
			if disposed then return end
			report()
			for _,rule in ipairs(pack.data.replacement_rules or {}) do
				if disposed then return end
				if rule.enabled~=false then
					local ok,resource=pcall(loadResource,rule)
					if ok and resource then
						rule.resource=resource
						for _,id in ipairs(rule.replace_ids or {}) do pack.rules[numericId(id)]=rule end
					elseif not ok then
						pack.failed=pack.failed+1
						warn("[Valorant Pack] "..tostring(rule.name)..": "..tostring(resource))
					end
				end
			end
			pack.loading=false; pack.ready=true
			if not disposed then report(); if pack.enabled then scan(pack) end end
		end)
	end
	for index,pack in ipairs(packs) do
		makeToggle(sec.container,pack.name,22+(index-1)*28,function(value)
			pack.enabled=value
			if value then prepare(pack) else restore(pack) end
			report()
		end)
	end
	local added=game.DescendantAdded:Connect(function(obj)
		if disposed or not (packs[1].enabled or packs[2].enabled) then return end
		if not properties(obj) then return end
		for _,pack in ipairs(packs) do if pack.enabled and pack.ready then watch(pack,obj) end end
	end)
	_screenGui.Destroying:Connect(function()
		disposed=true; added:Disconnect()
		for _,pack in ipairs(packs) do pack.enabled=false; restore(pack) end
		for _,pack in ipairs(packs) do
			for _,rule in ipairs(pack.data.replacement_rules or {}) do
				local resource=rule.resource
				if resource and resource.kind=="id" and resource.template then resource.template:Destroy() end
			end
		end
		for _,resource in pairs(cache) do
			if resource then
				if resource.template then resource.template:Destroy() end
				if resource.editable then resource.editable:Destroy() end
			end
		end
	end)
end


--==================== TAB 2: VISUALS ====================--
local visTab = window:getTab(2)
local hatSec = visTab:newSection({name="Accessories", is_changeable=true, scale=0.45})
local crossSec = visTab:newSection({name="Crosshair", is_changeable=true, scale=0.25})
crossSec.frame.Position = UDim2.new(0.5,0,0,0)

makeToggle(hatSec.container, "China Hat", 22, function(v)
	local char = player.Character; if not char then return end
	if v then
		local head = char:FindFirstChild("Head")
		if head and not char:FindFirstChild("ChinaHatCone") then
			local cone = Instance.new("Part"); cone.Name = "ChinaHatCone"; cone.Size = Vector3.new(1,1,1); cone.Color = Color3.fromRGB(255,105,180); cone.Material = Enum.Material.Neon; cone.Transparency = 0.2; cone.Anchored = false; cone.CanCollide = false
			local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.FileMesh; mesh.MeshId = "rbxassetid://1033714"; mesh.Scale = Vector3.new(1.7,1.1,1.7); mesh.Parent = cone
			local weld = Instance.new("Weld"); weld.Part0 = head; weld.Part1 = cone; weld.C0 = CFrame.new(0,0.9,0); weld.Parent = cone
			local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255,105,180); light.Brightness = 0; light.Range = 12; light.Shadows = true; light.Parent = cone
			cone.Parent = char
		end
	else
		local hat = char:FindFirstChild("ChinaHatCone"); if hat then hat:Destroy() end
	end
end)

transformToggles.Amany = makeToggle(hatSec.container, "Amany Transform", 50, function(v) setTransform("Amany", v) end)
transformToggles.Riz = makeToggle(hatSec.container, "Riz Transform", 78, function(v) setTransform("Riz", v) end)
transformToggles.Yokai = makeToggle(hatSec.container, "Yokai Transform", 106, function(v) setTransform("Yokai", v) end)

--==================== VISUALS: AURA SECTION ====================--
local auraSec = visTab:newSection({name="Aura", is_changeable=true, scale=0.49})
auraSec.frame.Position = UDim2.new(0,0,0.49,0)
-- Angel Aura: anchored, non-colliding effect carriers outside the character rig.
do
	local enabled, disposed = false, false
	local generation = 0
	local created = {}
	local auraColor = Color3.fromRGB(133, 220, 255)
	local characterConnection
	local toggle

	local rainbow = false
	local colors={
		{name="Ice",color=Color3.fromRGB(133,220,255)},
		{name="Purple",color=Color3.fromRGB(180,110,255)}
	}
	local colorIndex=1
	local firstPersonHidden=false
	local visibilityObjects={}
	local function isFirstPerson()
		local currentCamera=workspace.CurrentCamera
		local character=player.Character
		if not currentCamera or not character then return true end
		if player.CameraMode==Enum.CameraMode.LockFirstPerson then return true end
		local cameraPosition=currentCamera.CFrame.Position
		local head=character:FindFirstChild("Head")
		local root=character:FindFirstChild("HumanoidRootPart")
		local humanoid=character:FindFirstChildOfClass("Humanoid")
		local focusDistance=(cameraPosition-currentCamera.Focus.Position).Magnitude
		if focusDistance < (firstPersonHidden and 1.8 or 1.2) then return true end
		if head and head:IsA("BasePart") then
			local headDistance=(cameraPosition-head.Position).Magnitude
			if headDistance < (firstPersonHidden and 2.4 or 1.9) then return true end
			if headDistance<3.5 and head.LocalTransparencyModifier>=0.95 then return true end
		end
		-- FPS games may offset the camera away from the avatar's transformed head.
		if root and root:IsA("BasePart") then
			local offset=humanoid and humanoid.CameraOffset or Vector3.zero
			local eyePosition=root.CFrame:PointToWorldSpace(Vector3.new(0,1.5,0)+offset)
			if (cameraPosition-eyePosition).Magnitude < (firstPersonHidden and 2.4 or 1.9) then return true end
		end
		return false
	end
	local function trackVisibility(object)
		if object:IsA("BasePart") then
			table.insert(visibilityObjects,{object=object,kind="part",original=object.LocalTransparencyModifier})
		elseif object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail") or object:IsA("Light") then
			table.insert(visibilityObjects,{object=object,kind="effect",original=object.Enabled})
		end
	end

	local function configure(effect)
		local now=os.clock()
		local color=rainbow and Color3.fromHSV((now*0.15)%1,0.8,1) or auraColor
		if effect:IsA("ParticleEmitter") or effect:IsA("Beam") or effect:IsA("Trail") then
			effect.Color=ColorSequence.new(color)
			effect.Enabled=not firstPersonHidden
		elseif effect:IsA("Light") then
			effect.Color=color
		end
	end
	local function updateEffects()
		if firstPersonHidden then return end
		for _,entry in ipairs(visibilityObjects) do
			if entry.kind=="effect" and entry.object.Parent then configure(entry.object) end
		end
	end
	local lastVisibilityCheck=-math.huge
	local function updateVisibility(force)
		local hidden=isFirstPerson()
		local now=os.clock()
		local changed=hidden~=firstPersonHidden
		if not force and not changed and now-lastVisibilityCheck<0.25 then return end
		lastVisibilityCheck=now
		firstPersonHidden=hidden
		-- Detect camera changes every frame; rewrite effects on transitions and periodic verification.
		for _,entry in ipairs(visibilityObjects) do
			local object=entry.object
			if object.Parent then
				if entry.kind=="part" then
					local desired=hidden and 1 or entry.original
					if object.LocalTransparencyModifier~=desired then object.LocalTransparencyModifier=desired end
				else
					local desired=not hidden and entry.original
					if object.Enabled~=desired then object.Enabled=desired end
					if hidden and (changed or force) and (object:IsA("ParticleEmitter") or object:IsA("Trail")) then object:Clear() end
				end
			end
		end
		for _,holder in ipairs(created) do
			if hidden then
				if holder.Parent then holder.Parent=nil end
			elseif holder.Parent~=workspace then holder.Parent=workspace end
		end
	end

	local carriers={}
	local groundParams=RaycastParams.new()
	groundParams.FilterType=Enum.RaycastFilterType.Exclude
	local groundHit,groundTime=nil,-math.huge
	local function updateCarriers()
		if firstPersonHidden then return end
		local now=os.clock()
		local groundChecked=false
		for _,entry in ipairs(carriers) do
			if entry.part.Parent and entry.root.Parent then
				local frame
				if entry.target and entry.target.Parent then frame=entry.target.CFrame
				else
					frame=entry.root.CFrame*entry.offset
					if entry.ground then
						if not groundChecked and now-groundTime>=0.1 then
							local exclude={entry.character}
							for _,object in ipairs(created) do table.insert(exclude,object) end
							groundParams.FilterDescendantsInstances=exclude
							groundHit=workspace:Raycast(entry.root.Position,Vector3.new(0,-30,0),groundParams)
							groundTime=now
						end
						groundChecked=true
						if groundHit then frame=CFrame.new(frame.Position.X,groundHit.Position.Y+0.05,frame.Position.Z)*frame.Rotation end
					end
				end
				entry.part.CFrame=frame
			end
		end
	end

	local function clear()
		table.clear(carriers)
		groundHit=nil; groundTime=-math.huge
		table.clear(visibilityObjects)
		for _, object in ipairs(created) do object:Destroy() end
		table.clear(created)
	end

	local function refresh(character)
		generation = generation + 1
		local currentGeneration = generation
		clear()
		if disposed or not enabled or not character then return end
		task.spawn(function()
			local root = character:WaitForChild("HumanoidRootPart", 10)
			if not root or disposed or not enabled or currentGeneration ~= generation then return end
			local ok, result = pcall(function()
				return game:GetObjects("rbxassetid://97658130917593")[1]
			end)
			if not ok or not result then
				if not disposed and currentGeneration == generation then
					warn("[AmanyHub] Angel Aura could not load: " .. tostring(result))
					toggle:setState(false)
				end
				return
			end
			if disposed or not enabled or currentGeneration ~= generation or player.Character ~= character then
				result:Destroy()
				return
			end
			-- Keep effect carrier parts: ground mist may live on a separate floor part.
			-- Carriers stay outside the character and never participate in character physics.
			local sourceRoot=result:FindFirstChild("HumanoidRootPart",true)
				or result:FindFirstChild("Torso",true) or result:FindFirstChild("UpperTorso",true)
				or result:FindFirstChildWhichIsA("BasePart",true)
			local sourceFrame=sourceRoot and sourceRoot:IsA("BasePart") and sourceRoot.CFrame or CFrame.new()
			local descendants=result:GetDescendants()
			if result:IsA("BasePart") then table.insert(descendants,1,result) end
			for _,object in ipairs(descendants) do
				if object:IsA("BasePart") then
					local target=character:FindFirstChild(object.Name)
					if target and not target:IsA("BasePart") then target=nil end
					local offset=sourceFrame:ToObjectSpace(object.CFrame)
					local name=object.Name:lower()
					local ground=not target and (name:find("ground",1,true) or name:find("floor",1,true)
						or name:find("mist",1,true) or name:find("fog",1,true) or offset.Position.Y < -1.5)
					object.Anchored=true
					object.CanCollide=false
					object.CanTouch=false
					object.CanQuery=false
					object.Massless=true
					if target then object.Transparency=1 end
					table.insert(carriers,{part=object,target=target,root=root,character=character,offset=offset,ground=ground})
				elseif object:IsA("Attachment") then
					object.Name="AmanyAngelAuraAttachment"
				elseif object:IsA("LuaSourceContainer") or object:IsA("JointInstance")
					or object:IsA("Constraint") or object:IsA("Humanoid") or object:IsA("Animator") then
					object:Destroy()
				end
			end
			local holder=Instance.new("Folder")
			holder.Name="AmanyAngelAuraEffects"
			firstPersonHidden=isFirstPerson()
			if firstPersonHidden then holder.Parent=nil else holder.Parent=workspace end
			table.insert(created,holder)
			result.Parent=holder
			updateCarriers()
			trackVisibility(result)
			for _,effect in ipairs(result:GetDescendants()) do trackVisibility(effect) end
			configure(result)
			for _,effect in ipairs(result:GetDescendants()) do configure(effect) end
			updateVisibility(true)

		end)
	end

	toggle = makeToggle(auraSec.container, "Angel Aura", 22, function(value)
		enabled = value
		refresh(player.Character)
	end)
	local function auraButton(text,y,callback)
		local button=utility.newObject("TextButton",{
			BackgroundColor3=Color3.fromRGB(30,30,30),BorderColor3=Color3.fromRGB(80,80,80),
			Position=UDim2.new(0,12,0,y),Size=UDim2.new(1,-24,0,22),
			Text=text,Font=Enum.Font.SourceSans,TextSize=13,
			TextColor3=Color3.fromRGB(220,220,220),Parent=auraSec.container
		})
		button.MouseButton1Click:Connect(function() callback(button) end)
	end
	auraButton("Color: Ice  >",46,function(button)
		colorIndex=colorIndex % #colors+1
		auraColor=colors[colorIndex].color
		button.Text="Color: "..colors[colorIndex].name.."  >"
		updateEffects()
	end)
	makeToggle(auraSec.container,"Rainbow Aura",74,function(value) rainbow=value; updateEffects() end)
	local elapsed=0
	local animationConnection=RunService.Heartbeat:Connect(function(dt)
		if disposed or not enabled or firstPersonHidden then return end
		updateCarriers()
		if not rainbow then return end
		elapsed=elapsed+dt
		if elapsed<0.05 then return end
		elapsed=0
		updateEffects()
	end)

	local visibilityBinding="YokaiAngelAuraVisibility_"..hs:GenerateGUID(false)
	RunService:BindToRenderStep(visibilityBinding,Enum.RenderPriority.Last.Value+10,function()
		if not disposed and enabled then updateVisibility() end
	end)
	characterConnection = player.CharacterAdded:Connect(function(character)
		refresh(character)
	end)
	_screenGui.Destroying:Connect(function()
		disposed = true
		enabled = false
		generation = generation + 1
		characterConnection:Disconnect()
		animationConnection:Disconnect()
		RunService:UnbindFromRenderStep(visibilityBinding)
		clear()
	end)
end


-- Movement effects are independent of Angel Aura and use no external assets.
do
	local TweenService=game:GetService("TweenService")
	local jumpOn,landOn,disposed=false,false,false
	local stateConnection
	local generation=0
	local active={}
	local effectColor=Color3.fromRGB(133,220,255)
	local colorIndex=1
	local palette={Color3.fromRGB(133,220,255),Color3.fromRGB(180,110,255)}
	local function clearMovement()
		for _,ring in ipairs(active) do ring.folder:Destroy() end
		table.clear(active)
	end
	local function emitRing(character,landing)
		if disposed or #active>=6 then return end
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={character}
		local hit=workspace:Raycast(root.Position,Vector3.new(0,-12,0),params)
		local position=hit and hit.Position+hit.Normal*0.06 or root.Position-Vector3.new(0,3,0)
		local normal=hit and hit.Normal or Vector3.new(0,1,0)
		local tangent=normal:Cross(Vector3.new(0,0,1))
		if tangent.Magnitude<0.01 then tangent=normal:Cross(Vector3.new(1,0,0)) end
		tangent=tangent.Unit
		local frame=CFrame.fromMatrix(position,tangent,normal,tangent:Cross(normal))
		local folder=Instance.new("Folder")
		folder.Name=landing and "YokaiLandingRipple" or "YokaiJumpRing"
		local ring={folder=folder,parts={},frame=frame,age=0,duration=landing and 0.75 or 0.6,maxRadius=landing and 5 or 3.5}
		for i=1,28 do
			local part=Instance.new("Part")
			part.Name="RingSegment"
			part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
			part.Material=Enum.Material.Neon; part.Color=effectColor
			part.Size=Vector3.new(0.1,0.04,0.1)
			part.CFrame=frame
			part.Transparency=1
			part.Parent=folder
			table.insert(ring.parts,part)
		end
		folder.Parent=workspace
		table.insert(active,ring)
	end
	local function bindCharacter(character)
		generation=generation+1
		local token=generation
		if stateConnection then stateConnection:Disconnect(); stateConnection=nil end
		clearMovement()
		task.spawn(function()
			local humanoid=character:WaitForChild("Humanoid",10)
			if not humanoid or disposed or token~=generation or player.Character~=character then return end
			stateConnection=humanoid.StateChanged:Connect(function(_,newState)
				if disposed then return end
				if newState==Enum.HumanoidStateType.Jumping and jumpOn then emitRing(character,false)
				elseif newState==Enum.HumanoidStateType.Landed and landOn then emitRing(character,true) end
			end)
		end)
	end
	makeToggle(auraSec.container,"Jump Ring",106,function(value) jumpOn=value; if not jumpOn and not landOn then clearMovement() end end)
	makeToggle(auraSec.container,"Landing Ripple",134,function(value) landOn=value; if not jumpOn and not landOn then clearMovement() end end)
	local colorButton=utility.newObject("TextButton",{
		BackgroundColor3=Color3.fromRGB(30,30,30),BorderColor3=Color3.fromRGB(80,80,80),
		Position=UDim2.new(0,12,0,162),Size=UDim2.new(1,-24,0,22),
		Text="Jump / Land Color: Ice  >",Font=Enum.Font.SourceSans,TextSize=13,
		TextColor3=Color3.fromRGB(220,220,220),Parent=auraSec.container
	})
	colorButton.MouseButton1Click:Connect(function()
		colorIndex=colorIndex % #palette+1; effectColor=palette[colorIndex]
		colorButton.Text="Jump / Land Color: "..(colorIndex==1 and "Ice" or "Purple").."  >"
	end)
	local updateConnection=RunService.Heartbeat:Connect(function(dt)
		for i=#active,1,-1 do
			local ring=active[i]
			ring.age=ring.age+dt
			local t=math.min(1,ring.age/ring.duration)
			if t>=1 then ring.folder:Destroy(); table.remove(active,i)
			else
				local radius=0.6+(ring.maxRadius-0.6)*TweenService:GetValue(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
				for index,part in ipairs(ring.parts) do
					local angle=(index-1)*math.pi*2/#ring.parts
					part.Size=Vector3.new(0.12*(1-t)+0.02,0.04,2*math.pi*radius/#ring.parts*1.05)
					part.CFrame=ring.frame*CFrame.new(math.cos(angle)*radius,0,math.sin(angle)*radius)*CFrame.Angles(0,-angle,0)
					part.Transparency=0.15+0.85*t
				end
			end
		end
	end)
	local respawnConnection=player.CharacterAdded:Connect(bindCharacter)
	if player.Character then bindCharacter(player.Character) end
	_screenGui.Destroying:Connect(function()
		disposed=true; generation=generation+1
		if stateConnection then stateConnection:Disconnect() end
		respawnConnection:Disconnect(); updateConnection:Disconnect()
		clearMovement()
	end)
end

local crosshairConn = nil; local crosshairKeyConn = nil
makeToggle(crossSec.container, "Dynamic Crosshair", 22, function(v)
	if v then
		local TargetGui = game:GetService("CoreGui")
		if TargetGui:FindFirstChild("SleepyStaticCenterCrosshair") then TargetGui.SleepyStaticCenterCrosshair:Destroy() end
		local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SleepyStaticCenterCrosshair"; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true; ScreenGui.DisplayOrder = 9999; ScreenGui.Parent = TargetGui
		local CenterContainer = Instance.new("Frame"); CenterContainer.Name = "Centro"; CenterContainer.Size = UDim2.new(0,0,0,0); CenterContainer.Position = UDim2.new(0.5,0,0.5,0); CenterContainer.BackgroundTransparency = 1; CenterContainer.Parent = ScreenGui
		local TextContainer = Instance.new("Frame"); TextContainer.Name = "TextoContenedor"; TextContainer.Size = UDim2.new(0,0,0,0); TextContainer.Position = UDim2.new(0.5,0,0.5,0); TextContainer.BackgroundTransparency = 1; TextContainer.Parent = ScreenGui
		local TextLabel = Instance.new("TextLabel"); TextLabel.Name = "YokaiText"; TextLabel.Size = UDim2.new(0,300,0,20); TextLabel.Position = UDim2.new(0,-150,0,22); TextLabel.BackgroundTransparency = 1; TextLabel.RichText = true; TextLabel.Text = '<font letter-spacing="6">Yokai.win</font>'; TextLabel.Font = Enum.Font.Arial; TextLabel.TextSize = 14; TextLabel.TextStrokeTransparency = 0; TextLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0); TextLabel.Parent = TextContainer
		local BaseLength=17; local Thickness=1; local CenterGap=8; local RotationSpeed=150; local RGBSpeed=0.05; local SizeRange=5; local PulseSpeed=3.5; local MinSpeedMultiplier=0.35; local MaxSpeedMultiplier=1.75
		local Lines={}; local Outlines={}
		for i=1,4 do
			local O=Instance.new("Frame"); O.Name="Borde"..i; O.BorderSizePixel=0; O.BackgroundColor3=Color3.fromRGB(0,0,0); O.BackgroundTransparency=0.5; O.AnchorPoint=Vector2.new(0.5,0.5); O.Parent=CenterContainer; Outlines[i]=O
			local L=Instance.new("Frame"); L.Name="Linea"..i; L.BorderSizePixel=0; L.AnchorPoint=Vector2.new(0.5,0.5); L.Parent=CenterContainer; Lines[i]=L
		end
		local TickCounter=0; local ModoMenu=false
		crosshairKeyConn = uis.InputBegan:Connect(function(input, gp) if gp then return end; if input.KeyCode==Enum.KeyCode.M or input.KeyCode==Enum.KeyCode.ButtonSelect then ModoMenu=not ModoMenu end end)
		crosshairConn = RunService.RenderStepped:Connect(function(dt)
			if not CenterContainer or not CenterContainer.Parent then crosshairConn:Disconnect(); return end
			TickCounter += dt
			local CP; if not ModoMenu then CP=UDim2.new(0.5,0,0.5,0) else local CL=uis:GetMouseLocation(); CP=UDim2.new(0,CL.X,0,CL.Y) end
			CenterContainer.Position=CP; TextContainer.Position=CP
			local PF=math.sin(TickCounter*PulseSpeed); local SP=(PF+1)/2; local SL=MinSpeedMultiplier+(SP*(MaxSpeedMultiplier-MinSpeedMultiplier))
			CenterContainer.Rotation=(CenterContainer.Rotation+(RotationSpeed*SL*dt))%360
			local Hue=(TickCounter*RGBSpeed)%1; local CC=Color3.fromHSV(Hue,1,1); TextLabel.TextColor3=CC
			local DL=BaseLength+(PF*SizeRange); local BS=1
			Lines[1].Size=UDim2.new(0,Thickness,0,DL); Lines[1].Position=UDim2.new(0,0,0,-CenterGap-(DL/2)); Lines[1].BackgroundColor3=CC; Outlines[1].Size=UDim2.new(0,Thickness+(BS*2),0,DL+(BS*2)); Outlines[1].Position=Lines[1].Position
			Lines[2].Size=UDim2.new(0,Thickness,0,DL); Lines[2].Position=UDim2.new(0,0,0,CenterGap+(DL/2)); Lines[2].BackgroundColor3=CC; Outlines[2].Size=UDim2.new(0,Thickness+(BS*2),0,DL+(BS*2)); Outlines[2].Position=Lines[2].Position
			Lines[3].Size=UDim2.new(0,DL,0,Thickness); Lines[3].Position=UDim2.new(0,-CenterGap-(DL/2),0,0); Lines[3].BackgroundColor3=CC; Outlines[3].Size=UDim2.new(0,DL+(BS*2),0,Thickness+(BS*2)); Outlines[3].Position=Lines[3].Position
			Lines[4].Size=UDim2.new(0,DL,0,Thickness); Lines[4].Position=UDim2.new(0,CenterGap+(DL/2),0,0); Lines[4].BackgroundColor3=CC; Outlines[4].Size=UDim2.new(0,DL+(BS*2),0,Thickness+(BS*2)); Outlines[4].Position=Lines[4].Position
		end)
	else
		if crosshairConn then crosshairConn:Disconnect(); crosshairConn=nil end
		if crosshairKeyConn then crosshairKeyConn:Disconnect(); crosshairKeyConn=nil end
		local ch=game:GetService("CoreGui"):FindFirstChild("SleepyStaticCenterCrosshair"); if ch then ch:Destroy() end
	end
end)

--==================== TAB 3: ESP ====================--
local espTab = window:getTab(3)
local espSec = espTab:newSection({name="ESP", is_changeable=true, scale=0.55})
local espEnabled=false; local tracersEnabled=false; local neonEnabled=false; local espColor=Color3.fromRGB(170,100,255); local espObjects={}; local tracerLines={}

local function createESP(plr)
	if plr==player or espObjects[plr] then return end
	local bb=Instance.new("BillboardGui"); bb.Name="YokaiESP"; bb.AlwaysOnTop=true; bb.Size=UDim2.new(4.2,0,6.2,0); bb.StudsOffset=Vector3.new(0,0.3,0)
	local outline=Instance.new("Frame"); outline.BackgroundTransparency=1; outline.Size=UDim2.new(1,0,1,0); outline.Parent=bb
	local stroke=Instance.new("UIStroke"); stroke.Color=espColor; stroke.Thickness=1.7; stroke.Parent=outline
	local fill=Instance.new("Frame"); fill.BackgroundColor3=espColor; fill.BackgroundTransparency=0.68; fill.BorderSizePixel=0; fill.Size=UDim2.new(1,0,1,0); fill.Parent=outline
	local name=Instance.new("TextLabel"); name.BackgroundTransparency=1; name.Size=UDim2.new(1,0,0,16); name.Position=UDim2.new(0,0,0,-20); name.Font=Enum.Font.GothamMedium; name.TextSize=12; name.TextColor3=espColor; name.TextStrokeTransparency=0.45; name.Text=plr.Name; name.Parent=bb
	espObjects[plr]={bb=bb,stroke=stroke,fill=fill,name=name}
	local function attach() if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then bb.Adornee=plr.Character.HumanoidRootPart; bb.Parent=plr.Character.HumanoidRootPart end end
	if plr.Character then attach() end
	plr.CharacterAdded:Connect(function() task.wait(0.5) attach() end)
end

local function removeESP(plr)
	if espObjects[plr] then if espObjects[plr].bb then espObjects[plr].bb:Destroy() end; espObjects[plr]=nil end
	if tracerLines[plr] then tracerLines[plr]:Remove(); tracerLines[plr]=nil end
end

makeToggle(espSec.container, "ESP Boxes", 22, function(v) espEnabled=v; if v then for _,p in ipairs(Players:GetPlayers()) do if p~=player then createESP(p) end end else for p,_ in pairs(espObjects) do removeESP(p) end end end)
makeToggle(espSec.container, "Tracers", 48, function(v) tracersEnabled=v; if v then for _,p in ipairs(Players:GetPlayers()) do if p~=player and not tracerLines[p] then local line=Drawing.new("Line"); line.Thickness=1.5; line.Transparency=0.25; tracerLines[p]=line end end else for _,line in pairs(tracerLines) do line.Visible=false end end end)
makeToggle(espSec.container, "Neon Mode", 74, function(v) neonEnabled=v; for _,o in pairs(espObjects) do if o.stroke then o.stroke.Thickness=v and 2.6 or 1.7 end; if o.fill then o.fill.BackgroundTransparency=v and 0.52 or 0.68 end end end)

local colors={{n="Purple",c=Color3.fromRGB(170,100,255)},{n="Blue",c=Color3.fromRGB(80,160,255)},{n="Green",c=Color3.fromRGB(80,255,160)},{n="Pink",c=Color3.fromRGB(255,100,180)},{n="Cyan",c=Color3.fromRGB(80,255,255)},{n="White",c=Color3.fromRGB(240,240,255)}}
for i,d in ipairs(colors) do
	local b=utility.newObject("TextButton",{BackgroundColor3=d.c,BorderSizePixel=0,Position=UDim2.new(0,12+((i-1)%3)*70,0,110+math.floor((i-1)/3)*28),Size=UDim2.new(0,64,0,22),Font=Enum.Font.SourceSans,Text=d.n,TextColor3=Color3.fromRGB(15,15,15),TextSize=12,Parent=espSec.container})
	b.MouseButton1Click:Connect(function() espColor=d.c; for _,o in pairs(espObjects) do if o.stroke then o.stroke.Color=espColor end; if o.fill then o.fill.BackgroundColor3=espColor end; if o.name then o.name.TextColor3=espColor end end end)
end

RunService.RenderStepped:Connect(function() for plr,line in pairs(tracerLines) do if tracersEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then local pos,onScreen=camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position); if onScreen then line.From=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y); line.To=Vector2.new(pos.X,pos.Y); line.Color=espColor; line.Visible=true else line.Visible=false end else line.Visible=false end end end)
Players.PlayerAdded:Connect(function(p) if espEnabled then task.wait(1) createESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

--==================== TAB 4: WORLD ====================--
local worldTab = window:getTab(4)
local skySec = worldTab:newSection({name="Sky / Custom Sky", is_changeable=true, scale=0.30}); skySec.frame.Position=UDim2.new(0,0,0,0)
local originalLighting={}
makeToggle(skySec.container, "Night Mode", 22, function(v) local L=game:GetService("Lighting"); if v then originalLighting={ClockTime=L.ClockTime,Brightness=L.Brightness,Ambient=L.Ambient,OutdoorAmbient=L.OutdoorAmbient}; L.ClockTime=0; L.Brightness=1.15; L.Ambient=Color3.fromRGB(70,110,200); L.OutdoorAmbient=Color3.fromRGB(25,40,80); L.FogColor=Color3.fromRGB(15,25,55); L.FogStart=40; L.FogEnd=1400; local atm=L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",L); atm.Density=0.22; atm.Offset=0.18; atm.Color=Color3.fromRGB(80,130,220); atm.Decay=Color3.fromRGB(20,30,70); atm.Glare=0.12; atm.Haze=1.7; local sky=L:FindFirstChildOfClass("Sky") or Instance.new("Sky",L); sky.StarCount=5000; sky.CelestialBodiesShown=true else if originalLighting.ClockTime then L.ClockTime=originalLighting.ClockTime; L.Brightness=originalLighting.Brightness; L.Ambient=originalLighting.Ambient; L.OutdoorAmbient=originalLighting.OutdoorAmbient end end end)

-- Custom Sky presets
do
	local lighting = game:GetService("Lighting")
	local presets = {
		{ name = "Yokai", id = "93932626981302" },
		{ name = "DarkPurple Sky", id = "106884396681004" },
		{ name = "Normal Sky", id = "108082540504502" },
	}
	local toggles = {}
	local savedSkies = {}
	local currentSky
	local selected
	local generation = 0
	local disposed = false

	local skyProperties={"Name","SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp",
		"CelestialBodiesShown","StarCount","SunTextureId","MoonTextureId","SunAngularSize","MoonAngularSize","SkyboxOrientation"}
	local function snapshotSky(sky)
		local properties={}
		for _,property in ipairs(skyProperties) do
			local ok,value=pcall(function() return sky[property] end)
			if ok then properties[property]=value end
		end
		return {object=sky,properties=properties}
	end
	local function restore()
		if currentSky then pcall(function() currentSky:Destroy() end); currentSky=nil end
		for _,saved in ipairs(savedSkies) do
			local ok=pcall(function() saved.object.Parent=lighting end)
			if not ok then
				-- Destroy() permanently locks Parent. Rebuild only Sky properties;
				-- never copy controller scripts from the old instance.
				local replacement=Instance.new("Sky")
				for property,value in pairs(saved.properties) do
					pcall(function() replacement[property]=value end)
				end
				replacement.Parent=lighting
			end
		end
		table.clear(savedSkies)
	end

	local function apply(preset)
		generation = generation + 1
		local requestGeneration = generation
		task.spawn(function()
			local loaded
			local sky
			local texture = "rbxassetid://" .. preset.id
			local ok, objects = pcall(function() return game:GetObjects(texture) end)
			if ok and type(objects) == "table" then
				loaded = objects
				for _, object in ipairs(objects) do
					local source = object:IsA("Sky") and object or object:FindFirstChildWhichIsA("Sky", true)
					if source then sky = source:Clone(); break end
					local image = (object:IsA("Decal") or object:IsA("Texture")) and object
						or object:FindFirstChildWhichIsA("Decal", true)
					if image and image.Texture ~= "" then texture = image.Texture end
				end
			end
			-- Image assets use the supplied texture on all six faces.
			if not sky then
				sky = Instance.new("Sky")
				for _, face in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}) do
					sky[face] = texture
				end
				sky.CelestialBodiesShown = false
				sky.StarCount = 0
			end
			if loaded then for _, object in ipairs(loaded) do object:Destroy() end end
			if disposed or generation ~= requestGeneration or selected ~= preset.name then
				sky:Destroy()
				return
			end
			if currentSky then currentSky:Destroy() end
			for _, object in ipairs(lighting:GetChildren()) do
				if object:IsA("Sky") then
					table.insert(savedSkies, snapshotSky(object))
					object.Parent = nil
				end
			end
			sky.Name = "AmanyCustomSky"
			sky.Parent = lighting
			currentSky = sky
		end)
	end

	for index, preset in ipairs(presets) do
		toggles[preset.name] = makeToggle(skySec.container, preset.name, 50 + (index - 1) * 28, function(value)
			if disposed then return end
			if value then
				for name, toggle in pairs(toggles) do
					if name ~= preset.name then toggle:setState(false) end
				end
				selected = preset.name
				apply(preset)
			elseif selected == preset.name then
				selected = nil
				generation = generation + 1
				restore()
			end
		end)
	end
	_screenGui.Destroying:Connect(function()
		disposed = true
		selected = nil
		generation = generation + 1
		restore()
	end)
end


local worldSec = worldTab:newSection({name="World", is_changeable=true, scale=0.42}); worldSec.frame.Position=UDim2.new(0,0,0.34,0)
getgenv().Resolution = getgenv().Resolution or {[".gg/scripters"]=0.65}
local stretchOn=false
makeToggle(worldSec.container, "World Rift Stretch", 22, function(v) stretchOn=v; if v and not getgenv().gg_scripters then RunService.RenderStepped:Connect(function() if stretchOn then camera.CFrame=camera.CFrame*CFrame.new(0,0,0,1,0,0,0,getgenv().Resolution[".gg/scripters"],0,0,0,1) end end); getgenv().gg_scripters=true end end)

local snowOn=false
local snowConn
local snowFolder
local function stopSnow()
	if snowConn then snowConn:Disconnect(); snowConn=nil end
	if snowFolder then snowFolder:Destroy(); snowFolder=nil end
end
makeToggle(worldSec.container,"Rift World 1 (Snow)",50,function(value)
	snowOn=value
	stopSnow()
	if not value then return end
	local previous=workspace:FindFirstChild("NieveBlancaYokai")
	if previous then previous:Destroy() end
	snowFolder=Instance.new("Folder")
	snowFolder.Name="NieveBlancaYokai"
	local parts,positions,frames,offsets={},{},{},{}
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local currentCamera=workspace.CurrentCamera
	local center=root and root.Position+Vector3.new(0,9,0) or (currentCamera and currentCamera.CFrame.Position or Vector3.zero)
	for i=1,650 do
		local part=Instance.new("Part")
		part.Size=Vector3.new(0.15,0.15,0.15); part.Shape=Enum.PartType.Ball
		part.Material=Enum.Material.Neon; part.Color=Color3.fromRGB(255,255,255)
		part.Transparency=0.42; part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
		local position=center+Vector3.new(math.random(-50,50),math.random(-20,50),math.random(-50,50))
		part.CFrame=CFrame.new(position); part.Parent=snowFolder
		parts[i]=part; positions[i]=position; frames[i]=part.CFrame; offsets[i]=math.random()*12
	end
	snowFolder.Parent=workspace
	local elapsed=0
	snowConn=RunService.Heartbeat:Connect(function(dt)
		elapsed=elapsed+dt
		if elapsed<1/30 then return end
		local step=elapsed; elapsed=0
		root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		currentCamera=workspace.CurrentCamera
		center=root and root.Position+Vector3.new(0,9,0) or (currentCamera and currentCamera.CFrame.Position or center)
		local now=os.clock()
		for i=1,#parts do
			local position=positions[i]+Vector3.new(math.sin(now+offsets[i])*2.4*step,-20*step,math.cos(now+offsets[i]*1.3)*2.1*step)
			if math.abs(position.X-center.X)>55 or math.abs(position.Z-center.Z)>55 or position.Y<center.Y-22 then
				position=center+Vector3.new(math.random(-50,50),math.random(18,55),math.random(-50,50))
			end
			positions[i]=position; frames[i]=CFrame.new(position)
		end
		workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged)
	end)
end)
_screenGui.Destroying:Connect(stopSnow)

--==================== APPEARANCE PACK (pasted script) ====================--
do
	local Lighting = game:GetService("Lighting")
	local PlayerGui = player:WaitForChild("PlayerGui")
	local CoreGui = game:GetService("CoreGui")
	local sec = worldTab:newSection({name="Appearance Pack",is_changeable=true,scale=0.98})
	sec.frame.Position=UDim2.new(0.5,4,0,0)
	local enabled, originals = {}, {}
	local alive = true

	local assets = {texture=""}
	local paths = {texture="texture_fleasion_7658055825.png"}
	local function remember(kind,obj,prop,value)
		originals[kind]=originals[kind] or {}
		local entries=originals[kind]
		entries[obj]=entries[obj] or {}
		if entries[obj][prop]==nil then entries[obj][prop]={value=obj[prop]} end
		obj[prop]=value
	end
	local function restore(kind)
		for obj,props in pairs(originals[kind] or {}) do
			for prop,old in pairs(props) do pcall(function() obj[prop]=old.value end) end
		end
		originals[kind]=nil
	end
	local fontWatches = {}
	local codeFont = Font.fromEnum(Enum.Font.Code)
	local function stopFontWatches()
		for obj,entry in pairs(fontWatches) do
			for _,connection in ipairs(entry.connections) do connection:Disconnect() end
		end
		table.clear(fontWatches)
	end
	local function enforceFont(obj)
		if not alive or not enabled.font or not obj:IsDescendantOf(PlayerGui) then return end
		if obj.FontFace~=codeFont then remember("font",obj,"FontFace",codeFont) end
		if not obj.TextScaled then
			if obj.TextSize>32 then remember("font",obj,"TextSize",24)
			elseif obj.TextSize<10 then remember("font",obj,"TextSize",12) end
		end
	end
	local function watchFont(obj)
		if fontWatches[obj] then enforceFont(obj); return end
		-- Save the complete FontFace, including custom font families and weight.
		remember("font",obj,"FontFace",codeFont)
		local entry={connections={},pending=false}
		fontWatches[obj]=entry
		local function schedule()
			if entry.pending or not enabled.font then return end
			entry.pending=true
			task.defer(function()
				entry.pending=false
				if fontWatches[obj]==entry then pcall(enforceFont,obj) end
			end)
		end
		for _,prop in ipairs({"FontFace","TextSize","TextScaled","Text"}) do
			table.insert(entry.connections,obj:GetPropertyChangedSignal(prop):Connect(schedule))
		end
		table.insert(entry.connections,obj.Destroying:Connect(function()
			for _,connection in ipairs(entry.connections) do connection:Disconnect() end
			fontWatches[obj]=nil
			if originals.font then originals.font[obj]=nil end
		end))
		enforceFont(obj)
	end

	local function resolve(path)
		if path:match("^rbxassetid://%d+$") then return path end
		if type(getcustomasset)=="function" and type(isfile)=="function" then
			local ok,result=pcall(function() if isfile(path) then return getcustomasset(path) end end)
			if ok then return result end
		end
	end
	local status=utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,156),Size=UDim2.new(1,-24,0,44),TextWrapped=true,Font=Enum.Font.SourceSans,Text="Map Texture: local file or rbxassetid:// ID.",TextSize=12,TextColor3=Color3.fromRGB(190,190,190),Parent=sec.container})
	local function excluded(obj)
		local cam=workspace.CurrentCamera
		if cam and obj:IsDescendantOf(cam) then return true end
		local node=obj
		while node and node~=workspace do
			if node:IsA("Model") and Players:GetPlayerFromCharacter(node) then return true end
			local name=node.Name:lower()
			for _,term in ipairs({"weapon","arm","hand","gun","lobby","spawn","menu"}) do
				if name:find(term,1,true) then return true end
			end
			node=node.Parent
		end
		return false
	end
	local function process(obj)
		if not alive or not obj.Parent then return end
		pcall(function()
			if obj:IsDescendantOf(CoreGui) or obj:IsDescendantOf(_screenGui) then return end
			local inGui=obj:IsDescendantOf(PlayerGui)
			if enabled.font and inGui and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
				local skip=false
				for _,term in ipairs({"fps","ping","top","stat","kill","streak","left","center"}) do
					if obj.Name:lower():find(term,1,true) then skip=true; break end
				end
				if not skip then
					watchFont(obj)
					if not obj.TextScaled then
						if obj.TextSize>32 then remember("font",obj,"TextSize",24)
						elseif obj.TextSize<10 then remember("font",obj,"TextSize",12) end
					end
				end
			end
			if enabled.texture and assets.texture~="" and obj:IsDescendantOf(workspace) and not excluded(obj) then
				local prop=(obj:IsA("MeshPart") and "TextureID") or ((obj:IsA("Decal") or obj:IsA("Texture")) and "Texture")
				if prop and tostring(obj[prop]):find("7658055825",1,true) then
					if obj:IsA("MeshPart") then
						for _,child in ipairs(obj:GetChildren()) do
							if child:IsA("SurfaceAppearance") then remember("texture",child,"Parent",nil) end
						end
					end
					remember("texture",obj,prop,assets.texture)
				end
			end
			if enabled.menu and inGui then
				local viewport=obj:FindFirstAncestorWhichIsA("ViewportFrame")
				if viewport then
					if obj:IsA("SurfaceAppearance") then remember("menu",obj,"Parent",nil)
					elseif obj:IsA("BasePart") and not (originals.menu and originals.menu[obj] and originals.menu[obj].Size) then
						remember("menu",obj,"Size",Vector3.new(obj.Size.X*1.05,obj.Size.Y*0.95,obj.Size.Z*1.05))
					end
				end
			end
		end)
	end
	local function scan(kind)
		local roots=kind=="texture" and {workspace} or {PlayerGui}
		for _,root in ipairs(roots) do
			for _,obj in ipairs(root:GetDescendants()) do process(obj) end
		end
	end
	for i,option in ipairs({{"font","Code Font"},{"texture","Map Texture"},{"menu","Menu Weapon Style"}}) do
		local kind=option[1]
		local toggle
		toggle=makeToggle(sec.container,option[2],20+(i-1)*28,function(value)
			if value and kind=="texture" then
				assets[kind]=resolve(paths[kind]) or ""
				if assets[kind]=="" then status.Text="Missing asset: "..paths[kind]; toggle:setState(false); return end
			end
			enabled[kind]=value
			if value then scan(kind) else
				if kind=="font" then stopFontWatches() end
				restore(kind)
			end
		end)
	end
	local function pathBox(kind,y)
		local box=utility.newObject("TextBox",{BackgroundColor3=Color3.fromRGB(30,30,30),BorderColor3=Color3.fromRGB(80,80,80),Position=UDim2.new(0,12,0,y),Size=UDim2.new(1,-24,0,24),Font=Enum.Font.SourceSans,Text=paths[kind],PlaceholderText=kind.." file / asset ID",ClearTextOnFocus=false,TextSize=12,TextColor3=Color3.fromRGB(220,220,220),Parent=sec.container})
		box.FocusLost:Connect(function()
			paths[kind]=box.Text
			if enabled[kind] then
				restore(kind); assets[kind]=resolve(paths[kind]) or ""; scan(kind)
				status.Text=assets[kind]~="" and "Asset updated" or ("Missing asset: "..paths[kind])
			end
		end)
	end
	pathBox("texture",120)
	local connections={}
	for _,root in ipairs({workspace,PlayerGui}) do
		table.insert(connections,root.DescendantAdded:Connect(function(obj)
			if root==workspace then
				if not enabled.texture then return end
			elseif not (enabled.font or enabled.menu) then return end
			task.delay(0.1,function() if alive then process(obj) end end)
		end))
	end
	_screenGui.Destroying:Connect(function()
		alive=false
		stopFontWatches()
		for _,conn in ipairs(connections) do conn:Disconnect() end
		for kind in pairs(enabled) do enabled[kind]=false; restore(kind) end
	end)

end


--==================== TAB 5: PLAYER ====================--
local plrTab = window:getTab(5)
local plrSec = plrTab:newSection({name="Player", is_changeable=true, scale=0.55})
local speedOn=false; local jumpOn=false; local flyOn=false; local speedVal=16; local jumpVal=50; local flyVal=50; local flyBV=nil; local flyConn=nil

makeToggle(plrSec.container, "Velocity", 22, function(v) speedOn=v; if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed=v and speedVal or 16 end end)
makeSlider(plrSec.container, 48, 0, 100, 16, function(v) speedVal=v; if speedOn and player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed=v end end)
makeToggle(plrSec.container, "Jump", 78, function(v) jumpOn=v; if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.JumpPower=v and jumpVal or 50 end end)
makeSlider(plrSec.container, 104, 50, 1000, 50, function(v) jumpVal=v; if jumpOn and player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.JumpPower=v end end)
makeToggle(plrSec.container, "Fly", 134, function(v) flyOn=v; if v then local char=player.Character; if char and char:FindFirstChild("HumanoidRootPart") then flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(9e9,9e9,9e9); flyBV.Velocity=Vector3.zero; flyBV.Parent=char.HumanoidRootPart; flyConn=RunService.RenderStepped:Connect(function() if not flyOn or not flyBV or not flyBV.Parent then return end; local dir=Vector3.zero; if uis:IsKeyDown(Enum.KeyCode.W) then dir=dir+camera.CFrame.LookVector end; if uis:IsKeyDown(Enum.KeyCode.S) then dir=dir-camera.CFrame.LookVector end; if uis:IsKeyDown(Enum.KeyCode.A) then dir=dir-camera.CFrame.RightVector end; if uis:IsKeyDown(Enum.KeyCode.D) then dir=dir+camera.CFrame.RightVector end; if uis:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end; if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end; flyBV.Velocity=dir.Magnitude>0 and dir.Unit*flyVal or Vector3.zero end) end else if flyConn then flyConn:Disconnect(); flyConn=nil end; if flyBV then flyBV:Destroy(); flyBV=nil end end end)
makeSlider(plrSec.container, 160, 0, 200, 50, function(v) flyVal=v end)

player.CharacterAdded:Connect(function(char) task.wait(0.5); if speedOn and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed=speedVal end; if jumpOn and char:FindFirstChild("Humanoid") then char.Humanoid.JumpPower=jumpVal end end)

--==================== TAB 5+: KILL SOUND ====================--
local killSec = plrTab:newSection({name="Kill Sound", is_changeable=true, scale=0.42})
killSec.frame.Position = UDim2.new(0.5, 4, 0, 0)

local KillSoundMgr = {
	enabled = false,
	soundId = 4590662766,
	volume = 2,
	lastPlayed = 0,
	sound = nil,
	assetList = {},
	listLoaded = false,
	listError = nil,
}

local ASSET_LIST_URL = REMOTE_CONFIG_BASE.."ErTf5GFmKXYSa7QEcyhR.json"

local FALLBACK_LIST = {
	{ name = "Boom Headshot", id = 7361085557 },
	{ name = "Ohhhh", id = 609079653 },
	{ name = "Murder", id = 8329329181 },
	{ name = "Joker Laugh", id = 17026215874 },
	{ name = "Fart", id = 5990352970 },
	{ name = "Bruh", id = 5790762117 },
	{ name = "Metal Pipe", id = 6021847176 },
	{ name = "Roblox Death", id = 1835772614 },
	{ name = "Minecraft Oof", id = 3744380410 },
	{ name = "Vine Boom", id = 5157782758 },
	{ name = "Windows Error", id = 5157773538 },
	{ name = "Notification", id = 6042053626 },
	{ name = "Anime Wow", id = 6750483492 },
	{ name = "Airhorn", id = 5565412810 },
}

local KILL_CFG = CONFIG_FOLDER .. "/killsound.json"
if isfile(KILL_CFG) then
	pcall(function()
		local d = hs:JSONDecode(readfile(KILL_CFG))
		if type(d) == "table" then
			if d.soundId then KillSoundMgr.soundId = d.soundId end
			if d.volume then KillSoundMgr.volume = d.volume end
		end
	end)
end

local function saveKillCfg()
	pcall(function()
		writefile(KILL_CFG, hs:JSONEncode({
			soundId = KillSoundMgr.soundId,
			volume = KillSoundMgr.volume,
		}))
	end)
end

KillSoundMgr.sound = Instance.new("Sound")
KillSoundMgr.sound.Name = "YokaiKillSound"
KillSoundMgr.sound.Looped = false
KillSoundMgr.sound.Parent = game:GetService("SoundService")

local function updateKillSound()
	local id = tostring(KillSoundMgr.soundId):gsub("%D", "")
	KillSoundMgr.sound.SoundId = "rbxassetid://" .. id
	KillSoundMgr.sound.Volume = tonumber(KillSoundMgr.volume) or 2
end
updateKillSound()

local function isAlive()
	local c = player.Character
	if not c then return false end
	local h = c:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0
end

local function playKillSound()
	if not KillSoundMgr.enabled then return end
	if not isAlive() then return end
	if tick() - KillSoundMgr.lastPlayed < 0.3 then return end
	KillSoundMgr.lastPlayed = tick()

	local clone = KillSoundMgr.sound:Clone()
	clone.Parent = game:GetService("SoundService")
	clone:Play()
	Debris:AddItem(clone, 4)
end

task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	pg.DescendantAdded:Connect(function(desc)
		if not desc:IsA("TextLabel") then return end
		local t = desc.Text:upper()
		if t:find("KILLED BY") or t:find("YOU DIED") or t:find("DEATH") or t:find("KILLER") then return end
		if t:find("YOU KILLED") or t:find("ELIMINATED") or t == "+100" or t:find("+100") then
			playKillSound()
		end
	end)
end)

task.spawn(function()
	local rs = game:GetService("ReplicatedStorage")
	for _, v in ipairs(rs:GetDescendants()) do
		if v:IsA("RemoteEvent") then
			local n = v.Name:lower()
			if (n:find("kill") or n:find("elim")) and not n:find("death") then
				v.OnClientEvent:Connect(playKillSound)
			end
		end
	end
end)

task.spawn(function()
	local st = player:WaitForChild("leaderstats", 10) or player:WaitForChild("stats", 5)
	if not st then return end
	local k = st:FindFirstChild("Kills") or st:FindFirstChild("Eliminations") or st:FindFirstChild("Kill")
	if not k then return end
	local last = k.Value
	k.Changed:Connect(function(nv)
		if nv > last then playKillSound() end
		last = nv
	end)
end)

-- 前方宣言 (openDropdownから参照される)
local dropdownBtn
local dropdownPopup = nil
local dropdownCloseConn = nil

local function fetchAssetList()
	if KillSoundMgr.listLoaded then return end

	task.spawn(function()
		local rawBody = httpGet(ASSET_LIST_URL)
		local result = nil

		if rawBody and rawBody ~= "" and not rawBody:find("^404") and not rawBody:find("Not Found") then
			local ok, decoded = pcall(function() return hs:JSONDecode(rawBody) end)
			if ok and type(decoded) == "table" then result = decoded end
		end

		if not result then
			warn("⚠️ KillSound: GitHubから取得できなかったため、ローカルリストを使用します")
			for _, entry in ipairs(FALLBACK_LIST) do
				table.insert(KillSoundMgr.assetList, { name = tostring(entry.name), id = tonumber(entry.id) or entry.id })
			end
			table.sort(KillSoundMgr.assetList, function(a, b) return tostring(a.name) < tostring(b.name) end)
			KillSoundMgr.listLoaded = true
			print("✅ KillSound: " .. #KillSoundMgr.assetList .. " 個のアセットを読み込みました（ローカル）")
			return
		end

		if result.sounds and type(result.sounds) == "table" then
			for _, entry in ipairs(result.sounds) do
				if type(entry) == "table" and entry.name and entry.id then
					table.insert(KillSoundMgr.assetList, { name = tostring(entry.name), id = tonumber(entry.id) or entry.id })
				end
			end
		end
		if #KillSoundMgr.assetList == 0 then
			for name, id in pairs(result) do
				if type(name) == "string" and (type(id) == "number" or (type(id) == "string" and id:match("^%d+$"))) then
					table.insert(KillSoundMgr.assetList, { name = name, id = tonumber(id) or id })
				end
			end
		end
		if #KillSoundMgr.assetList == 0 then
			for _, entry in ipairs(result) do
				if type(entry) == "table" then
					local n = entry.name or entry.Name or entry.title or entry.Title
					local i = entry.id or entry.Id or entry.ID or entry.assetId or entry.AssetId
					if n and i then table.insert(KillSoundMgr.assetList, { name = tostring(n), id = tonumber(i) or i }) end
				end
			end
		end
		if #KillSoundMgr.assetList == 0 and result.data then
			for _, entry in ipairs(result.data) do
				if type(entry) == "table" then
					local n = entry.name or entry.Name or entry.title
					local i = entry.assetId or entry.AssetId or entry.id or entry.Id
					if n and i then table.insert(KillSoundMgr.assetList, { name = tostring(n), id = tonumber(i) or i }) end
				end
			end
		end
		if #KillSoundMgr.assetList == 0 and result.sounds and type(result.sounds) == "table" then
			for name, id in pairs(result.sounds) do
				if type(name) == "string" and (type(id) == "number" or (type(id) == "string" and id:match("^%d+$"))) then
					table.insert(KillSoundMgr.assetList, { name = name, id = tonumber(id) or id })
				end
			end
		end

		if #KillSoundMgr.assetList == 0 then
			warn("⚠️ KillSound: GitHubのJSONに有効なデータがないため、ローカルリストを使用します")
			for _, entry in ipairs(FALLBACK_LIST) do
				table.insert(KillSoundMgr.assetList, { name = tostring(entry.name), id = tonumber(entry.id) or entry.id })
			end
		end

		table.sort(KillSoundMgr.assetList, function(a, b)
			return tostring(a.name) < tostring(b.name)
		end)

		KillSoundMgr.listLoaded = true
		print("✅ KillSound: " .. #KillSoundMgr.assetList .. " 個のアセットを読み込みました")
	end)
end

-- ==================== Kill Sound UI ====================--
local popupGui = Instance.new("ScreenGui")
popupGui.Name = "YokaiPopups"
popupGui.ResetOnSpawn = false
popupGui.IgnoreGuiInset = true
popupGui.DisplayOrder = 999999
popupGui.Parent = player:WaitForChild("PlayerGui")

local function closeDropdown()
	if dropdownPopup then
		dropdownPopup:Destroy()
		dropdownPopup = nil
	end
	if dropdownCloseConn then
		dropdownCloseConn:Disconnect()
		dropdownCloseConn = nil
	end
end

local function openDropdown()
	closeDropdown()
	if #KillSoundMgr.assetList == 0 then return end

	local btnPos = dropdownBtn.AbsolutePosition
	local btnSize = dropdownBtn.AbsoluteSize

	local popup = Instance.new("ScrollingFrame")
	popup.Name = "KillSoundDropdown"
	popup.BackgroundColor3 = Color3.fromRGB(25,25,25)
	popup.BorderColor3 = Color3.fromRGB(100,100,100)
	popup.BorderSizePixel = 1
	popup.ScrollBarThickness = 4
	popup.ZIndex = 999999
	popup.Parent = popupGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0,2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = popup

	for i, entry in ipairs(KillSoundMgr.assetList) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(1,-8,0,24)
		btn.Position = UDim2.new(0,4,0,0)
		btn.Font = Enum.Font.SourceSans
		btn.Text = "  " .. tostring(entry.name)
		btn.TextColor3 = Color3.fromRGB(220,220,220)
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = i
		btn.ZIndex = 1000000
		btn.Parent = popup
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,3); corner.Parent = btn

		btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(55,70,100) end)
		btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(35,35,35) end)
		btn.MouseButton1Click:Connect(function()
			KillSoundMgr.soundId = entry.id
			dropdownBtn.Text = "  " .. tostring(entry.name)
			updateKillSound()
			saveKillCfg()
			closeDropdown()
		end)
	end

	local maxH = 220
	local contentH = #KillSoundMgr.assetList * 26 + 8
	local popupH = math.min(contentH, maxH)

	popup.Size = UDim2.new(0, btnSize.X, 0, popupH)
	popup.CanvasSize = UDim2.new(0, 0, 0, contentH)
	popup.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + btnSize.Y + 2)

	local viewportY = camera.ViewportSize.Y
	if btnPos.Y + btnSize.Y + popupH > viewportY then
		popup.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y - popupH - 2)
	end

	dropdownPopup = popup

	local openTime = tick()
	dropdownCloseConn = uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if tick() - openTime < 0.15 then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local mouse = uis:GetMouseLocation()
		local absPos = popup.AbsolutePosition
		local absSize = popup.AbsoluteSize

		if mouse.X >= absPos.X and mouse.X <= absPos.X + absSize.X
			and mouse.Y >= absPos.Y and mouse.Y <= absPos.Y + absSize.Y then
			return
		end

		local btnAbsPos = dropdownBtn.AbsolutePosition
		local btnAbsSize = dropdownBtn.AbsoluteSize
		if mouse.X >= btnAbsPos.X and mouse.X <= btnAbsPos.X + btnAbsSize.X
			and mouse.Y >= btnAbsPos.Y and mouse.Y <= btnAbsPos.Y + btnAbsSize.Y then
			return
		end

		closeDropdown()
	end)
end

-- ★ 現在のサウンドIDに応じてボタンのテキストを更新
local function refreshDropdownButtonText()
	if not dropdownBtn then return end
	for _, entry in ipairs(KillSoundMgr.assetList) do
		if tonumber(entry.id) == tonumber(KillSoundMgr.soundId) then
			dropdownBtn.Text = "  " .. tostring(entry.name)
			return
		end
	end
	if #KillSoundMgr.assetList > 0 then
		dropdownBtn.Text = "  ID: " .. tostring(KillSoundMgr.soundId) .. " (クリックで選択)"
	else
		dropdownBtn.Text = "  取得失敗 (クリックで再試行)"
	end
end

makeToggle(killSec.container, "Enable Kill Sound", 22, function(v)
	KillSoundMgr.enabled = v
end)

utility.newObject("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.new(0,12,0,52), Size = UDim2.new(0,60,0,16),
	Font = Enum.Font.SourceSans, Text = "Sound:", TextColor3 = Color3.fromRGB(198,198,198),
	TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = killSec.container
})

dropdownBtn = utility.newObject("TextButton", {
	BackgroundColor3 = Color3.fromRGB(30,30,30), BorderColor3 = Color3.fromRGB(80,80,80),
	BorderSizePixel = 1, Position = UDim2.new(0,80,0,50), Size = UDim2.new(1,-100,0,22),
	Font = Enum.Font.SourceSans, Text = "  読み込み中...", TextColor3 = Color3.fromRGB(220,220,220),
	TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = killSec.container
})
utility.newObject("UICorner", {CornerRadius = UDim.new(0,3), Parent = dropdownBtn})
utility.newObject("UIPadding", {PaddingLeft = UDim.new(0,6), Parent = dropdownBtn})

dropdownBtn.MouseButton1Click:Connect(function()
	if dropdownPopup then
		closeDropdown()
		return
	end

	if not KillSoundMgr.listLoaded then
		dropdownBtn.Text = "  読み込み中..."
		KillSoundMgr.listLoaded = false
		KillSoundMgr.listError = nil
		fetchAssetList()
		task.spawn(function()
			local timeout = 8
			local elapsed = 0
			while not KillSoundMgr.listLoaded and elapsed < timeout do
				task.wait(0.2)
				elapsed += 0.2
			end
			if KillSoundMgr.listLoaded then
				refreshDropdownButtonText()
				openDropdown()
			else
				dropdownBtn.Text = "  取得失敗 (クリックで再試行)"
			end
		end)
		return
	end

	openDropdown()
end)

utility.newObject("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.new(0,12,0,80), Size = UDim2.new(0,60,0,16),
	Font = Enum.Font.SourceSans, Text = "Manual ID:", TextColor3 = Color3.fromRGB(150,150,150),
	TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = killSec.container
})

local manualIdBox = utility.newObject("TextBox", {
	BackgroundColor3 = Color3.fromRGB(30,30,30), BorderColor3 = Color3.fromRGB(80,80,80),
	BorderSizePixel = 1, Position = UDim2.new(0,80,0,78), Size = UDim2.new(1,-100,0,20),
	Font = Enum.Font.SourceSans, Text = tostring(KillSoundMgr.soundId),
	TextColor3 = Color3.fromRGB(220,220,220), TextSize = 12, Parent = killSec.container
})
utility.newObject("UICorner", {CornerRadius = UDim.new(0,3), Parent = manualIdBox})
utility.newObject("UIPadding", {PaddingLeft = UDim.new(0,6), Parent = manualIdBox})

manualIdBox.FocusLost:Connect(function()
	local n = tonumber(manualIdBox.Text)
	if n then
		KillSoundMgr.soundId = n
		updateKillSound()
		saveKillCfg()
		refreshDropdownButtonText()
	end
	manualIdBox.Text = tostring(KillSoundMgr.soundId)
end)

utility.newObject("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.new(0,12,0,106), Size = UDim2.new(0,60,0,16),
	Font = Enum.Font.SourceSans, Text = "Volume:", TextColor3 = Color3.fromRGB(198,198,198),
	TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = killSec.container
})

-- ★ decimals = 1 で 0.1 刻みの微調整
makeSlider(killSec.container, 132, 0, 10, KillSoundMgr.volume, function(v)
	KillSoundMgr.volume = v
	updateKillSound()
	saveKillCfg()
end, 1)

-- ★ 実行時に自動でリスト取得 + 完了したらボタン更新
task.spawn(function()
	fetchAssetList()

	local elapsed = 0
	while not KillSoundMgr.listLoaded and elapsed < 10 do
		task.wait(0.1)
		elapsed += 0.1
	end

	if KillSoundMgr.listLoaded then
		refreshDropdownButtonText()
	else
		dropdownBtn.Text = "  取得失敗 (クリックで再試行)"
	end
end)

--==================== HIT SOUND ====================--
do
	local SoundService = game:GetService("SoundService")
	local names = {"Neverlose", "Sparkle", "Minecraft"}
	local ids = {Neverlose="rbxassetid://6607204501", Sparkle="rbxassetid://132463144859699", Minecraft="rbxassetid://4018616850"}
	local state = {enabled=false, name="Neverlose", volume=1, pitch=1, alive=true}
	local live, lastHit = 0, -math.huge
	local folder = Instance.new("Folder")
	folder.Name = "YokaiHitSounds"
	folder.Parent = SoundService
	local function play(preview)
		if not state.alive or (not preview and not state.enabled) then return end
		local now = os.clock()
		if live >= 8 or (not preview and now-lastHit < 0.008) then return end
		if not preview then lastHit = now end
		local sound = Instance.new("Sound")
		sound.SoundId = ids[state.name]
		sound.Volume = state.volume
		sound.PlaybackSpeed = state.pitch
		sound.Parent = folder
		live = live + 1
		local cleaned = false
		local function cleanup()
			if cleaned then return end
			cleaned = true
			live = math.max(0, live-1)
			sound:Destroy()
		end
		sound.Ended:Connect(cleanup)
		task.delay(6, cleanup)
		local ok = pcall(function() sound:Play() end)
		if not ok then cleanup() end
	end
	local sec = plrTab:newSection({name="Hit Sound", is_changeable=true, scale=0.58})
	sec.frame.Position = UDim2.new(0.5,4,0.42,0)
	makeToggle(sec.container, "Enable Hit Sound", 20, function(v) state.enabled=v end)
	local function button(text, y)
		return utility.newObject("TextButton", {
			BackgroundColor3=Color3.fromRGB(30,30,30), BorderColor3=Color3.fromRGB(80,80,80),
			Position=UDim2.new(0,12,0,y), Size=UDim2.new(1,-24,0,22),
			Font=Enum.Font.SourceSans, Text=text, TextSize=13,
			TextColor3=Color3.fromRGB(220,220,220), Parent=sec.container
		})
	end
	local choice = button("Sound: Neverlose  >", 44)
	local index = 1
	choice.MouseButton1Click:Connect(function()
		index=index % #names + 1
		state.name=names[index]
		choice.Text="Sound: "..state.name.."  >"
	end)
	local function label(text,y)
		return utility.newObject("TextLabel", {
			BackgroundTransparency=1, Position=UDim2.new(0,12,0,y), Size=UDim2.new(1,-24,0,16),
			Font=Enum.Font.SourceSans, Text=text, TextSize=13,
			TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Color3.fromRGB(198,198,198), Parent=sec.container
		})
	end
	label("Volume",72)
	makeSlider(sec.container,94,0,5,1,function(v) state.volume=v end,1)
	label("Pitch",116)
	makeSlider(sec.container,138,0.1,3,1,function(v) state.pitch=v end,1)
	button("Preview",162).MouseButton1Click:Connect(function() play(true) end)
	local status = label("Hit detection: connecting...",190)
	-- Publish hitsounds.json beside the Kill Sound catalog in the same repository.
	local HIT_ASSET_LIST_URL = REMOTE_CONFIG_BASE.."hitsounds.json"
	task.spawn(function()
		local ok, result = pcall(function()
			return hs:JSONDecode(httpGet(HIT_ASSET_LIST_URL))
		end)
		if not ok or type(result)~="table" or not state.alive then return end
		local newNames, newIds = {}, {}
		for _,entry in ipairs(result.sounds or result) do
			if type(entry)=="table" and type(entry.name)=="string" then
				local id=tostring(entry.id or ""):match("^%d+$")
				if id and not newIds[entry.name] then
					table.insert(newNames,entry.name)
					newIds[entry.name]="rbxassetid://"..id
				end
			end
		end
		if #newNames==0 then return end
		names,ids=newNames,newIds
		index=table.find(names,state.name) or 1
		state.name=names[index]
		choice.Text="Sound: "..state.name.."  >"
	end)

		-- Ported from sonata: hitSoundIds / muteSoundInstance / CreateSound post-hook.
	local hitSoundIds = {
		["rbxassetid://13110130082"] = true,
		["rbxassetid://16537449730"] = true,
		["rbxassetid://16537337310"] = true,
	}
	local function isHitSoundId(soundId)
		return type(soundId)=="string" and hitSoundIds[soundId]==true
	end
	local function muteSoundInstance(sound)
		if typeof(sound)=="Instance" and sound:IsA("Sound") then
			pcall(function()
				sound.Volume=0
				sound.PlaybackSpeed=0.01
			end)
		end
	end
	local restoreCreateSound
	task.spawn(function()
		for attempt=1,30 do
			if not state.alive then return end
			local modules=game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
			local node=modules and modules:FindFirstChild("Utility")
			if node and node:IsA("ModuleScript") then
				local ok,soundUtility=pcall(require,node)
				if not state.alive then return end
				if ok and type(soundUtility)=="table" and type(soundUtility.CreateSound)=="function" then
					local hooked=pcall(function()
						local function afterCreate(result,soundId)
							if state.alive and state.enabled and isHitSoundId(soundId) then
								muteSoundInstance(result)
							end
						end
						local oldCreate=soundUtility.CreateSound
						local function wrapped(...)
							local soundId=select(2,...)
							local packed=table.pack(oldCreate(...))
							pcall(afterCreate,packed[1],soundId)
							return table.unpack(packed,1,packed.n)
						end
						if type(hookfunction)=="function" then
							local closure=type(newcclosure)=="function" and newcclosure(wrapped) or wrapped
							oldCreate=hookfunction(soundUtility.CreateSound,closure)
							restoreCreateSound=function() hookfunction(soundUtility.CreateSound,oldCreate) end
						else
							soundUtility.CreateSound=wrapped
							restoreCreateSound=function()
								if soundUtility.CreateSound==wrapped then soundUtility.CreateSound=oldCreate end
							end
						end
					end)
					if hooked then return end
				end
			end
			task.wait(1)
		end
		if state.alive then warn("Hit Sound: CreateSound mute could not be installed") end
	end)
	_screenGui.Destroying:Connect(function()
		if restoreCreateSound then pcall(restoreCreateSound) end
	end)


	-- Suppress the original hitmarker only while custom Hit Sound is enabled.
	local restoreHitmarker
	task.spawn(function()
		for attempt=1,30 do
			if not state.alive then return end
			local node=player:FindFirstChild("PlayerScripts")
			for _,name in ipairs({"Modules","ClientReplicatedClasses","ClientFighter","ClientItem","ClientViewModel"}) do
				node=node and node:FindFirstChild(name)
			end
			if node and node:IsA("ModuleScript") then
				local ok,mod=pcall(require,node)
				if not state.alive then return end
				if ok and type(mod)=="table" and type(mod.PlayHitmarkerSound)=="function" then
					local hooked=pcall(function()
						local original=mod.PlayHitmarkerSound
						local function wrapped(self,...)
							if state.alive and state.enabled then return end
							return original(self,...)
						end
						if type(hookfunction)=="function" then
							local closure=type(newcclosure)=="function" and newcclosure(wrapped) or wrapped
							original=hookfunction(mod.PlayHitmarkerSound,closure)
							restoreHitmarker=function() hookfunction(mod.PlayHitmarkerSound,original) end
						else
							mod.PlayHitmarkerSound=wrapped
							restoreHitmarker=function()
								if mod.PlayHitmarkerSound==wrapped then mod.PlayHitmarkerSound=original end
							end
						end
					end)
					if hooked then return end
				end
			end
			task.wait(1)
		end
		if state.alive then warn("Hit Sound: original hitmarker mute could not be installed") end
	end)
	_screenGui.Destroying:Connect(function()
		if restoreHitmarker then pcall(restoreHitmarker) end
	end)

	local installed = {}
	local function install(target)
		if installed[target] or type(target.DamageEffect) ~= "function" then return false end
		local original = target.DamageEffect
		local function wrapped(self,payload,...)
			if state.alive and type(payload)=="table" then
				local amount=payload[utf8.char(0)]
				if amount~=nil and amount~=0 and amount~=false then pcall(play,false) end
			end
			return original(self,payload,...)
		end
		-- Keep the original callable so a later execution does not stack wrappers.
		local restore
		if type(hookfunction)=="function" then
			original=hookfunction(target.DamageEffect,wrapped)
			restore=function() hookfunction(target.DamageEffect,original) end
		else
			target.DamageEffect=wrapped
			restore=function()
				if target.DamageEffect==wrapped then target.DamageEffect=original end
			end
		end
		installed[target]=restore
		return true
	end
	_screenGui.Destroying:Connect(function()
		state.alive=false
		for _,restore in pairs(installed) do pcall(restore) end
		folder:Destroy()
	end)
	-- Resolve each path separately: a missing MouseCrosshair must not block ItemInterface.
	task.spawn(function()
		local paths = {
			{"Modules","ClientReplicatedClasses","ClientFighter","ClientItem","ItemInterface","Mouse","MouseCrosshair"},
			{"Modules","ClientReplicatedClasses","ClientFighter","ClientItem","ItemInterface"}
		}
		for attempt=1,30 do
			if not state.alive then return end
			for _,path in ipairs(paths) do
				local node=player:FindFirstChild("PlayerScripts")
				for _,name in ipairs(path) do node=node and node:FindFirstChild(name) end
				if node and node:IsA("ModuleScript") then
					local ok,mod=pcall(require,node)
					if not state.alive then return end
					if ok and type(mod)=="table" then
						local hooked,result=pcall(install,mod)
						if hooked and result then status.Text="Hit detection: ready"; return end
					end
				end
			end
			task.wait(1)
		end
		if state.alive then status.Text="Hit detection: unavailable" end
	end)
end


--==================== TAB 6: UTILITIES (BLACKLIST) ====================--
local utilTab = window:getTab(6)
local blSec = utilTab:newSection({name="Blacklist System", is_changeable=true, scale=0.92})
blSec.frame.Position=UDim2.new(0,0,0,0); blSec.frame.Size=UDim2.new(1,-8,0.94,-8)

local blacklistData={}
local function loadBlacklist() if isfile("BlacklistSystem/blacklist.json") then local s,d=pcall(function() return hs:JSONDecode(readfile("BlacklistSystem/blacklist.json")) end); if s and type(d)=="table" then return d end end; return {} end
local function saveBlacklist(data) if not isfolder("BlacklistSystem") then makefolder("BlacklistSystem") end; local s,e=pcall(function() return hs:JSONEncode(data) end); if s then writefile("BlacklistSystem/blacklist.json",e) end end
blacklistData=loadBlacklist()
local selectedPlayerId=nil; local currentFilter=""

local function mkPanel(parent, pos, size)
	local f=utility.newObject("Frame",{BackgroundColor3=Color3.fromRGB(12,12,12),BorderColor3=Color3.fromRGB(60,60,60),BorderSizePixel=1,Position=pos,Size=size,Parent=parent})
	local i=utility.newObject("Frame",{BackgroundColor3=Color3.fromRGB(40,40,40),Position=UDim2.new(0,1,0,1),Size=UDim2.new(1,-2,1,-2),Parent=f})
	local i2=utility.newObject("Frame",{BackgroundColor3=Color3.fromRGB(23,23,23),Position=UDim2.new(0,1,0,1),Size=UDim2.new(1,-2,1,-2),Parent=i})
	return i2
end

local listInner=mkPanel(blSec.container, UDim2.new(0,10,0,10), UDim2.new(0.45,-15,1,-20))
utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,5),Size=UDim2.new(0.6,-20,0,20),Font=Enum.Font.SourceSansBold,Text="Players",TextColor3=Color3.fromRGB(198,198,198),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,Parent=listInner})
local playerCount=utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0.6,0,0,5),Size=UDim2.new(0.4,-10,0,20),Font=Enum.Font.SourceSans,Text="0 players",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,Parent=listInner})
local searchBox=utility.newObject("TextBox",{BackgroundColor3=Color3.fromRGB(30,30,30),BorderColor3=Color3.fromRGB(80,80,80),BorderSizePixel=1,Position=UDim2.new(0,10,0,30),Size=UDim2.new(1,-20,0,24),Font=Enum.Font.SourceSans,TextSize=13,TextColor3=Color3.fromRGB(220,220,220),PlaceholderText="Search by name or ID...",PlaceholderColor3=Color3.fromRGB(100,100,100),ClearTextOnFocus=false,Parent=listInner})
utility.newObject("UICorner",{CornerRadius=UDim.new(0,3),Parent=searchBox})
local blScroll=utility.newObject("ScrollingFrame",{BackgroundColor3=Color3.fromRGB(30,30,30),BorderColor3=Color3.fromRGB(80,80,80),BorderSizePixel=1,Position=UDim2.new(0,10,0,60),Size=UDim2.new(1,-20,1,-70),ScrollBarThickness=4,CanvasSize=UDim2.new(0,0,0,0),Parent=listInner})
local blListLayout=Instance.new("UIListLayout"); blListLayout.Padding=UDim.new(0,3); blListLayout.Parent=blScroll

local editorInner=mkPanel(blSec.container, UDim2.new(0.45,5,0,10), UDim2.new(0.55,-15,1,-20))
local targetLabel=utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,5),Size=UDim2.new(1,-20,0,20),Font=Enum.Font.SourceSansBold,Text="Select a player...",TextColor3=Color3.fromRGB(198,198,198),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,Parent=editorInner})
local blNoteBox=utility.newObject("TextBox",{BackgroundColor3=Color3.fromRGB(30,30,30),BorderColor3=Color3.fromRGB(80,80,80),BorderSizePixel=1,Position=UDim2.new(0,10,0,30),Size=UDim2.new(1,-20,1,-115),Font=Enum.Font.SourceSans,TextSize=14,TextColor3=Color3.fromRGB(220,220,220),PlaceholderText="Write a note...",PlaceholderColor3=Color3.fromRGB(100,100,100),ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Parent=editorInner})
local charCounter=utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(1,-80,1,-88),Size=UDim2.new(0,70,0,16),Font=Enum.Font.SourceSans,Text="0 chars",TextColor3=Color3.fromRGB(120,120,120),TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,Parent=editorInner})
blNoteBox:GetPropertyChangedSignal("Text"):Connect(function() local l=#blNoteBox.Text; charCounter.Text=l.." chars"; charCounter.TextColor3=l>500 and Color3.fromRGB(240,70,70) or Color3.fromRGB(120,120,120) end)

local function mkBtn(parent, text, pos, size, color)
	local b=utility.newObject("TextButton",{BackgroundColor3=color,BorderSizePixel=0,Position=pos,Size=size,Font=Enum.Font.SourceSansBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255),Text=text,Parent=parent})
	utility.newObject("UICorner",{CornerRadius=UDim.new(0,3),Parent=b})
	return b
end
local saveBtn=mkBtn(editorInner,"SAVE NOTE",UDim2.new(0,10,1,-70),UDim2.new(0.31,-5,0,30),Color3.fromRGB(100,160,255))
local removeBtn=mkBtn(editorInner,"REMOVE",UDim2.new(0.34,0,1,-70),UDim2.new(0.31,-5,0,30),Color3.fromRGB(240,70,70))
local clearBtn=mkBtn(editorInner,"CLEAR",UDim2.new(0.68,0,1,-70),UDim2.new(0.32,-10,0,30),Color3.fromRGB(60,60,70))

local function addHover(btn, normal, hover) btn.MouseEnter:Connect(function() btn.BackgroundColor3=hover end); btn.MouseLeave:Connect(function() btn.BackgroundColor3=normal end) end
addHover(saveBtn,Color3.fromRGB(100,160,255),Color3.fromRGB(120,180,255))
addHover(removeBtn,Color3.fromRGB(240,70,70),Color3.fromRGB(255,90,90))
addHover(clearBtn,Color3.fromRGB(60,60,70),Color3.fromRGB(80,80,90))

searchBox:GetPropertyChangedSignal("Text"):Connect(function() currentFilter=string.lower(searchBox.Text); refreshBlacklist() end)

function refreshBlacklist()
	for _,child in ipairs(blScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	local list={}; local blCount=0
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=player then
			local pId=tostring(p.UserId); local entry=blacklistData[pId]
			local dn=string.lower(p.DisplayName); local un=string.lower(p.Name)
			if currentFilter~="" and not string.find(dn,currentFilter,1,true) and not string.find(un,currentFilter,1,true) and not string.find(pId,currentFilter,1,true) then continue end
			table.insert(list,{player=p,entry=entry,isBL=entry~=nil}); if entry then blCount+=1 end
		end
	end
	table.sort(list,function(a,b) if a.isBL~=b.isBL then return a.isBL end; return string.lower(a.player.DisplayName)<string.lower(b.player.DisplayName) end)
	for _,data in ipairs(list) do
		local p=data.player; local entry=data.entry; local isSel=selectedPlayerId==p.UserId
		local btn=utility.newObject("TextButton",{BackgroundColor3=isSel and Color3.fromRGB(50,70,110) or (entry and Color3.fromRGB(40,30,30) or Color3.fromRGB(30,30,30)),BorderColor3=isSel and Color3.fromRGB(100,160,255) or (entry and Color3.fromRGB(240,70,70) or Color3.fromRGB(80,80,80)),BorderSizePixel=1,Size=UDim2.new(1,-8,0,32),Font=Enum.Font.SourceSans,TextSize=13,TextColor3=entry and Color3.fromRGB(240,70,70) or Color3.fromRGB(220,220,220),TextXAlignment=Enum.TextXAlignment.Left,Parent=blScroll})
		utility.newObject("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=btn}); utility.newObject("UICorner",{CornerRadius=UDim.new(0,3),Parent=btn})
		btn.Text=(entry and "⚠ " or "")..p.DisplayName.." (@"..p.Name..")"
		local nb=isSel and Color3.fromRGB(50,70,110) or (entry and Color3.fromRGB(40,30,30) or Color3.fromRGB(30,30,30))
		local hb=isSel and Color3.fromRGB(60,80,120) or (entry and Color3.fromRGB(50,35,35) or Color3.fromRGB(40,40,40))
		addHover(btn,nb,hb)
		btn.MouseButton1Click:Connect(function() selectedPlayerId=p.UserId; targetLabel.Text=p.DisplayName.." (@"..p.Name..")"; blNoteBox.Text=entry and entry.note or ""; charCounter.Text=#blNoteBox.Text.." chars"; refreshBlacklist() end)
	end
	blScroll.CanvasSize=UDim2.new(0,0,0,blListLayout.AbsoluteContentSize.Y+8)
	playerCount.Text=#list.." players"..(blCount>0 and " ("..blCount.." blocked)" or "")
end

saveBtn.MouseButton1Click:Connect(function() if not selectedPlayerId then return end; if blNoteBox.Text~="" then blacklistData[tostring(selectedPlayerId)]={note=blNoteBox.Text,updatedAt=os.time()}; saveBlacklist(blacklistData); refreshBlacklist() end end)
removeBtn.MouseButton1Click:Connect(function() if not selectedPlayerId then return end; blacklistData[tostring(selectedPlayerId)]=nil; saveBlacklist(blacklistData); blNoteBox.Text=""; charCounter.Text="0 chars"; targetLabel.Text="Select a player..."; selectedPlayerId=nil; refreshBlacklist() end)
clearBtn.MouseButton1Click:Connect(function() blNoteBox.Text=""; charCounter.Text="0 chars" end)
Players.PlayerAdded:Connect(refreshBlacklist); Players.PlayerRemoving:Connect(refreshBlacklist); refreshBlacklist()

--==================== TAB 7: CONFIG ====================--
local cfgTab = window:getTab(7)
local cfgSec = cfgTab:newSection({name="Configuration", is_changeable=true, scale=0.92})
cfgSec.frame.Position=UDim2.new(0,0,0,0); cfgSec.frame.Size=UDim2.new(1,-8,0.94,-8)
utility.newObject("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,16,0,12),Size=UDim2.new(0,300,0,22),Font=Enum.Font.GothamBold,Text="Configuration",TextColor3=Color3.fromRGB(230,230,255),TextSize=18,Parent=cfgSec.container})
local cfgNameBox=utility.newObject("TextBox",{BackgroundColor3=Color3.fromRGB(28,28,35),BorderColor3=Color3.fromRGB(60,60,75),BorderSizePixel=1,Position=UDim2.new(0,16,0,68),Size=UDim2.new(0,280,0,26),Font=Enum.Font.SourceSans,Text="",TextColor3=Color3.fromRGB(220,220,230),TextSize=14,Parent=cfgSec.container})
local listFrame2=utility.newObject("ScrollingFrame",{BackgroundColor3=Color3.fromRGB(28,28,35),BorderColor3=Color3.fromRGB(60,60,75),BorderSizePixel=1,Position=UDim2.new(0,16,0,128),Size=UDim2.new(0,280,0,110),ScrollBarThickness=4,CanvasSize=UDim2.new(0,0,0,0),Parent=cfgSec.container})
local listLayout2=Instance.new("UIListLayout"); listLayout2.Parent=listFrame2; listLayout2.Padding=UDim.new(0,2)

local function refreshList()
	for _,c in pairs(listFrame2:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local files=listfiles(CONFIG_FOLDER) or {}; local y=0
	for _,f in ipairs(files) do local name=f:match("([^/\\]+)%.json$"); if name and name~="settings" and name~="killsound" then local btn=utility.newObject("TextButton",{BackgroundColor3=(name==selectedConfig) and Color3.fromRGB(50,70,110) or Color3.fromRGB(35,35,45),BorderSizePixel=0,Size=UDim2.new(1,-8,0,24),Font=Enum.Font.SourceSans,Text="  "..name,TextColor3=Color3.fromRGB(210,210,230),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Parent=listFrame2}); btn.MouseButton1Click:Connect(function() selectedConfig=name; cfgNameBox.Text=name; refreshList() end); y=y+26 end end
	listFrame2.CanvasSize=UDim2.new(0,0,0,y)
end
refreshList()

local function makeCfgBtn(text,x,y,color) local b=utility.newObject("TextButton",{BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.new(0,x,0,y),Size=UDim2.new(0,135,0,28),Font=Enum.Font.GothamMedium,Text=text,TextColor3=Color3.fromRGB(240,240,255),TextSize=13,Parent=cfgSec.container}); utility.newObject("UICorner",{CornerRadius=UDim.new(0,4),Parent=b}); return b end

makeCfgBtn("Create config",16,255,Color3.fromRGB(45,90,140)).MouseButton1Click:Connect(function() local n=cfgNameBox.Text; if n=="" then return end; writefile(CONFIG_FOLDER.."/"..n..".json",hs:JSONEncode({created=os.time()})); refreshList() end)
makeCfgBtn("Set autoload",16,292,Color3.fromRGB(50,110,70)).MouseButton1Click:Connect(function() local n=selectedConfig~="" and selectedConfig or cfgNameBox.Text; if n=="" then return end; settings.LastConfig=n; settings.AutoLoad=true; saveSettings() end)
makeCfgBtn("Remove autoload",161,292,Color3.fromRGB(110,50,50)).MouseButton1Click:Connect(function() settings.LastConfig=""; settings.AutoLoad=false; saveSettings() end)
makeCfgBtn("Refresh list",16,335,Color3.fromRGB(50,50,65)).MouseButton1Click:Connect(refreshList)
makeCfgBtn("Delete config",161,255,Color3.fromRGB(110,50,50)).MouseButton1Click:Connect(function() local n=selectedConfig; if n=="" then return end; if isfile(CONFIG_FOLDER.."/"..n..".json") then delfile(CONFIG_FOLDER.."/"..n..".json"); if settings.LastConfig==n then settings.LastConfig=""; settings.AutoLoad=false; saveSettings() end; selectedConfig=""; cfgNameBox.Text=""; refreshList() end end)

if settings.AutoLoad and settings.LastConfig~="" then task.spawn(function() task.wait(0.5); selectedConfig=settings.LastConfig; cfgNameBox.Text=settings.LastConfig end) end

print("✅ Yokai UI v12 Loaded | RightControl to Toggle | Kill Sound: Auto-Load + Popup + Decimal Volume")




















