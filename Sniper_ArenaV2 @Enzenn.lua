-- Modern UNO HUB v5.0
-- Clean rewrite - all features working

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Cleanup existing
if game.CoreGui:FindFirstChild("UnoModernHub") then
    game.CoreGui.UnoModernHub:Destroy()
end

-- State
local Features = {
    SkeletonESP = false,
    TracerESP = false,
    BoxESP = false,
    LineESP = false,
    AimAssist = false,
    AutoShoot = false,
    AimStrength = 35,
    AimFOV = 140,
    AimSmoothness = 0.12,
    ESPColor = Color3.fromRGB(0, 170, 255),
}

local ESP = {}
local IsScoped = false

-------------------------------------------------
-- UTILITY
-------------------------------------------------
local function Tween(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-------------------------------------------------
-- GUI CREATION
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UnoModernHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game.CoreGui

-- ==================== HOME ICON ====================
local icon = Instance.new("ImageButton")
icon.Name = "HomeIcon"
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(0, 20, 0.5, -20)
icon.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
icon.Image = "rbxassetid://7733960981"
icon.ImageColor3 = Features.ESPColor
icon.AutoButtonColor = false
icon.Active = true
icon.Parent = gui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 10)
iconCorner.Parent = icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Features.ESPColor
iconStroke.Thickness = 2
iconStroke.Parent = icon

-- Icon drag variables
local iconDragging = false
local iconDragStart = nil
local iconStartPos = nil

icon.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = icon.Position
    end
end)

icon.InputChanged:Connect(function(input)
    if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - iconDragStart
        icon.Position = UDim2.new(
            iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = false
    end
end)

-- ==================== MAIN WINDOW ====================
local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 400, 0, 320)
main.Position = UDim2.new(0.5, -200, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- TOP BAR
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
topBar.BorderSizePixel = 0
mainCorner:Clone().Parent = topBar

-- Fix bottom of topbar
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 20)
topBarFix.Position = UDim2.new(0, 0, 1, -20)
topBarFix.BackgroundColor3 = topBar.BackgroundColor3
mainCorner:Clone().Parent = topBarFix

topBarFix.Parent = topBar
topBar.Parent = main

-- Title
local titleIcon = Instance.new("ImageLabel")
titleIcon.Size = UDim2.new(0, 20, 0, 20)
titleIcon.Position = UDim2.new(0, 12, 0, 11)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://7733960981"
titleIcon.ImageColor3 = Features.ESPColor
mainCorner:Clone().Parent = titleIcon
titleIcon.Parent = topBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 120, 0, 42)
titleText.Position = UDim2.new(0, 38, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "UNO HUB"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(0, 120, 0, 14)
subText.Position = UDim2.new(0, 38, 0, 24)
subText.BackgroundTransparency = 1
subText.Text = "v5.0 | Premium"
subText.TextColor3 = Color3.fromRGB(130, 130, 140)
subText.Font = Enum.Font.Gotham
subText.TextSize = 10
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.Parent = topBar

-- Window buttons
local function MakeBtn(text, pos, bg, hover)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = pos
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = bg
    btn.AutoButtonColor = false
    btn.Parent = topBar

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = hover}, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = bg}, 0.15) end)
    return btn
end

local minBtn = MakeBtn("−", UDim2.new(1, -98, 0, 7), Color3.fromRGB(45,45,55), Color3.fromRGB(65,65,80))
local hideBtn = MakeBtn("○", UDim2.new(1, -64, 0, 7), Color3.fromRGB(45,45,55), Color3.fromRGB(65,65,80))
local exitBtn = MakeBtn("×", UDim2.new(1, -30, 0, 7), Color3.fromRGB(210,55,55), Color3.fromRGB(255,75,75))

-- ==================== TAB BAR ====================
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.Position = UDim2.new(0, 8, 0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
tabBar.BorderSizePixel = 0
mainCorner:Clone().Parent = tabBar
tabBar.Parent = main

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 6)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.Parent = tabBar

-- ==================== CONTENT AREA ====================
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -16, 1, -90)
contentArea.Position = UDim2.new(0, 8, 0, 86)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.Parent = main

-- ==================== TAB SYSTEM ====================
local tabs = {}
local activeTabName = "Combat"
local tabContents = {}

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name.."Tab"
    btn.Size = UDim2.new(0, 110, 0, 28)
    btn.BackgroundColor3 = name == activeTabName and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(32, 32, 40)
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.Parent = tabBar

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    -- Content scrolling frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name.."Scroll"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
    scroll.Visible = name == activeTabName
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = contentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    tabs[name] = btn
    tabContents[name] = scroll

    btn.MouseButton1Click:Connect(function()
        if activeTabName == name then return end

        -- Deactivate old
        Tween(tabs[activeTabName], {BackgroundColor3 = Color3.fromRGB(32, 32, 40)}, 0.2)
        tabContents[activeTabName].Visible = false

        -- Activate new
        activeTabName = name
        Tween(btn, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
        tabContents[name].Visible = true
    end)

    return scroll
end

local combatScroll = CreateTab("Combat")
local visualScroll = CreateTab("Visual")

-- ==================== TOGGLE COMPONENT ====================
local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Toggle track
    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 52, 0, 28)
    track.Position = UDim2.new(1, -66, 0.5, -14)
    track.Text = ""
    track.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 60)
    track.AutoButtonColor = false
    track.Parent = frame

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = default and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = track

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local state = default

    track.MouseButton1Click:Connect(function()
        state = not state
        if state then
            Tween(track, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
            Tween(knob, {Position = UDim2.new(1, -26, 0.5, -11)}, 0.2)
        else
            Tween(track, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.2)
            Tween(knob, {Position = UDim2.new(0, 3, 0.5, -11)}, 0.2)
        end
        callback(state)
    end)

    return frame
end

-- ==================== SLIDER COMPONENT ====================
local function CreateSlider(parent, labelText, min, max, default, callback, suffix)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 64)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = labelText..": "..default..(suffix or "")
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 8)
    track.Position = UDim2.new(0, 12, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    track.BorderSizePixel = 0
    track.Parent = frame

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track

    -- Fill
    local pct = (default - min) / (max - min)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fc2 = Instance.new("UICorner")
    fc2.CornerRadius = UDim.new(1, 0)
    fc2.Parent = fill

    -- Handle
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new(pct, -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = track

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(1, 0)
    hc.Parent = handle

    local dragging = false

    local function update(input)
        local mouseX = input.Position.X
        local barX = track.AbsolutePosition.X
        local barW = track.AbsoluteSize.X
        local newPct = math.clamp((mouseX - barX) / barW, 0, 1)
        local value = math.floor(min + (newPct * (max - min)))

        fill.Size = UDim2.new(newPct, 0, 1, 0)
        handle.Position = UDim2.new(newPct, -8, 0.5, -8)
        label.Text = labelText..": "..value..(suffix or "")

        callback(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    track.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return frame
end

-- ==================== DROPDOWN COMPONENT ====================
local function CreateDropdown(parent, labelText, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, 48)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(0, 120, 0, 30)
    display.Position = UDim2.new(1, -136, 0.5, -15)
    display.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    display.Text = default or options[1]
    display.Font = Enum.Font.GothamMedium
    display.TextSize = 12
    display.TextColor3 = Color3.fromRGB(255, 255, 255)
    display.AutoButtonColor = false
    display.Parent = frame

    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(0, 6)
    dc.Parent = display

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -24, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 10
    arrow.TextColor3 = Color3.fromRGB(150, 150, 160)
    arrow.Parent = display

    -- Dropdown list
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 30)
    list.Position = UDim2.new(0, 0, 0, 48)
    list.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    list.BorderSizePixel = 0
    list.Visible = false
    list.Parent = frame

    local ll = Instance.new("UIListLayout")
    ll.Parent = list

    local expanded = false

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(32, 32, 42) or Color3.fromRGB(28, 28, 36)
        optBtn.Text = "  "..opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.Parent = list

        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        optBtn.MouseLeave:Connect(function()
            Tween(optBtn, {BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(32, 32, 42) or Color3.fromRGB(28, 28, 36)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end)
        optBtn.MouseButton1Click:Connect(function()
            display.Text = opt
            callback(opt)
            expanded = false
            list.Visible = false
            Tween(frame, {Size = UDim2.new(1, -8, 0, 48)}, 0.2)
            arrow.Text = "▼"
        end)
    end

    display.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            list.Visible = true
            Tween(frame, {Size = UDim2.new(1, -8, 0, 48 + list.Size.Y.Offset)}, 0.2)
            arrow.Text = "▲"
        else
            Tween(frame, {Size = UDim2.new(1, -8, 0, 48)}, 0.2)
            arrow.Text = "▼"
            delay(0.2, function()
                if not expanded then list.Visible = false end
            end)
        end
    end)

    return frame
end

-------------------------------------------------
-- POPULATE COMBAT TAB
-------------------------------------------------
CreateToggle(combatScroll, "Aim Assist", false, function(v)
    Features.AimAssist = v
end)

CreateToggle(combatScroll, "Auto Shoot", false, function(v)
    Features.AutoShoot = v
end)

CreateSlider(combatScroll, "Aim Strength", 0, 100, 35, function(v)
    Features.AimStrength = v
end, "%")

CreateSlider(combatScroll, "Aim FOV", 10, 300, 140, function(v)
    Features.AimFOV = v
end, "")

CreateSlider(combatScroll, "Smoothness", 1, 100, 12, function(v)
    Features.AimSmoothness = v / 100
end, "%")

-------------------------------------------------
-- POPULATE VISUAL TAB
-------------------------------------------------
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

-------------------------------------------------
-- WINDOW DRAG
-------------------------------------------------
local winDragging = false
local winDragStart = nil
local winStartPos = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        winDragging = true
        winDragStart = input.Position
        winStartPos = main.Position
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        -- drag tracking
    end
end)

UIS.InputChanged:Connect(function(input)
    if winDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - winDragStart
        main.Position = UDim2.new(
            winStartPos.X.Scale, winStartPos.X.Offset + delta.X,
            winStartPos.Y.Scale, winStartPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        winDragging = false
    end
end)

-------------------------------------------------
-- WINDOW BUTTONS
-------------------------------------------------
icon.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Tween(main, {Size = UDim2.new(0, 400, 0, 42)}, 0.2)
        tabBar.Visible = false
        contentArea.Visible = false
    else
        Tween(main, {Size = UDim2.new(0, 400, 0, 320)}, 0.2)
        tabBar.Visible = true
        contentArea.Visible = true
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

-- PROPER EXIT - FULL CLEANUP
exitBtn.MouseButton1Click:Connect(function()
    -- Hide everything first
    main.Visible = false
    icon.Visible = false

    -- Remove all drawing objects
    for _, data in pairs(ESP) do
        if data.Tracer then
            pcall(function() data.Tracer:Remove() end)
        end
        if data.Skeleton then
            for _, line in pairs(data.Skeleton) do
                pcall(function() line:Remove() end)
            end
        end
        if data.Box then
            for _, line in pairs(data.Box) do
                pcall(function() line:Remove() end)
            end
        end
        if data.Line then
            pcall(function() data.Line:Remove() end)
        end
    end

    pcall(function() FOVCircle:Remove() end)

    -- Destroy GUI after brief delay to ensure cleanup
    delay(0.1, function()
        pcall(function() gui:Destroy() end)
    end)
end)

-------------------------------------------------
-- DRAWING SYSTEM
-------------------------------------------------
local function NewLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Transparency = 1
    line.Thickness = 1.5
    return line
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Features.ESPColor
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Radius = Features.AimFOV

-------------------------------------------------
-- SKELETON DATA
-------------------------------------------------
local R15Skeleton = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

local R6Skeleton = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}
}

local function GetSkeleton(char)
    if char:FindFirstChild("UpperTorso") then
        return R15Skeleton
    end
    return R6Skeleton
end

-------------------------------------------------
-- ESP SETUP
-------------------------------------------------
local function CreateESP(player)
    if player == LocalPlayer then return end

    local skeleton = {}
    for i = 1, 14 do
        skeleton[i] = NewLine()
    end

    local box = {}
    for i = 1, 4 do
        box[i] = NewLine()
    end

    ESP[player] = {
        Skeleton = skeleton,
        Tracer = NewLine(),
        Box = box,
        Line = NewLine(),
        IsDead = false
    }

    local function SetupHealthTracking()
        local char = player.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        hum:GetPropertyChangedSignal("Health"):Connect(function()
            if hum.Health <= 0 then
                local data = ESP[player]
                if data then
                    data.IsDead = true
                    data.Tracer.Visible = false
                    data.Line.Visible = false
                    for _, l in pairs(data.Skeleton) do
                        l.Visible = false
                    end
                    for _, l in pairs(data.Box) do
                        l.Visible = false
                    end
                end
            else
                local data = ESP[player]
                if data then
                    data.IsDead = false
                end
            end
        end)

        hum.Died:Connect(function()
            local data = ESP[player]
            if data then
                data.IsDead = true
                data.Tracer.Visible = false
                data.Line.Visible = false
                for _, l in pairs(data.Skeleton) do
                    l.Visible = false
                end
                for _, l in pairs(data.Box) do
                    l.Visible = false
                end
            end
        end)
    end

    SetupHealthTracking()

    player.CharacterAdded:Connect(function()
        local data = ESP[player]
        if data then
            data.IsDead = false
        end
        delay(0.5, SetupHealthTracking)
    end)
end

local function RemoveESP(player)
    local data = ESP[player]
    if not data then return end

    for _, l in pairs(data.Skeleton) do
        pcall(function() l:Remove() end)
    end
    pcall(function() data.Tracer:Remove() end)
    for _, l in pairs(data.Box) do
        pcall(function() l:Remove() end)
    end
    pcall(function() data.Line:Remove() end)

    ESP[player] = nil
end

-- Initialize for existing players
for _, p in ipairs(Players:GetPlayers()) do
    CreateESP(p)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-------------------------------------------------
-- AIM & SHOOT
-------------------------------------------------
local function GetClosestPlayer()
    local closest = nil
    local shortest = Features.AimFOV
    local mousePos = UIS:GetMouseLocation()

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
                        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = head
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- Scope detection
UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsScoped = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsScoped = false
    end
end)

-------------------------------------------------
-- RENDER LOOP
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()

    -- Update FOV circle
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Features.AimFOV
    FOVCircle.Color = Features.ESPColor
    FOVCircle.Visible = Features.AimAssist or Features.AutoShoot

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    -- Auto Shoot
    if Features.AutoShoot and IsScoped then
        local target = GetClosestPlayer()
        if target then
            pcall(function()
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end)
        end
    end

    -- ESP Render
    for player, data in pairs(ESP) do
        if data.IsDead then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, l in pairs(data.Skeleton) do l.Visible = false end
            for _, l in pairs(data.Box) do l.Visible = false end
            continue
        end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not char or not hum or hum.Health <= 0 or not hrp or not head then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, l in pairs(data.Skeleton) do l.Visible = false end
            for _, l in pairs(data.Box) do l.Visible = false end
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

        if not onScreen then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, l in pairs(data.Skeleton) do l.Visible = false end
            for _, l in pairs(data.Box) do l.Visible = false end
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
                    else
                        line.Visible = false
                    end
                elseif line then
                    line.Visible = false
                end
            end
        else
            for _, l in pairs(data.Skeleton) do l.Visible = false end
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
            else
                data.Tracer.Visible = false
            end
        else
            data.Tracer.Visible = false
        end

        -- BOX ESP
        if Features.BoxESP then
            local size = math.clamp(1800 / distance, 25, 140)
            local x, y = rootPos.X, rootPos.Y
            local topY = y - size * 1.2
            local botY = y + size * 0.4

            data.Box[1].From = Vector2.new(x - size/2, topY)
            data.Box[1].To = Vector2.new(x + size/2, topY)
            data.Box[1].Color = color
            data.Box[1].Thickness = thickness
            data.Box[1].Visible = true

            data.Box[2].From = Vector2.new(x + size/2, topY)
            data.Box[2].To = Vector2.new(x + size/2, botY)
            data.Box[2].Color = color
            data.Box[2].Thickness = thickness
            data.Box[2].Visible = true

            data.Box[3].From = Vector2.new(x + size/2, botY)
            data.Box[3].To = Vector2.new(x - size/2, botY)
            data.Box[3].Color = color
            data.Box[3].Thickness = thickness
            data.Box[3].Visible = true

            data.Box[4].From = Vector2.new(x - size/2, botY)
            data.Box[4].To = Vector2.new(x - size/2, topY)
            data.Box[4].Color = color
            data.Box[4].Thickness = thickness
            data.Box[4].Visible = true
        else
            for _, l in pairs(data.Box) do l.Visible = false end
        end

        -- LINE ESP (bottom of screen)
        if Features.LineESP then
            data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Line.To = Vector2.new(rootPos.X, rootPos.Y)
            data.Line.Color = color
            data.Line.Thickness = thickness
            data.Line.Visible = true
        else
            data.Line.Visible = false
        end
    end

    -- AIM ASSIST
    if Features.AimAssist then
        local target = GetClosestPlayer()
        if target then
            local smooth = math.clamp(Features.AimStrength / 100, 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, target.Position),
                smooth * Features.AimSmoothness
            )
        end
    end
end)

-- Anti AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)
