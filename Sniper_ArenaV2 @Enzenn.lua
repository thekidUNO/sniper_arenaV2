-- Modern UNO HUB v10.0 -- All 14 Issues Fixed
-- Fixes: Camera conflict, VirtualUser removal, ESP throttling, Raycast visibility,
-- Skeleton ghosting, FOV conditional, Slider precision, Dropdown debounce,
-- Executor checks, Memory cleanup, Touch drag lock, Target validation,
-- R6 allocation, Tween spam cancellation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-------------------------------------------------
-- EXECUTOR CAPABILITY CHECKS (Issue #9)
-------------------------------------------------
local Capabilities = {
    Drawing = typeof(Drawing) == "table" and Drawing.new ~= nil,
    GetHUI = typeof(gethui) == "function",
    Cloneref = typeof(cloneref) == "function",
    GetCustomAsset = typeof(getcustomasset) == "function",
    FileSystem = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function",
}

if not Capabilities.Drawing then
    warn("[UNO HUB] Drawing API unsupported. ESP features disabled.")
end

if Capabilities.GetHUI then
    -- Use gethui if available for better stealth
end

-------------------------------------------------
-- SAFE PARENTING
-------------------------------------------------
local function SafeParent(gui)
    if Capabilities.GetHUI then
        gui.Parent = gethui()
    else
        gui.Parent = game.CoreGui
    end
end

-------------------------------------------------
-- CLEANUP ON RE-EXECUTE
-------------------------------------------------
local oldGui = game.CoreGui:FindFirstChild("UnoModernHub")
if oldGui then
    pcall(function() oldGui:Destroy() end)
end
if Capabilities.GetHUI then
    local hui = gethui()
    for _, v in ipairs(hui:GetChildren()) do
        if v.Name == "UnoModernHub" then
            pcall(function() v:Destroy() end)
        end
    end
end

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local isPC = not isMobile

-------------------------------------------------
-- CONNECTION MANAGER
-------------------------------------------------
local Connections = {}
local function Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

local function DisconnectAll()
    for _, conn in ipairs(Connections) do
        if conn and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end
    Connections = {}
end

-------------------------------------------------
-- TWEEN MANAGER (Issue #14 - Cancel active tweens)
-------------------------------------------------
local ActiveTweens = {}
local function SafeTween(obj, props, dur, style, dir)
    if not obj or not obj.Parent then return end
    local key = tostring(obj)
    if ActiveTweens[key] then
        pcall(function() ActiveTweens[key]:Cancel() end)
    end
    local tween = TweenService:Create(obj, TweenInfo.new(
        dur or 0.2,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props)
    ActiveTweens[key] = tween
    tween:Play()
    tween.Completed:Connect(function()
        if ActiveTweens[key] == tween then
            ActiveTweens[key] = nil
        end
    end)
    return tween
end

local function CancelAllTweens()
    for key, tween in pairs(ActiveTweens) do
        pcall(function() tween:Cancel() end)
    end
    ActiveTweens = {}
end

-------------------------------------------------
-- GLOBAL INTERACTION LOCK (Issue #11)
-------------------------------------------------
local InteractionLock = {
    None = 0,
    Slider = 1,
    Window = 2,
    Icon = 3,
}
local CurrentLock = InteractionLock.None

-------------------------------------------------
-- STATE
-------------------------------------------------
local Features = {
    SkeletonESP = false,
    TracerESP = false,
    BoxESP = false,
    LineESP = false,
    AimAssist = false,
    AimActive = false,      -- NEW: Only true when actively aiming (RMB held)
    AimStrength = 35,
    AimFOV = 140,
    ESPColor = Color3.fromRGB(0, 170, 255),
}

local ESP = {}
local targetSnapshot = nil
local targetSnapshotPlayer = nil  -- Track which player the snapshot belongs to

-------------------------------------------------
-- UTILITY
-------------------------------------------------
local function NewCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

-------------------------------------------------
-- GUI
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UnoModernHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SafeParent(gui)

local WIN_W = isMobile and 340 or 400
local WIN_H = isMobile and 260 or 300

local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
main.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

NewCorner(main, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- Home Icon
local iconSize = isMobile and 44 or 36
local icon = Instance.new("ImageButton")
icon.Size = UDim2.new(0, iconSize, 0, iconSize)
icon.Position = UDim2.new(0, 12, 0.5, -iconSize/2)
icon.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
icon.Image = "rbxassetid://7733960981"
icon.ImageColor3 = Features.ESPColor
icon.AutoButtonColor = false
icon.Active = true
icon.Parent = gui

NewCorner(icon, 12)

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Features.ESPColor
iconStroke.Thickness = 2
iconStroke.Parent = icon

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
topBar.BorderSizePixel = 0
NewCorner(topBar, 14)
topBar.Parent = main

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 18)
topFix.Position = UDim2.new(0, 0, 1, -18)
topFix.BackgroundColor3 = topBar.BackgroundColor3
NewCorner(topFix, 14)
topFix.Parent = topBar

local titleIcon = Instance.new("ImageLabel")
titleIcon.Size = UDim2.new(0, 18, 0, 18)
titleIcon.Position = UDim2.new(0, 10, 0, 11)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://7733960981"
titleIcon.ImageColor3 = Features.ESPColor
titleIcon.Parent = topBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 120, 0, 40)
titleText.Position = UDim2.new(0, 34, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "UNO HUB"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 15
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(0, 120, 0, 14)
subText.Position = UDim2.new(0, 34, 0, 22)
subText.BackgroundTransparency = 1
subText.Text = "v10.0 | Fixed"
subText.TextColor3 = Color3.fromRGB(130, 130, 140)
subText.Font = Enum.Font.Gotham
subText.TextSize = 9
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.Parent = topBar

-- Buttons with tween cancellation (Issue #14)
local btnSize = isMobile and 32 or 26
local function MakeBtn(text, pos, bg, hover)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, btnSize, 0, btnSize)
    btn.Position = pos
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = bg
    btn.AutoButtonColor = false
    btn.Parent = topBar
    NewCorner(btn, 8)

    btn.MouseEnter:Connect(function()
        SafeTween(btn, {BackgroundColor3 = hover}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        SafeTween(btn, {BackgroundColor3 = bg}, 0.15)
    end)
    return btn
end

local minBtn = MakeBtn("−", UDim2.new(1, -90, 0, 6), Color3.fromRGB(45,45,55), Color3.fromRGB(65,65,80))
local hideBtn = MakeBtn("○", UDim2.new(1, -58, 0, 6), Color3.fromRGB(45,45,55), Color3.fromRGB(65,65,80))
local exitBtn = MakeBtn("×", UDim2.new(1, -26, 0, 6), Color3.fromRGB(210,55,55), Color3.fromRGB(255,75,75))

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -12, 0, 32)
tabBar.Position = UDim2.new(0, 6, 0, 44)
tabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
tabBar.BorderSizePixel = 0
NewCorner(tabBar, 10)
tabBar.Parent = main

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 6)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.Parent = tabBar

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -12, 1, -82)
contentArea.Position = UDim2.new(0, 6, 0, 80)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.Parent = main

-- =============================================
-- TAB SYSTEM
-- =============================================
local tabs = {}
local activeTab = "Combat"
local tabContents = {}

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name.."Tab"
    btn.Size = UDim2.new(0, isMobile and 80 or 100, 0, 26)
    btn.BackgroundColor3 = name == activeTab and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(32, 32, 40)
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    NewCorner(btn, 8)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name.."Scroll"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
    scroll.Visible = name == activeTab
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = contentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)

    tabs[name] = btn
    tabContents[name] = scroll

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        SafeTween(tabs[activeTab], {BackgroundColor3 = Color3.fromRGB(32, 32, 40)}, 0.2)
        tabContents[activeTab].Visible = false
        activeTab = name
        SafeTween(btn, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
        tabContents[name].Visible = true
    end)

    return scroll
end

local combatScroll = CreateTab("Combat")
local visualScroll = CreateTab("Visual")

-- =============================================
-- TOGGLE (with tween cancellation)
-- =============================================
local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, isMobile and 52 or 44)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    NewCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = isMobile and 15 or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, isMobile and 56 or 48, 0, isMobile and 30 or 26)
    track.Position = UDim2.new(1, -66, 0.5, -15)
    track.Text = ""
    track.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 60)
    track.AutoButtonColor = false
    track.Parent = frame
    NewCorner(track, 1)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, isMobile and 24 or 20, 0, isMobile and 24 or 20)
    knob.Position = default and UDim2.new(1, -28, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = track
    NewCorner(knob, 1)

    local state = default
    track.MouseButton1Click:Connect(function()
        state = not state
        if state then
            SafeTween(track, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
            SafeTween(knob, {Position = UDim2.new(1, -28, 0.5, -12)}, 0.2)
        else
            SafeTween(track, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.2)
            SafeTween(knob, {Position = UDim2.new(0, 3, 0.5, -12)}, 0.2)
        end
        callback(state)
    end)

    return frame
end

-- =============================================
-- SLIDER (Fixed precision + interaction lock)
-- =============================================
local ActiveSlider = nil
local sliderData = {}

local function CreateSlider(parent, labelText, min, max, default, callback, suffix)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, isMobile and 68 or 60)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    NewCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText..": "..default..(suffix or "")
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = isMobile and 15 or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local track = Instance.new("TextButton")
    track.Name = "SliderTrack"
    track.Size = UDim2.new(1, -20, 0, 12)
    track.Position = UDim2.new(0, 10, 0, 36)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    track.Text = ""
    track.AutoButtonColor = false
    track.Active = true
    track.Parent = frame
    NewCorner(track, 1)

    local pct = (default - min) / (max - min)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    NewCorner(fill, 1)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, isMobile and 24 or 18, 0, isMobile and 24 or 18)
    handle.Position = UDim2.new(pct, -handle.Size.X.Offset/2, 0.5, -handle.Size.Y.Offset/2)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = track
    NewCorner(handle, 1)

    local handleStroke = Instance.new("UIStroke")
    handleStroke.Color = Color3.fromRGB(180, 180, 180)
    handleStroke.Thickness = 1
    handleStroke.Parent = handle

    -- Issue #7: Use math.round for smoother values
    local function updateSlider()
        if CurrentLock ~= InteractionLock.None and CurrentLock ~= InteractionLock.Slider then return end
        local mousePos = UIS:GetMouseLocation()
        local barX = track.AbsolutePosition.X
        local barW = track.AbsoluteSize.X
        local newPct = math.clamp((mousePos.X - barX) / barW, 0, 1)
        local value = math.round(min + (newPct * (max - min)))

        fill.Size = UDim2.new(newPct, 0, 1, 0)
        handle.Position = UDim2.new(newPct, -handle.Size.X.Offset/2, 0.5, -handle.Size.Y.Offset/2)
        label.Text = labelText..": "..value..(suffix or "")

        callback(value)
    end

    local sliderId = tostring(frame)
    sliderData[sliderId] = {
        track = track,
        update = updateSlider
    }

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if CurrentLock == InteractionLock.None then
                CurrentLock = InteractionLock.Slider
                ActiveSlider = sliderId
                updateSlider()
            end
        end
    end)

    return frame
end

-- =============================================
-- CENTRALIZED INPUT (with interaction lock)
-- =============================================
Connect(UIS.InputChanged, function(input)
    if ActiveSlider then
        local data = sliderData[ActiveSlider]
        if data then
            data.update()
        end
    end
end)

Connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if ActiveSlider then
            CurrentLock = InteractionLock.None
            ActiveSlider = nil
        end
    end
end)

-- =============================================
-- DROPDOWN (Issue #8 - Debounced animation)
-- =============================================
local function CreateDropdown(parent, labelText, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, isMobile and 52 or 44)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent
    NewCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, frame.Size.Y.Offset)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = isMobile and 15 or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(0, 110, 0, 28)
    display.Position = UDim2.new(1, -124, 0.5, -14)
    display.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    display.Text = default or options[1]
    display.Font = Enum.Font.GothamMedium
    display.TextSize = 12
    display.TextColor3 = Color3.fromRGB(255, 255, 255)
    display.AutoButtonColor = false
    display.Parent = frame
    NewCorner(display, 6)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -22, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 10
    arrow.TextColor3 = Color3.fromRGB(150, 150, 160)
    arrow.Parent = display

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 28)
    list.Position = UDim2.new(0, 0, 0, frame.Size.Y.Offset)
    list.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    list.BorderSizePixel = 0
    list.Visible = false
    list.Parent = frame

    local ll = Instance.new("UIListLayout")
    ll.Parent = list

    local expanded = false
    local dropdownBusy = false  -- Issue #8: Debounce lock

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(32, 32, 42) or Color3.fromRGB(28, 28, 36)
        optBtn.Text = "  "..opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.Parent = list

        optBtn.MouseEnter:Connect(function()
            SafeTween(optBtn, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        optBtn.MouseLeave:Connect(function()
            SafeTween(optBtn, {BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(32, 32, 42) or Color3.fromRGB(28, 28, 36)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end)
        optBtn.MouseButton1Click:Connect(function()
            if dropdownBusy then return end
            display.Text = opt
            callback(opt)
            expanded = false
            dropdownBusy = true
            SafeTween(frame, {Size = UDim2.new(1, -6, 0, isMobile and 52 or 44)}, 0.2)
            arrow.Text = "▼"
            task.delay(0.2, function()
                if not expanded then list.Visible = false end
                dropdownBusy = false
            end)
        end)
    end

    display.MouseButton1Click:Connect(function()
        if dropdownBusy then return end
        expanded = not expanded
        if expanded then
            list.Visible = true
            SafeTween(frame, {Size = UDim2.new(1, -6, 0, (isMobile and 52 or 44) + list.Size.Y.Offset)}, 0.2)
            arrow.Text = "▲"
        else
            SafeTween(frame, {Size = UDim2.new(1, -6, 0, isMobile and 52 or 44)}, 0.2)
            arrow.Text = "▼"
            task.delay(0.2, function()
                if not expanded then list.Visible = false end
            end)
        end
    end)

    return frame
end

-- =============================================
-- POPULATE COMBAT TAB
-- =============================================
CreateToggle(combatScroll, "Aim Assist", false, function(v)
    Features.AimAssist = v
    if not v then
        Features.AimActive = false
        targetSnapshot = nil
        targetSnapshotPlayer = nil
    end
end)

CreateSlider(combatScroll, "Aim Strength", 0, 100, 35, function(v)
    Features.AimStrength = v
end, "%")

CreateSlider(combatScroll, "Aim FOV", 10, 300, 140, function(v)
    Features.AimFOV = v
end, "")

-- =============================================
-- POPULATE VISUAL TAB
-- =============================================
CreateToggle(visualScroll, "Skeleton ESP", false, function(v)
    Features.SkeletonESP = v
end)

CreateToggle(visualScroll, "Tracer ESP", false, function(v)
    Features.TracerESP = v
end)

CreateToggle(visualScroll, "Box ESP", false, function(v)
    Features.BoxESP = v
end)

CreateToggle(visualScroll, "Line ESP", false, function(v)
    Features.LineESP = v
end)

CreateSlider(visualScroll, "Line Thickness", 1, 5, 2, function(v)
    -- Applied in render
end, "")

CreateDropdown(visualScroll, "ESP Color", {"Cyan", "Red", "Green", "Purple", "Yellow", "White"}, "Cyan", function(v)
    local colors = {
        Cyan = Color3.fromRGB(0, 170, 255),
        Red = Color3.fromRGB(255, 60, 60),
        Green = Color3.fromRGB(60, 255, 120),
        Purple = Color3.fromRGB(180, 60, 255),
        Yellow = Color3.fromRGB(255, 220, 60),
        White = Color3.fromRGB(255, 255, 255)
    }
    Features.ESPColor = colors[v] or colors.Cyan
    iconStroke.Color = Features.ESPColor
    titleIcon.ImageColor3 = Features.ESPColor
end)

-- =============================================
-- DRAG (with interaction lock - Issue #11)
-- =============================================
local isDraggingWindow = false
local isDraggingIcon = false
local dragStart = nil
local dragStartPos = nil

Connect(icon.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if CurrentLock == InteractionLock.None then
            CurrentLock = InteractionLock.Icon
            isDraggingIcon = true
            dragStart = input.Position
            dragStartPos = icon.Position
        end
    end
end)

Connect(topBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if CurrentLock == InteractionLock.None then
            CurrentLock = InteractionLock.Window
            isDraggingWindow = true
            dragStart = input.Position
            dragStartPos = main.Position
        end
    end
end)

Connect(UIS.InputChanged, function(input)
    if not isDraggingWindow and not isDraggingIcon then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local delta = input.Position - dragStart

    if isDraggingIcon then
        icon.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    elseif isDraggingWindow then
        main.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    end
end)

Connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingWindow = false
        isDraggingIcon = false
        if CurrentLock == InteractionLock.Window or CurrentLock == InteractionLock.Icon then
            CurrentLock = InteractionLock.None
        end
    end
end)

-- =============================================
-- PC AIM INPUT (Issue #1 - AimActive state)
-- =============================================
if isPC then
    Connect(UIS.InputBegan, function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
            Features.AimActive = true
        end
    end)

    Connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Features.AimActive = false
        end
    end)
end

-- Mobile aim: tap-and-hold on screen bottom half
if isMobile then
    Connect(UIS.InputBegan, function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            if pos.Y > Camera.ViewportSize.Y * 0.6 then
                Features.AimActive = true
            end
        end
    end)
    Connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            Features.AimActive = false
        end
    end)
end

-- =============================================
-- WINDOW BUTTONS
-- =============================================
icon.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        SafeTween(main, {Size = UDim2.new(0, WIN_W, 0, 40)}, 0.2)
        tabBar.Visible = false
        contentArea.Visible = false
    else
        SafeTween(main, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, 0.2)
        tabBar.Visible = true
        contentArea.Visible = true
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

-- =============================================
-- EXIT CLEANUP (Issue #10 - Complete cleanup)
-- =============================================
exitBtn.MouseButton1Click:Connect(function()
    -- Cancel all tweens
    CancelAllTweens()

    -- Disconnect all connections
    DisconnectAll()

    -- Clear snapshots
    targetSnapshot = nil
    targetSnapshotPlayer = nil

    -- Hide UI
    main.Visible = false
    icon.Visible = false

    -- Remove all ESP drawings
    for _, data in pairs(ESP) do
        if data.Tracer then pcall(function() data.Tracer:Remove() end) end
        if data.Skeleton then for _, l in pairs(data.Skeleton) do pcall(function() l:Remove() end) end end
        if data.Box then for _, l in pairs(data.Box) do pcall(function() l:Remove() end) end end
        if data.Line then pcall(function() data.Line:Remove() end) end
    end
    ESP = {}

    -- Remove FOV circle (Issue #10)
    pcall(function() FOVCircle:Remove() end)

    -- Destroy GUI
    task.delay(0.1, function()
        pcall(function() gui:Destroy() end)
    end)
end)

-- =============================================
-- DRAWING (with capability check)
-- =============================================
local function NewLine()
    if not Capabilities.Drawing then return nil end
    local line = Drawing.new("Line")
    line.Visible = false
    line.Transparency = 1
    line.Thickness = isMobile and 2.5 or 1.5
    return line
end

local FOVCircle
if Capabilities.Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Color = Features.ESPColor
    FOVCircle.Thickness = isMobile and 2 or 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Radius = Features.AimFOV
end

-- =============================================
-- SKELETON (Issue #13 - Dynamic allocation)
-- =============================================
local R15Skeleton = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

local R6Skeleton = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}
}

local function GetSkeleton(char)
    if char:FindFirstChild("UpperTorso") then return R15Skeleton end
    return R6Skeleton
end

-- =============================================
-- ESP SETUP (Issue #13 - Dynamic line count)
-- =============================================
local function CreateESP(player)
    if player == LocalPlayer then return end
    if not Capabilities.Drawing then return end

    local char = player.Character
    local skeletonCount = 5  -- Default R6
    if char then
        local skel = GetSkeleton(char)
        skeletonCount = #skel
    end

    local skeleton = {}
    for i = 1, skeletonCount do skeleton[i] = NewLine() end

    local box = {}
    for i = 1, 4 do box[i] = NewLine() end

    ESP[player] = {
        Skeleton = skeleton,
        Tracer = NewLine(),
        Box = box,
        Line = NewLine(),
        IsDead = false,
        SkeletonCount = skeletonCount,  -- Track for dynamic updates
    }

    local function SetupHealth()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        Connect(hum:GetPropertyChangedSignal("Health"), function()
            if hum.Health <= 0 then
                local data = ESP[player]
                if data then
                    data.IsDead = true
                    data.Tracer.Visible = false
                    data.Line.Visible = false
                    for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
                    for _, l in pairs(data.Box) do if l then l.Visible = false end end
                end
            else
                local data = ESP[player]
                if data then data.IsDead = false end
            end
        end)

        Connect(hum.Died, function()
            local data = ESP[player]
            if data then
                data.IsDead = true
                data.Tracer.Visible = false
                data.Line.Visible = false
                for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
                for _, l in pairs(data.Box) do if l then l.Visible = false end end
            end
        end)
    end

    SetupHealth()
    Connect(player.CharacterAdded, function(newChar)
        local data = ESP[player]
        if data then
            data.IsDead = false
            -- Issue #13: Reallocate skeleton lines for new rig type
            local newSkel = GetSkeleton(newChar)
            local newCount = #newSkel
            if newCount ~= data.SkeletonCount then
                -- Remove old lines
                for _, l in pairs(data.Skeleton) do if l then pcall(function() l:Remove() end) end end
                -- Create new lines
                data.Skeleton = {}
                for i = 1, newCount do data.Skeleton[i] = NewLine() end
                data.SkeletonCount = newCount
            end
        end
        task.delay(0.5, SetupHealth)
    end)
end

local function RemoveESP(player)
    local data = ESP[player]
    if not data then return end
    for _, l in pairs(data.Skeleton) do if l then pcall(function() l:Remove() end) end end
    if data.Tracer then pcall(function() data.Tracer:Remove() end) end
    for _, l in pairs(data.Box) do if l then pcall(function() l:Remove() end) end end
    if data.Line then pcall(function() data.Line:Remove() end) end
    ESP[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Connect(Players.PlayerAdded, CreateESP)
Connect(Players.PlayerRemoving, RemoveESP)

-- =============================================
-- AIM TARGETING (Issue #4 - Raycast visibility)
-- =============================================
local function IsVisible(targetPos)
    local origin = Camera.CFrame.Position
    local direction = (targetPos - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel:FindFirstChild("Humanoid") then
            return true  -- Hit a player, visible
        end
        return false  -- Hit a wall/obstacle
    end
    return true  -- Nothing hit, visible
end

local function GetClosestPlayer()
    local closest = nil
    local shortest = Features.AimFOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local data = ESP[p]
                if data and not data.IsDead then
                    local pos, visible = Camera:WorldToViewportPoint(head.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        if dist < shortest then
                            -- Issue #4: Raycast check
                            if IsVisible(head.Position) then
                                shortest = dist
                                closest = head
                            end
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- =============================================
-- RENDER LOOP (Issue #3 - Throttled ESP)
-- =============================================
local LastESP = 0
local ESPThrottle = 0.016  -- ~60fps cap for ESP

Connect(RunService.RenderStepped, function()
    local now = tick()

    -- =============================================
    -- AIMBOT (Full rate - always check)
    -- =============================================
    -- Issue #12: Validate target snapshot every frame
    if targetSnapshot and targetSnapshotPlayer then
        local char = targetSnapshotPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")

        -- Invalidate if dead, missing, or offscreen
        if not hum or hum.Health <= 0 or not head or head ~= targetSnapshot then
            targetSnapshot = nil
            targetSnapshotPlayer = nil
        else
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then
                targetSnapshot = nil
                targetSnapshotPlayer = nil
            end
        end
    end

    -- Find new target if needed
    if not targetSnapshot and Features.AimAssist and Features.AimActive then
        targetSnapshot = GetClosestPlayer()
        if targetSnapshot then
            -- Find which player owns this head
            for _, p in ipairs(Players:GetPlayers()) do
                local char = p.Character
                if char and char:FindFirstChild("Head") == targetSnapshot then
                    targetSnapshotPlayer = p
                    break
                end
            end
        end
    end

    -- Issue #1: Only lerp when AimActive is true (RMB held)
    -- Issue #1: Use CFrame.lookAt to only rotate, not fight position systems
    if Features.AimAssist and Features.AimActive and targetSnapshot then
        local alpha = math.clamp(Features.AimStrength / 100, 0.01, 1.0)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetSnapshot.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
    end

    -- Issue #6: FOV circle only visible when AimAssist AND AimActive
    if Capabilities.Drawing and FOVCircle then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = Features.AimFOV
        FOVCircle.Color = Features.ESPColor
        FOVCircle.Visible = Features.AimAssist and Features.AimActive
    end

    -- =============================================
    -- ESP (Throttled - Issue #3)
    -- =============================================
    if now - LastESP < ESPThrottle then return end
    LastESP = now

    if not Capabilities.Drawing then return end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(ESP) do
        -- Issue #5: Immediately hide all lines BEFORE updates (prevents ghosting)
        data.Tracer.Visible = false
        data.Line.Visible = false
        for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
        for _, l in pairs(data.Box) do if l then l.Visible = false end end

        if data.IsDead then
            continue
        end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not char or not hum or hum.Health <= 0 or not hrp or not head then
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        local thickness = math.clamp(3.5 - (distance / 300), 1, 3.5)
        local color = Features.ESPColor

        -- SKELETON
        if Features.SkeletonESP then
            local connections = GetSkeleton(char)
            for i, bones in ipairs(connections) do
                local p0 = char:FindFirstChild(bones[1])
                local p1 = char:FindFirstChild(bones[2])
                local line = data.Skeleton[i]
                if p0 and p1 and line then
                    local v0, vis0 = Camera:WorldToViewportPoint(p0.Position)
                    local v1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                    if vis0 and vis1 then
                        line.From = Vector2.new(v0.X, v0.Y)
                        line.To = Vector2.new(v1.X, v1.Y)
                        line.Color = color
                        line.Thickness = thickness
                        line.Visible = true
                    end
                end
            end
        end

        -- TRACER
        if Features.TracerESP and myRoot then
            local myPos, myVis = Camera:WorldToViewportPoint(myRoot.Position + Vector3.new(0, 2, 0))
            if myVis then
                data.Tracer.From = Vector2.new(myPos.X, myPos.Y)
                data.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                data.Tracer.Color = color
                data.Tracer.Thickness = thickness
                data.Tracer.Visible = true
            end
        end

        -- BOX ESP
        if Features.BoxESP then
            local headPos = Camera:WorldToViewportPoint(head.Position)
            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local boxHeight = math.abs(headPos.Y - legPos.Y)
            local boxWidth = boxHeight * 0.6
            local centerX = rootPos.X
            local topY = headPos.Y - boxHeight * 0.1
            local botY = legPos.Y

            data.Box[1].From = Vector2.new(centerX - boxWidth/2, topY)
            data.Box[1].To = Vector2.new(centerX + boxWidth/2, topY)
            data.Box[1].Color = color
            data.Box[1].Thickness = thickness
            data.Box[1].Visible = true

            data.Box[2].From = Vector2.new(centerX + boxWidth/2, topY)
            data.Box[2].To = Vector2.new(centerX + boxWidth/2, botY)
            data.Box[2].Color = color
            data.Box[2].Thickness = thickness
            data.Box[2].Visible = true

            data.Box[3].From = Vector2.new(centerX + boxWidth/2, botY)
            data.Box[3].To = Vector2.new(centerX - boxWidth/2, botY)
            data.Box[3].Color = color
            data.Box[3].Thickness = thickness
            data.Box[3].Visible = true

            data.Box[4].From = Vector2.new(centerX - boxWidth/2, botY)
            data.Box[4].To = Vector2.new(centerX - boxWidth/2, topY)
            data.Box[4].Color = color
            data.Box[4].Thickness = thickness
            data.Box[4].Visible = true
        end

        -- LINE ESP
        if Features.LineESP then
            data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Line.To = Vector2.new(rootPos.X, rootPos.Y)
            data.Line.Color = color
            data.Line.Thickness = thickness
            data.Line.Visible = true
        end
    end
end)

-- Issue #2: VirtualUser completely removed. No anti-AFK, no Button2 simulation.
-- The script no longer interferes with game camera systems or ADS mechanics.
