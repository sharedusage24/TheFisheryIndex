-- ============= The Fishery Index Inspector v1.0.1 by Molicha17 =============
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== Tunables =====
local TITLE_PAD = 8
local BODY_PAD  = 10

local SIDEBAR_W = 140
local SHOW_MUTATIONS   = true 
local SHOW_TOTAL_MULT  = true 

-- fixed defaults
local BODY_FONT_SIZE  = 24
local TITLE_FONT_SIZE = BODY_FONT_SIZE + 4
local PANEL_ALPHA     = 0.1 

-- ============= Universal text style (Guru + stroke) =============
local function styleTextLabel(lbl, textSize, textColor)
	lbl.BackgroundTransparency = 1
	lbl.RichText = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.FontFace = Font.new("rbxasset://fonts/families/Guru.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	lbl.TextSize = textSize or 16
	lbl.TextColor3 = textColor or Color3.fromRGB(230,230,230)
	local stroke = lbl:FindFirstChild("Stroke") or Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.fromRGB(0,0,0)
	stroke.Thickness = 0.5
	stroke.Transparency = 0.3333
	stroke.Parent = lbl
end

-- ==================== UI root ====================
local screen = playerGui:FindFirstChild("ClickInfoGui") or Instance.new("ScreenGui")
screen.Name = "ClickInfoGui"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = playerGui

local panel = screen:FindFirstChild("Panel") or Instance.new("Frame")
panel.Name = "Panel"
panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
panel.BackgroundTransparency = PANEL_ALPHA
panel.BorderSizePixel = 0
panel.Position = UDim2.fromOffset(20, 100)
panel.Size = UDim2.fromOffset(640, 320)
panel.Active = true
panel.Parent = screen

-- Hide the overlay at launch
panel.Visible = false
local menuVisible = false


-- === Draggable Toggle Button (middle-right, debounced, draggable, clamped) ===
local debounce = false

local toggleBtn = screen:FindFirstChild("ToggleOverlay") or Instance.new("TextButton")
toggleBtn.Name = "ToggleOverlay"
toggleBtn.AutoButtonColor = true
toggleBtn.Text = "TFI"
toggleBtn.TextSize = 24
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleBtn.Size = UDim2.fromOffset(54, 54)
toggleBtn.AnchorPoint = Vector2.new(0, 0)
toggleBtn.TextWrapped = true
toggleBtn.TextYAlignment = Enum.TextYAlignment.Center
local function placeBtnMiddleRight()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local sz = toggleBtn.AbsoluteSize
	if sz.X == 0 or sz.Y == 0 then
		sz = Vector2.new(54, 54)
	end
	local x = vp.X - 16 - sz.X
	local y = math.floor(vp.Y * 0.5 - sz.Y * 0.5)
	toggleBtn.Position = UDim2.fromOffset(x, y)
end
toggleBtn.ZIndex = 1000
toggleBtn.Active = true
toggleBtn.Visible = true
toggleBtn.Parent = screen
placeBtnMiddleRight()
RunService.Heartbeat:Wait()
placeBtnMiddleRight()


do
	local corner = toggleBtn:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toggleBtn

	local stroke = toggleBtn:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4
	stroke.Parent = toggleBtn
end

local function setBtnVisual(open)
    toggleBtn.BackgroundColor3 = open and Color3.fromRGB(70,70,70) or Color3.fromRGB(45,45,45)
    if open then
        toggleBtn.Text = "TFI\nON"
    else
        toggleBtn.Text = "TFI\nOFF"
    end
end

setBtnVisual(false)

local function toggleMenu()
	if debounce then return end
	debounce = true
	menuVisible = not menuVisible
	panel.Visible = menuVisible
	setBtnVisual(menuVisible)
	task.delay(0.2, function() debounce = false end) -- debounce window
end

local function clampToScreenTopLeft(pos, size)
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	return Vector2.new(
		math.clamp(pos.X, 0, vp.X - size.X),
		math.clamp(pos.Y, 0, vp.Y - size.Y)
	)
end

local dragging = false
local dragOffsetTL = Vector2.new(0,0)
local movedEnough = false
local CLICK_DRAG_THRESHOLD = 6
local suppressNextClick = false

toggleBtn.MouseButton1Click:Connect(function()
	if suppressNextClick then
		suppressNextClick = false
		return
	end
	toggleMenu()
end)

toggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mouse = UserInputService:GetMouseLocation()
		dragging = true
		movedEnough = false
		dragOffsetTL = mouse - toggleBtn.AbsolutePosition
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local mouse = UserInputService:GetMouseLocation()
	local topLeft = mouse - dragOffsetTL
	local currentTL = toggleBtn.AbsolutePosition
	if not movedEnough and (math.abs(topLeft.X - currentTL.X) > CLICK_DRAG_THRESHOLD or math.abs(topLeft.Y - currentTL.Y) > CLICK_DRAG_THRESHOLD) then
		movedEnough = true
	end
	if movedEnough then
		local clamped = clampToScreenTopLeft(topLeft, toggleBtn.AbsoluteSize)
		toggleBtn.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	if dragging then
		if movedEnough then
			suppressNextClick = true
			task.delay(0.05, function() suppressNextClick = false end)
		end
	end
	dragging = false
end)

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		placeBtnMiddleRight()
	end)
end

local titleBar = panel:FindFirstChild("TitleBar") or Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
titleBar.BackgroundTransparency = 0
titleBar.BorderSizePixel = 0
titleBar.Parent = panel

local titlePadding = titleBar:FindFirstChild("UIPadding") or Instance.new("UIPadding")
titlePadding.Name = "UIPadding"
titlePadding.PaddingLeft   = UDim.new(0, TITLE_PAD)
titlePadding.PaddingTop    = UDim.new(0, TITLE_PAD)
titlePadding.PaddingBottom = UDim.new(0, TITLE_PAD)
titlePadding.Parent = titleBar

local titleText = titleBar:FindFirstChild("Title") or Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.fromScale(1,1)
titleText.Text = "The Fishery Index — Inspector"
titleText.TextXAlignment = Enum.TextXAlignment.Center
titleText.TextYAlignment = Enum.TextYAlignment.Center
titleText.BackgroundTransparency = 1
titleText.Parent = titleBar
styleTextLabel(titleText, TITLE_FONT_SIZE, Color3.fromRGB(230,230,230))

local function layoutTitle()
	local h = TITLE_FONT_SIZE + (TITLE_PAD * 2)
	titleBar.Size = UDim2.new(1, 0, 0, math.max(28, h))
end
layoutTitle()

-- ===== Two-column layout =====
local body = panel:FindFirstChild("Body") or Instance.new("Frame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Parent = panel

local sidebar = body:FindFirstChild("Sidebar") or Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.BackgroundTransparency = 1
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
sidebar.Position = UDim2.fromOffset(0, 0)
sidebar.Parent = body

-- Insert UIListLayout for tab stacking and wrapping
local sideList = sidebar:FindFirstChild("List") or Instance.new("UIListLayout")
sideList.Name = "List"
sideList.FillDirection = Enum.FillDirection.Vertical
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Padding = UDim.new(0, 6)
sideList.Parent = sidebar

-- separator next to sidebar
local sideSep = body:FindFirstChild("SidebarSep") or Instance.new("Frame")
sideSep.Name = "SidebarSep"
sideSep.BackgroundColor3 = Color3.fromRGB(55,55,55)
sideSep.BorderSizePixel = 0
sideSep.Size = UDim2.new(0, 1, 1, 0)
sideSep.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
sideSep.Parent = body

local mainArea = body:FindFirstChild("MainArea") or Instance.new("Frame")
mainArea.Name = "MainArea"
mainArea.BackgroundTransparency = 1
mainArea.Position = UDim2.new(0, SIDEBAR_W + 1, 0, 0)
mainArea.Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, 0)
mainArea.Parent = body


-- ===== Sidebar tab sizing (prevents overlap) =====
local TAB_TEXT_SIZE   = 24
local TAB_VPAD_FACTOR = 0.25 -- extra height = 25% of text size
local TAB_GAP         = 6
local function getTabButtonHeight()
    return math.ceil(TAB_TEXT_SIZE * (1 + TAB_VPAD_FACTOR))
end

local function makeTabButton(name, order)
    local btn = sidebar:FindFirstChild(name) or Instance.new("TextButton")
    btn.Name = name
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.AutoButtonColor = true
    btn.Size = UDim2.new(1, -12, 0, 0) -- width fills, height auto
    btn.AutomaticSize = Enum.AutomaticSize.Y
    btn.LayoutOrder = order
    btn.Text = name
    btn.Parent = sidebar

    -- style then override alignment for center + wrapping
    styleTextLabel(btn, TAB_TEXT_SIZE, Color3.fromRGB(230,230,230))
    btn.TextWrapped = true
    btn.TextTruncate = Enum.TextTruncate.None
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.TextYAlignment = Enum.TextYAlignment.Center

    -- Add inner padding for wrapped text
    local pad = btn:FindFirstChild("Pad") or Instance.new("UIPadding")
    pad.Name = "Pad"
    local vpad = math.ceil(TAB_TEXT_SIZE * (TAB_VPAD_FACTOR * 0.5))
    pad.PaddingTop    = UDim.new(0, vpad)
    pad.PaddingBottom = UDim.new(0, vpad)
    pad.PaddingLeft   = UDim.new(0, 8)
    pad.PaddingRight  = UDim.new(0, 8)
    pad.Parent = btn

    -- Enforce a minimum height so long labels expand instead of truncating
    btn.Size = UDim2.new(1, -12, 0, math.max(getTabButtonHeight(), btn.AbsoluteSize.Y))
    btn.AutomaticSize = Enum.AutomaticSize.Y

    local corner = btn:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    return btn
end

local inspectorBtn = makeTabButton("Inspector",      1)
local merchantBtn  = makeTabButton("Merchant Timer", 2)
local fishSkinBtn = makeTabButton("Fish Skin Changer", 3)

-- ====== Fish Skin Changer View ======
local skinView = mainArea:FindFirstChild("FishSkinView") or Instance.new("Frame")
skinView.Name = "FishSkinView"
skinView.BackgroundTransparency = 1
skinView.Visible = false
skinView.Size = UDim2.fromScale(1,1)
skinView.Parent = mainArea

local sPad = skinView:FindFirstChild("Pad") or Instance.new("UIPadding")
sPad.Name = "Pad"
sPad.PaddingLeft = UDim.new(0, BODY_PAD)
sPad.PaddingTop  = UDim.new(0, BODY_PAD)
sPad.Parent = skinView

local sTitle = skinView:FindFirstChild("Title") or Instance.new("TextLabel")
sTitle.Name = "Title"
sTitle.BackgroundTransparency = 1
sTitle.Text = "Fish Skin Changer"
sTitle.Size = UDim2.new(1, -BODY_PAD, 0, 28)
sTitle.Position = UDim2.fromOffset(0, 0)
sTitle.Parent = skinView
styleTextLabel(sTitle, math.max(18, BODY_FONT_SIZE), Color3.fromRGB(230,230,230))

-- Toggle button acting as a checkbox
local iceToggle = skinView:FindFirstChild("IceToggle") or Instance.new("TextButton")
iceToggle.Name = "IceToggle"
iceToggle.Size = UDim2.fromOffset(220, 30)
iceToggle.Position = UDim2.fromOffset(0, 40)
iceToggle.Text = "[ ] Fix Frozen"
iceToggle.Parent = skinView
styleTextLabel(iceToggle, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))
iceToggle.AutoButtonColor = true
local iceCorner = iceToggle:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", iceToggle)
iceCorner.CornerRadius = UDim.new(0,6)

local lightToggle = skinView:FindFirstChild("LightToggle") or Instance.new("TextButton")
lightToggle.Name = "LightToggle"
lightToggle.Size = UDim2.fromOffset(260, 30)
lightToggle.Position = UDim2.fromOffset(0, 80)
lightToggle.Text = "[ ] Fish is too bright"
lightToggle.Parent = skinView
styleTextLabel(lightToggle, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))
lightToggle.AutoButtonColor = true
local lightCorner = lightToggle:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", lightToggle)
lightCorner.CornerRadius = UDim.new(0,6)

-- Third toggle: set Ice.OriginalTransparency = 1 ("Remove Frozen")
local removeToggle = skinView:FindFirstChild("RemoveToggle") or Instance.new("TextButton")
removeToggle.Name = "RemoveToggle"
removeToggle.Size = UDim2.fromOffset(260, 30)
removeToggle.Position = UDim2.fromOffset(0, 120)
removeToggle.Text = "[ ] Remove Frozen"
removeToggle.Parent = skinView
styleTextLabel(removeToggle, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))
removeToggle.AutoButtonColor = true
local removeCorner = removeToggle:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", removeToggle)
removeCorner.CornerRadius = UDim.new(0,6)

-- Fourth toggle: disable Fire1 emission under Fish attachments ("Remove Atlantic")
local atlanticToggle = skinView:FindFirstChild("AtlanticToggle") or Instance.new("TextButton")
atlanticToggle.Name = "AtlanticToggle"
atlanticToggle.Size = UDim2.fromOffset(260, 30)
atlanticToggle.Position = UDim2.fromOffset(0, 160)
atlanticToggle.Text = "[ ] Remove Atlantic"
atlanticToggle.Parent = skinView
styleTextLabel(atlanticToggle, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))
atlanticToggle.AutoButtonColor = true
local atlCorner = atlanticToggle:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", atlanticToggle)
atlCorner.CornerRadius = UDim.new(0,6)

-- Remember state on the view
skinView:SetAttribute("IceOn", false)
skinView:SetAttribute("LightsOff", false) -- when true, PointLights in Fish are disabled
skinView:SetAttribute("RemoveFrozenOn", false)
skinView:SetAttribute("RemoveAtlanticOn", false)

local function applyIce(on)
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "Fish" then
			local ice = m:FindFirstChild("Ice", true)
			if ice and ice:IsA("BasePart") then
				if on then
					ice.Material = Enum.Material.Air
					-- If "Remove Frozen" is also on, that wins (sets to 1); otherwise 0.75
					if skinView:GetAttribute("RemoveFrozenOn") then
						ice:SetAttribute("OriginalTransparency", 1)
					else
						ice:SetAttribute("OriginalTransparency", 0.75)
					end
				else
					ice.Material = Enum.Material.Glass
					-- Only revert transparency if "Remove Frozen" is NOT active
					if not skinView:GetAttribute("RemoveFrozenOn") then
						ice:SetAttribute("OriginalTransparency", 0.5)
					end
				end
			end
		end
	end
end

local function applyRemoveFrozen(on)
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "Fish" then
			local ice = m:FindFirstChild("Ice", true)
			if ice and ice:IsA("BasePart") then
				ice:SetAttribute("OriginalTransparency", on and 1 or 0.5)
			end
		end
	end
end

local function applyLights(off)
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "Fish" then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("PointLight") then
					d.Enabled = not off
				end
			end
		end
	end
end

local function applyRemoveAtlantic(on)
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "Fish" then
			for _, d in ipairs(m:GetDescendants()) do
				if (d:IsA("ParticleEmitter") or d.ClassName == "Fire") and d.Name == "Fire1" then
					if d:IsA("ParticleEmitter") then
						d.Enabled = not on
					else
						-- Classic Fire fallback if present
						d.Heat = on and 0 or 10
						d.Size = on and 0 or 5
					end
				end
			end
		end
	end
end

-- Auto-apply Ice material to newly loaded Fish/Ice when enabled
local iceConns = {}

local function attachPerFishListener(fishModel)
	-- Avoid duplicate listener on same model
	if iceConns[fishModel] then return end
	iceConns[fishModel] = fishModel.DescendantAdded:Connect(function(d)
		if not (skinView:GetAttribute("IceOn")
			or skinView:GetAttribute("LightsOff")
			or skinView:GetAttribute("RemoveFrozenOn")
			or skinView:GetAttribute("RemoveAtlanticOn")) then
			return
		end
		if d then
			if d:IsA("BasePart") and d.Name == "Ice" then
				if skinView:GetAttribute("RemoveFrozenOn") then
					d:SetAttribute("OriginalTransparency", 1)
				elseif skinView:GetAttribute("IceOn") then
					d.Material = Enum.Material.Air
					d:SetAttribute("OriginalTransparency", 0.75)
				end
			elseif d:IsA("PointLight") and skinView:GetAttribute("LightsOff") then
				d.Enabled = false
			end
			if skinView:GetAttribute("RemoveAtlanticOn") then
				if (d:IsA("ParticleEmitter") or d.ClassName == "Fire") and d.Name == "Fire1" then
					if d:IsA("ParticleEmitter") then
						d.Enabled = false
					else
						d.Heat = 0; d.Size = 0
					end
				end
			end
		end
	end)
	-- Clean up when the model leaves Workspace
	fishModel.AncestryChanged:Connect(function()
		if not fishModel:IsDescendantOf(Workspace) then
			if iceConns[fishModel] then
				iceConns[fishModel]:Disconnect()
				iceConns[fishModel] = nil
			end
		end
	end)
end

local function attachWorkspaceListener()
	if iceConns.workspace then return end
	iceConns.workspace = Workspace.DescendantAdded:Connect(function(inst)
		if not (skinView:GetAttribute("IceOn")
			or skinView:GetAttribute("LightsOff")
			or skinView:GetAttribute("RemoveFrozenOn")
			or skinView:GetAttribute("RemoveAtlanticOn")) then
			return
		end
		if inst then
			-- New Fish model spawned
			if inst:IsA("Model") and inst.Name == "Fish" then
				-- Apply current states immediately
				if skinView:GetAttribute("IceOn") then
					local ice = inst:FindFirstChild("Ice", true)
					if ice and ice:IsA("BasePart") then
						ice.Material = Enum.Material.Air
						if not skinView:GetAttribute("RemoveFrozenOn") then
							ice:SetAttribute("OriginalTransparency", 0.75)
						end
					end
				end
				if skinView:GetAttribute("LightsOff") then
					for _, d in ipairs(inst:GetDescendants()) do
						if d:IsA("PointLight") then
							d.Enabled = false
						end
					end
				end
				if skinView:GetAttribute("RemoveFrozenOn") then
					local ice2 = inst:FindFirstChild("Ice", true)
					if ice2 and ice2:IsA("BasePart") then
						ice2:SetAttribute("OriginalTransparency", 1)
					end
				end
				if skinView:GetAttribute("RemoveAtlanticOn") then
					for _, d in ipairs(inst:GetDescendants()) do
						if (d:IsA("ParticleEmitter") or d.ClassName == "Fire") and d.Name == "Fire1" then
							if d:IsA("ParticleEmitter") then
								d.Enabled = false
							else
								d.Heat = 0; d.Size = 0
							end
						end
					end
				end
				attachPerFishListener(inst)
			end
			-- Ice or Light parts that appear later at workspace scope
			if inst:IsA("BasePart") and inst.Name == "Ice" and skinView:GetAttribute("IceOn") then
				inst.Material = Enum.Material.Air
				if not skinView:GetAttribute("RemoveFrozenOn") then
					inst:SetAttribute("OriginalTransparency", 0.75)
				end
			elseif inst:IsA("PointLight") and skinView:GetAttribute("LightsOff") then
				inst.Enabled = false
			elseif inst:IsA("BasePart") and inst.Name == "Ice" and skinView:GetAttribute("RemoveFrozenOn") then
				inst:SetAttribute("OriginalTransparency", 1)
			elseif (inst:IsA("ParticleEmitter") or inst.ClassName == "Fire") and inst.Name == "Fire1" and skinView:GetAttribute("RemoveAtlanticOn") then
				if inst:IsA("ParticleEmitter") then
					inst.Enabled = false
				else
					inst.Heat = 0; inst.Size = 0
				end
			end
		end
	end)
	-- Initialize listeners for all existing Fish
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "Fish" then
			attachPerFishListener(m)
		end
	end
end

local detachAllIceListeners
local function refreshSkinListeners()
	local anyOn = (skinView:GetAttribute("IceOn") or false)
	or (skinView:GetAttribute("LightsOff") or false)
	or (skinView:GetAttribute("RemoveFrozenOn") or false)
	or (skinView:GetAttribute("RemoveAtlanticOn") or false)
	if anyOn then
		attachWorkspaceListener()
	else
		detachAllIceListeners()
	end
end

function detachAllIceListeners()
	for key, conn in pairs(iceConns) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
			iceConns[key] = nil
		end
		-- Per-fish stored connections
		if typeof(key) == "Instance" and typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
			iceConns[key] = nil
		end
	end
end

iceToggle.MouseButton1Click:Connect(function()
	local on = not (skinView:GetAttribute("IceOn") or false)
	skinView:SetAttribute("IceOn", on)
	iceToggle.Text = on and "[✓] Fix Frozen" or "[ ] Fix Frozen"
	applyIce(on)
	refreshSkinListeners()
end)

lightToggle.MouseButton1Click:Connect(function()
	local off = not (skinView:GetAttribute("LightsOff") or false)
	skinView:SetAttribute("LightsOff", off)
	lightToggle.Text = off and "[✓] Fish is too bright" or "[ ] Fish is too bright"
	applyLights(off)
	refreshSkinListeners()
end)

removeToggle.MouseButton1Click:Connect(function()
	local on = not (skinView:GetAttribute("RemoveFrozenOn") or false)
	skinView:SetAttribute("RemoveFrozenOn", on)
	removeToggle.Text = on and "[✓] Remove Frozen" or "[ ] Remove Frozen"
	applyRemoveFrozen(on)
	refreshSkinListeners()
end)

atlanticToggle.MouseButton1Click:Connect(function()
	local on = not (skinView:GetAttribute("RemoveAtlanticOn") or false)
	skinView:SetAttribute("RemoveAtlanticOn", on)
	atlanticToggle.Text = on and "[✓] Remove Atlantic" or "[ ] Remove Atlantic"
	applyRemoveAtlantic(on)
	refreshSkinListeners()
end)

-- ====== Inspector View ======
local inspectorView = mainArea:FindFirstChild("InspectorView") or Instance.new("Frame")
inspectorView.Name = "InspectorView"
inspectorView.BackgroundTransparency = 1
inspectorView.Size = UDim2.fromScale(1,1)
inspectorView.Parent = mainArea

local content = inspectorView:FindFirstChild("Content") or Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, BODY_PAD, 0, BODY_PAD)
content.Size = UDim2.new(1, -(BODY_PAD*2), 1, -(BODY_PAD*2))
content.Parent = inspectorView

local label = content:FindFirstChild("Label") or Instance.new("TextLabel")
label.Name = "Label"
label.Size = UDim2.fromScale(1,1)
label.Text = "Click a Fish or Egg…"
label.Parent = content
styleTextLabel(label, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))

-- ====== Merchant Timer View ======
local merchantView = mainArea:FindFirstChild("MerchantView") or Instance.new("Frame")
merchantView.Name = "MerchantView"
merchantView.BackgroundTransparency = 1
merchantView.Visible = false
merchantView.Size = UDim2.fromScale(1,1)
merchantView.Parent = mainArea

local mPad = merchantView:FindFirstChild("Pad") or Instance.new("UIPadding")
mPad.Name = "Pad"
mPad.PaddingLeft = UDim.new(0, BODY_PAD)
mPad.PaddingTop  = UDim.new(0, BODY_PAD)
mPad.Parent = merchantView

local mTitle = merchantView:FindFirstChild("Title") or Instance.new("TextLabel")
mTitle.Name = "Title"
mTitle.BackgroundTransparency = 1
mTitle.Text = "Merchant Timer"
mTitle.Size = UDim2.new(1, -BODY_PAD, 0, 28)
mTitle.Position = UDim2.fromOffset(0, 0)
mTitle.Parent = merchantView
styleTextLabel(mTitle, math.max(18, BODY_FONT_SIZE), Color3.fromRGB(230,230,230))

local mCountdown = merchantView:FindFirstChild("Countdown") or Instance.new("TextLabel")
mCountdown.Name = "Countdown"
mCountdown.BackgroundTransparency = 1
mCountdown.Size = UDim2.new(1, -BODY_PAD, 0, 26)
mCountdown.Position = UDim2.fromOffset(0, 40)
mCountdown.Parent = merchantView
styleTextLabel(mCountdown, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))
mCountdown.Text = "—"

local mNote = merchantView:FindFirstChild("Note") or Instance.new("TextLabel")
mNote.Name = "Note"
mNote.BackgroundTransparency = 1
mNote.Size = UDim2.new(1, -BODY_PAD, 0, 22)
mNote.Position = UDim2.fromOffset(0, 70)
mNote.Parent = merchantView
styleTextLabel(mNote, BODY_FONT_SIZE - 2, Color3.fromRGB(200,200,200))
mNote.Text = ""

local mRefresh = merchantView:FindFirstChild("Refresh") or Instance.new("TextButton")
mRefresh.Name = "Refresh"
mRefresh.Size = UDim2.fromOffset(120, 30)
mRefresh.Position = UDim2.fromOffset(0, 104)
mRefresh.Text = "Refresh"
mRefresh.Parent = merchantView
styleTextLabel(mRefresh, BODY_FONT_SIZE, Color3.fromRGB(230,230,230))
mRefresh.AutoButtonColor = true
do local c = mRefresh:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", mRefresh) c.CornerRadius = UDim.new(0,6) end

-- ===== Merchant timer logic =====
local SPAWN_UTC_HOURS = {2, 8, 14, 20}
local merchantTickerConn
local tickerAccum = 0

local function humanizeHMS(sec)
	sec = math.max(0, math.floor(sec))
	local h = sec // 3600
	local m = (sec % 3600) // 60
	local s = sec % 60
	if h > 0 then
		return string.format("%dh %dm %02ds", h, m, s)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	else
		return string.format("%ds", s)
	end
end

-- next UTC spawn using pure UTC day math (avoids DST / locale issues)
local function nextMerchantUTC()
	local nowUTC = os.time(os.date("!*t"))
	local dayStartUTC = nowUTC - (nowUTC % 86400)
	for _, h in ipairs(SPAWN_UTC_HOURS) do
		local t = dayStartUTC + h * 3600
		if t >= nowUTC then return t end
	end
	return dayStartUTC + 86400 + SPAWN_UTC_HOURS[1] * 3600
end

local function updateMerchantCountdownOnce()
	local nextUTC = nextMerchantUTC()
	local nowLocal = os.time()
	local diff = math.max(0, nextUTC - nowLocal) -- local epoch vs UTC epoch is fine (both seconds since 1970)
	mCountdown.Text = string.format("%s till next merchant", humanizeHMS(diff))
	mNote.Text = string.format("(at %s your time)", os.date("%Y-%m-%d %H:%M:%S", nextUTC)) -- os.date() gives LOCAL string
end

local function stopMerchantTicker()
	if merchantTickerConn then
		merchantTickerConn:Disconnect()
		merchantTickerConn = nil
	end
	tickerAccum = 0
end

local function startMerchantTicker()
	if merchantTickerConn then return end
	updateMerchantCountdownOnce()
	tickerAccum = 0
	merchantTickerConn = RunService.Heartbeat:Connect(function(dt)
	tickerAccum += dt
        while tickerAccum >= 1 do
            updateMerchantCountdownOnce()
            tickerAccum -= 1
        end
    end)
end

mRefresh.MouseButton1Click:Connect(function()
	if mRefresh:GetAttribute("Busy") then return end
	mRefresh:SetAttribute("Busy", true)
	local oldText = mRefresh.Text
	mRefresh.Text = "Updating…"
	updateMerchantCountdownOnce()
	mRefresh.Text = "Refreshed ✓"
	task.delay(0.8, function()
		mRefresh.Text = oldText
		mRefresh:SetAttribute("Busy", false)
	end)
end)


-- ===== Tab switching =====
local function showOnly(view)
	inspectorView.Visible = (view == inspectorView)
	merchantView.Visible  = (view == merchantView)
	skinView.Visible      = (view == skinView)
end

local function showInspector()
	showOnly(inspectorView)
	stopMerchantTicker()
	mCountdown.Text = "—"
	mNote.Text = ""
end
local function showMerchant()
	showOnly(merchantView)
	startMerchantTicker()
end
local function showSkin()
	showOnly(skinView)
	-- If any feature is enabled, ensure listeners active and re-apply
	if skinView:GetAttribute("IceOn")
	   or skinView:GetAttribute("LightsOff")
	   or skinView:GetAttribute("RemoveFrozenOn")
	   or skinView:GetAttribute("RemoveAtlanticOn") then
		attachWorkspaceListener()
		if skinView:GetAttribute("IceOn") then applyIce(true) end
		if skinView:GetAttribute("LightsOff") then applyLights(true) end
		if skinView:GetAttribute("RemoveFrozenOn") then applyRemoveFrozen(true) end
		if skinView:GetAttribute("RemoveAtlanticOn") then applyRemoveAtlantic(true) end
	end
end

inspectorBtn.MouseButton1Click:Connect(showInspector)
merchantBtn.MouseButton1Click:Connect(showMerchant)
fishSkinBtn.MouseButton1Click:Connect(showSkin)
showInspector()

-- ================= Helpers =================
local function nearestModel(inst) local a=inst; while a and not a:IsA("Model") do a=a.Parent end; return a end
local function topModel(m) while m and m.Parent and m.Parent:IsA("Model") do m=m.Parent end; return m end
local function isFishModel(m) return m and m:IsA("Model") and m.Name=="Fish" end
local function isEggModel(m)  return m and m:IsA("Model") and m.Name=="Egg"  end

local function formatNumber(n)
	local s = tostring(n)
	local int, frac = s:match("^(%-?%d+)(%.%d+)?$")
	int = (int or s)
	int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return frac and (int..frac) or int
end
local function rgbString(c)
	local r = math.floor(c.R*255 + 0.5)
	local g = math.floor(c.G*255 + 0.5)
	local b = math.floor(c.B*255 + 0.5)
	return string.format("rgb(%d,%d,%d)", r,g,b)
end

-- ================= Mutation parsing =================
local MUTATION_VALUES = {
	Gold=5, Neon=7, Rainbow=8, Shiny=3, Petrified=2, Frozen=3,
	Cooked=0.25, Eclipsed=20, Sandstoned=15, Atlantic=12,
	Sunkissed=10, Inked=6, Disco=15,
}
local VALID_MUT_SET = {}; for k,_ in pairs(MUTATION_VALUES) do VALID_MUT_SET[k:lower()] = true end
local function trim(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
local function normalizeMutationText(txt)
	if type(txt)~="string" then return nil end
	local clean = trim(txt)
	if not clean:match("^[A-Za-z]+$") then return nil end
	local low = clean:lower(); if not VALID_MUT_SET[low] then return nil end
	for canon,_ in pairs(MUTATION_VALUES) do if canon:lower()==low then return canon end end
	return nil
end

local function favoritedText(holder)
	local f = holder and holder:FindFirstChild("Favorited", true)
	if f and f:IsA("GuiObject") then
		return f.Visible and "Favorited: Is Favorited" or "Favorited: Not Favorited"
	end
	return "Favorited: Not Favorited"
end

local function findFishInfoUI(model)
	if not model then return nil end
	local direct = model:FindFirstChild("FishInfoUI", true)
	if direct then return direct end
	for _,d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local ui = d:FindFirstChild("FishInfoUI", true)
			if ui then return ui end
		end
	end
	return nil
end

-- ================= Fish data & base value =================
local FISH_BY_ID
local function buildFishById()
	if FISH_BY_ID ~= nil then return FISH_BY_ID end
	local ok,mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishes"))
	end)
	if not ok or type(mod)~="table" then FISH_BY_ID = {}; return FISH_BY_ID end
	local data = mod.Data or mod or {}
	local map = {}
	for _,item in ipairs(data) do if type(item)=="table" and item.Id then map[item.Id]=item end end
	FISH_BY_ID = map
	return FISH_BY_ID
end
local function getFirstBasePriceRange(item)
	if not item or not item.WeightGroups then return nil end
	for _,g in ipairs(item.WeightGroups) do
		if g.UseBasePrice then
			local wd = g.WeightData and g.WeightData[1]
			if wd and wd.MinKg and wd.MaxKg then return wd.MinKg, wd.MaxKg end
		end
	end
	return nil
end
local function computeBaseSellValue(fishId, weightKg)
	local db = buildFishById(); local it = db[fishId]; if not it then return nil end
	local minKg, maxKg = getFirstBasePriceRange(it)
	if minKg and maxKg and type(weightKg)=="number" and weightKg>=minKg and weightKg<=maxKg then
		return it.BasePrice
	end
	if type(weightKg)=="number" and type(it.PricePerKg)=="number" then
		return weightKg * it.PricePerKg
	end
	return nil
end

-- ================= Summaries =================
local function summarizeFish(model)
	local fishInfoUI = findFishInfoUI(model)
	local holder     = fishInfoUI and fishInfoUI:FindFirstChild("Holder", true)

	local fishName = "(missing)"
	if holder then
		local fn = holder:FindFirstChild("FishName", true)
		if fn and fn:IsA("TextLabel") and fn.Text ~= "" then fishName = fn.Text end
	end

	local favLine = favoritedText(holder)

	local motherLine
	if holder then
		local mother = holder:FindFirstChild("Mother", true)
		if mother and mother:IsA("GuiObject") and mother.Visible then motherLine = '<font color="rgb(255,105,180)">Mother Fish</font>' end
	end

	local weight = model:GetAttribute("Weight")
	local weightStr, weightNum = "(missing)", nil
	if weight ~= nil then
		local n = tonumber(weight); weightNum = n
		weightStr = n and (string.format("%.1f", n).." kg") or (tostring(weight).." kg")
	end

	local coloredList, totalAdd = {}, 0
	if holder then
		local muts = holder:FindFirstChild("Mutations", true)
		if muts then
			local seen = {}
			for _, d in ipairs(muts:GetDescendants()) do
				if d:IsA("TextLabel") and d.Visible and d.Text and d.Text ~= "" then
					local canon = normalizeMutationText(d.Text)
					if canon and not seen[canon] then
						seen[canon] = true
						local colorStr = rgbString(d.TextColor3)
						table.insert(coloredList, string.format('<font color="%s">%s</font>', colorStr, canon))
						totalAdd += (MUTATION_VALUES[canon] or 0)
					end
				end
			end
		end
	end
	table.sort(coloredList)
	local mutLine = (#coloredList == 0) and "No Mutations" or table.concat(coloredList, ", ")

	local sellValueText
	do
		local fishId = model:GetAttribute("FishId")
		if fishId and weightNum then
			local baseVal = computeBaseSellValue(fishId, weightNum)
			if baseVal then
				local finalVal = math.ceil((totalAdd + 1) * baseVal)
				sellValueText = string.format('<font color="rgb(85,255,0)">Sell Value: $%s</font>', formatNumber(finalVal))
			end
		end
	end

	local lines = {}
	if motherLine then table.insert(lines, motherLine) end
	table.insert(lines, ("Fish Name: %s"):format(fishName))
	table.insert(lines, favLine)
	table.insert(lines, ("Weight: %s"):format(weightStr))
	if SHOW_MUTATIONS then
		table.insert(lines, ("Mutations: %s"):format(mutLine))
	end
	if SHOW_TOTAL_MULT then
		table.insert(lines, ("Total Multiplier: x%s"):format(tostring(totalAdd)))
	end
	if sellValueText then table.insert(lines, sellValueText) end
	return table.concat(lines, "\n")
end

local function summarizeEgg(model)
	local handle = model:FindFirstChild("Handle") or model:FindFirstChildWhichIsA("BasePart")
	local fishInfoUI = (handle and handle:FindFirstChild("FishInfoUI", true)) or findFishInfoUI(model)
	local holder = fishInfoUI and fishInfoUI:FindFirstChild("Holder", true)
	local fishName, progress = "(missing)", "(missing)"
	if holder then
		local fn = holder:FindFirstChild("FishName", true)
		if fn and fn:IsA("TextLabel") and fn.Text ~= "" then fishName = fn.Text end
		local pg = holder:FindFirstChild("Progress", true)
		if pg and pg:IsA("TextLabel") and pg.Text ~= "" then progress = pg.Text end
	end
	local favLine = favoritedText(holder)

	local motherLine
	if holder then
		local mother = holder:FindFirstChild("Mother", true)
		if mother and mother:IsA("GuiObject") and mother.Visible then motherLine = '<font color="rgb(255,105,180)">Mother Fish</font>' end
	end

	local lines = {}
	if motherLine then table.insert(lines, motherLine) end
	table.insert(lines, ("Egg Name: %s"):format(fishName))
	table.insert(lines, favLine)
	table.insert(lines, ("Progress: %s"):format(progress))
	return table.concat(lines, "\n")
end

-- ================= Raycast caches =================
local WATER_EXCLUDE, FISH_WHITELIST, EGG_WHITELIST = {}, {}, {}

local function rebuildWaterExclude()
	table.clear(WATER_EXCLUDE)
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return end
	for _, inst in ipairs(plots:GetDescendants()) do
		if inst.Name == "Water" then
			table.insert(WATER_EXCLUDE, inst)
		end
	end
end

local function rebuildFishEggWhitelists()
	table.clear(FISH_WHITELIST); table.clear(EGG_WHITELIST)
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") then
			if m.Name=="Fish" then table.insert(FISH_WHITELIST, m)
			elseif m.Name=="Egg" then table.insert(EGG_WHITELIST, m) end
		end
	end
end

rebuildWaterExclude()
rebuildFishEggWhitelists()

do
	local plots = Workspace:FindFirstChild("Plots")
	if plots then
		plots.DescendantAdded:Connect(function(d) if d.Name == "Water" then rebuildWaterExclude() end end)
		plots.DescendantRemoving:Connect(function(d) if d.Name == "Water" then rebuildWaterExclude() end end)
	end
end

-- ================= Raycast & input =================
local function castFromMouse()
	local camera = Workspace.CurrentCamera; if not camera then return nil end
	local pos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)

	local p1 = RaycastParams.new()
	p1.FilterType = Enum.RaycastFilterType.Exclude
	p1.FilterDescendantsInstances = WATER_EXCLUDE
	p1.IgnoreWater = true
	local r1 = Workspace:Raycast(ray.Origin, ray.Direction*1000, p1)
	local hit = r1 and r1.Instance or nil
	local m = hit and topModel(nearestModel(hit)) or nil
	if m and (isFishModel(m) or isEggModel(m)) then return hit end

	if #FISH_WHITELIST>0 or #EGG_WHITELIST>0 then
		local wl = {}
		for i=1,#FISH_WHITELIST do wl[#wl+1]=FISH_WHITELIST[i] end
			for i=1,#EGG_WHITELIST do wl[#wl+1]=EGG_WHITELIST[i] end
		local p2 = RaycastParams.new()
		p2.FilterType = Enum.RaycastFilterType.Whitelist
		p2.FilterDescendantsInstances = wl
		p2.IgnoreWater = true
		local r2 = Workspace:Raycast(ray.Origin, ray.Direction*1000, p2)
		return (r2 and r2.Instance) or hit
	end
	return hit
end

local function showInfoForHit(hitInst)
	if not hitInst then
		label.Text = "Click a Fish or Egg…"
		return
	end
	local m = topModel(nearestModel(hitInst))
	if not m then
		label.Text = "Click a Fish or Egg…"
		return
	end
	if isFishModel(m) then
		label.Text = summarizeFish(m)
	elseif isEggModel(m) then
		label.Text = summarizeEgg(m)
	else
		label.Text = "Not a Fish/Egg model"
	end
end

local clicking = false
local function handleClick()
	if clicking then return end
	clicking = true
	local hit = castFromMouse()
	showInfoForHit(hit)
	task.delay(0.05, function() clicking = false end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		handleClick()
	end
end)

UserInputService.TouchTapInWorld:Connect(function(_, processedByUI)
	if processedByUI then return end
	handleClick()
end)

-- ================= Layout adjustments =================
body.Position = UDim2.new(0, 0, 0, titleBar.AbsoluteSize.Y)
body.Size     = UDim2.new(1, 0, 1, -titleBar.AbsoluteSize.Y)

-- ===== Drag (title only) & Resize (clamped) =====
local MIN_W, MIN_H = 420, 240
local RESIZE_THICK = 6

local rightGrip = panel:FindFirstChild("RightGrip") or Instance.new("Frame")
rightGrip.Name = "RightGrip"
rightGrip.BackgroundTransparency = 1
rightGrip.Size = UDim2.new(0, RESIZE_THICK, 1, 0)
rightGrip.Position = UDim2.new(1, -RESIZE_THICK, 0, 0)
rightGrip.Active = true
rightGrip.Parent = panel

local bottomGrip = panel:FindFirstChild("BottomGrip") or Instance.new("Frame")
bottomGrip.Name = "BottomGrip"
bottomGrip.BackgroundTransparency = 1
bottomGrip.Size = UDim2.new(1, 0, 0, RESIZE_THICK)
bottomGrip.Position = UDim2.new(0, 0, 1, -RESIZE_THICK)
bottomGrip.Active = true
bottomGrip.Parent = panel

local cornerGrip = panel:FindFirstChild("CornerGrip") or Instance.new("Frame")
cornerGrip.Name = "CornerGrip"
cornerGrip.BackgroundColor3 = Color3.fromRGB(50,50,50)
cornerGrip.Size = UDim2.fromOffset(RESIZE_THICK+2, RESIZE_THICK+2)
cornerGrip.Position = UDim2.new(1, -(RESIZE_THICK+2), 1, -(RESIZE_THICK+2))
cornerGrip.Active = true
cornerGrip.Parent = panel

local function getViewportSize()
	local cam = Workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1920,1080)
end

local function clampPosToScreen(pos, size)
	local vp = getViewportSize()
	local maxX = math.max(0, vp.X - size.X)
	local maxY = math.max(0, vp.Y - size.Y)
	return Vector2.new(
		math.clamp(pos.X, 0, maxX),
		math.clamp(pos.Y, 0, maxY)
	)
end

local function clampSizeToScreen(w, h, pos)
	local vp = getViewportSize()
	local maxW = math.max(MIN_W, vp.X - pos.X)
	local maxH = math.max(MIN_H, vp.Y - pos.Y)
	return math.clamp(w, MIN_W, maxW), math.clamp(h, MIN_H, maxH)
end

do
	local dragging, dragOffsetTL = false, Vector2.new(0,0)

	local function onInputChanged(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local mouseNow = UserInputService:GetMouseLocation()
		local raw = mouseNow - dragOffsetTL
		local clamped = clampPosToScreen(raw, panel.AbsoluteSize)
		panel.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	end

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local mouseDown = UserInputService:GetMouseLocation()
			dragOffsetTL = mouseDown - panel.AbsolutePosition
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(onInputChanged)
end

local function startResize(which)
	local resizing   = true
	local startMouse = UserInputService:GetMouseLocation()
	local startSize  = panel.AbsoluteSize
	local startPos   = panel.AbsolutePosition

	local conn
	conn = UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = UserInputService:GetMouseLocation() - startMouse
		local newW, newH = startSize.X, startSize.Y
		if which == "right" then
			newW = startSize.X + delta.X
		elseif which == "bottom" then
			newH = startSize.Y + delta.Y
		else -- corner
			newW = startSize.X + delta.X
			newH = startSize.Y + delta.Y
		end

		newW, newH = clampSizeToScreen(newW, newH, startPos)
		panel.Size  = UDim2.fromOffset(newW, newH)
	end)

	local function stop()
		resizing = false
		if conn then conn:Disconnect() end
	end

	local ended
	ended = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			stop()
			ended:Disconnect()
		end
	end)
end

rightGrip.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		startResize("right")
	end
end)

bottomGrip.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		startResize("bottom")
	end
end)

cornerGrip.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		startResize("corner")
	end
end)

local function reClampPanel()
	local pos  = panel.AbsolutePosition
	local size = panel.AbsoluteSize
	local clampedPos = clampPosToScreen(Vector2.new(pos.X, pos.Y), size)
	panel.Position   = UDim2.fromOffset(clampedPos.X, clampedPos.Y)
	local w, h = clampSizeToScreen(size.X, size.Y, clampedPos)
	panel.Size  = UDim2.fromOffset(w, h)

	body.Position = UDim2.new(0, 0, 0, titleBar.AbsoluteSize.Y)
	body.Size     = UDim2.new(1, 0, 1, -titleBar.AbsoluteSize.Y)
end

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(reClampPanel)
end
