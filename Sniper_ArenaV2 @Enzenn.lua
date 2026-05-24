-- Modern UNO HUB v4.0
-- Fixed: Toggle visibility, content layout, icon sizing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if game.CoreGui:FindFirstChild("UnoModernHub") then
    game.CoreGui.UnoModernHub:Destroy()
end

local ESP = {}
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
    IsDead = false
}

-------------------------------------------------
-- UTILITIES
-------------------------------------------------
local function Tween(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-------------------------------------------------
-- GUI SETUP
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UnoModernHub"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- SMALL MOVABLE HOME ICON (36x36)
local icon = Instance.new("ImageButton")
icon.Name = "MenuIcon"
icon.Size = UDim2.new(0, 36, 0, 36)
icon.Position = UDim2.new(0, 15, 0.5, -18)
icon.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
icon.Image = "rbxassetid://7733960981"
icon.ImageColor3 = Features.ESPColor
icon.AutoButtonColor = false
icon.ZIndex = 100
icon.Parent = gui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 10)
iconCorner.Parent = icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Features.ESPColor
iconStroke.Thickness = 2
iconStroke.Parent = icon

-- Icon Draggable
local iconDragging = false
local iconDragInput, iconDragStart, iconStartPos

icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = icon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragging = false
            end
        end)
    end
end)

icon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        iconDragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == iconDragInput and iconDragging then
        local delta = input.Position - iconDragStart
        icon.Position = UDim2.new(
            iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
        )
    end
end)

-- MAIN WINDOW
local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 420, 0, 340)
main.Position = UDim2.new(0.5, -210, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.ZIndex = 50
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(40, 40, 50)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- TOP BAR
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
topBar.BorderSizePixel = 0
topBar.ZIndex = 51
topBar.Parent = main

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 16)
topBarCorner.Parent = topBar

-- Fix bottom corners of top bar
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 16)
topBarFix.Position = UDim2.new(0, 0, 1, -16)
topBarFix.BackgroundColor3 = topBar.BackgroundColor3
topBarFix.BorderSizePixel = 0
topBarFix.ZIndex = 51
topBarFix.Parent = topBar

-- Title
local titleIcon = Instance.new("ImageLabel")
titleIcon.Size = UDim2.new(0, 22, 0, 22)
titleIcon.Position = UDim2.new(0, 12, 0, 11)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://7733960981"
titleIcon.ImageColor3 = Features.ESPColor
titleIcon.ZIndex = 52
titleIcon.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 120, 0, 44)
title.Position = UDim2.new(0, 40, 0, 0)
title.BackgroundTransparency = 1
title.Text = "UNO HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 52
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 120, 0, 14)
subtitle.Position = UDim2.new(0, 40, 0, 26)
subtitle.BackgroundTransparency = 1
subtitle.Text = "v4.0 | Ultimate"
subtitle.TextColor3 = Color3.fromRGB(120, 120, 130)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 52
subtitle.Parent = topBar

-- Window Buttons
local function WinBtn(text, pos, color, hover)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = pos
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.AutoButtonColor = false
    btn.ZIndex = 52
    btn.Parent = topBar

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = hover}, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = color}, 0.15) end)
    return btn
end

local minBtn = WinBtn("−", UDim2.new(1, -100, 0, 8), Color3.fromRGB(45,45,55), Color3.fromRGB(60,60,75))
local hidBtn = WinBtn("○", UDim2.new(1, -66, 0, 8), Color3.fromRGB(45,45,55), Color3.fromRGB(60,60,75))
local exBtn = WinBtn("×", UDim2.new(1, -32, 0, 8), Color3.fromRGB(220,60,60), Color3.fromRGB(255,80,80))

-------------------------------------------------
-- TAB BAR
-------------------------------------------------
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 34)
tabBar.Position = UDim2.new(0, 10, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 50
tabBar.Parent = main

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 10)
tabBarCorner.Parent = tabBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabBar

local tabs = {}
local activeTab = "Combat"
local tabContents = {}

local function CreateTab(name, iconId)
    local tab = Instance.new("TextButton")
    tab.Name = name.."Tab"
    tab.Size = UDim2.new(0, 90, 0, 28)
    tab.BackgroundColor3 = name == activeTab and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(28, 28, 36)
    tab.Text = "  "..name
    tab.Font = Enum.Font.GothamSemibold
    tab.TextSize = 12
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.AutoButtonColor = false
    tab.ZIndex = 51
    tab.Parent = tabBar

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = tab

    local tIcon = Instance.new("ImageLabel")
    tIcon.Size = UDim2.new(0, 14, 0, 14)
    tIcon.Position = UDim2.new(0, 8, 0.5, -7)
    tIcon.BackgroundTransparency = 1
    tIcon.Image = iconId or "rbxassetid://7733960981"
    tIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    tIcon.ZIndex = 52
    tIcon.Parent = tab

    -- CONTENT FRAME (FIXED: proper sizing and visibility)
    local content = Instance.new("Frame")
    content.Name = name.."Content"
    content.Size = UDim2.new(1, -20, 1, -96)
    content.Position = UDim2.new(0, 10, 0, 90)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Visible = name == activeTab
    content.ZIndex = 50
    content.Parent = main
    content.ClipsDescendants = true

    -- Scroll frame inside content
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Features.ESPColor
    scroll.ZIndex = 50
    scroll.Parent = content
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.Padding = UDim.new(0, 8)
    scrollLayout.Parent = scroll

    scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
    end)

    tabContents[name] = content
    tabs[name] = tab

    tab.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        Tween(tabs[activeTab], {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}, 0.2)
        tabContents[activeTab].Visible = false
        activeTab = name
        Tween(tab, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
        tabContents[name].Visible = true
    end)

    return scroll
end

local combatTab = CreateTab("Combat", "rbxassetid://7733673987")
local visualTab = CreateTab("Visual", "rbxassetid://7734052925")
local playerTab = CreateTab("Player", "rbxassetid://7733955511")
local settingsTab = CreateTab("Settings", "rbxassetid://7734115589")

-------------------------------------------------
-- TOGGLE COMPONENT (FIXED VISIBILITY)
-------------------------------------------------
local function CreateToggle(parent, name, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 46)
    holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    holder.BorderSizePixel = 0
    holder.ZIndex = 55
    holder.Parent = parent

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 10)
    hc.Parent = holder

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 56
    label.Parent = holder

    -- Toggle Background
    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 50, 0, 26)
    toggleBg.Position = UDim2.new(1, -64, 0.5, -13)
    toggleBg.Text = ""
    toggleBg.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(45, 45, 55)
    toggleBg.AutoButtonColor = false
    toggleBg.ZIndex = 56
    toggleBg.Parent = holder

    local tbc = Instance.new("UICorner")
    tbc.CornerRadius = UDim.new(1, 0)
    tbc.Parent = toggleBg

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.ZIndex = 57
    knob.Parent = toggleBg

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local state = default

    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        if state then
            Tween(toggleBg, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
            Tween(knob, {Position = UDim2.new(1, -24, 0.5, -10)}, 0.2)
        else
            Tween(toggleBg, {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}, 0.2)
            Tween(knob, {Position = UDim2.new(0, 4, 0.5, -10)}, 0.2)
        end
        callback(state)
    end)

    return holder
end

-------------------------------------------------
-- SLIDER COMPONENT
-------------------------------------------------
local function CreateSlider(parent, name, min, max, default, callback, suffix)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 62)
    holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    holder.BorderSizePixel = 0
    holder.ZIndex = 55
    holder.Parent = parent

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 10)
    hc.Parent = holder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name..": "..default..(suffix or "")
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 56
    label.Parent = holder

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 8)
    sliderBg.Position = UDim2.new(0, 12, 0, 38)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 56
    sliderBg.Parent = holder

    local sbc = Instance.new("UICorner")
    sbc.CornerRadius = UDim.new(1, 0)
    sbc.Parent = sliderBg

    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Features.ESPColor
    fill.BorderSizePixel = 0
    fill.ZIndex = 57
    fill.Parent = sliderBg

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new(pct, -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.ZIndex = 58
    handle.Parent = sliderBg

    local hc2 = Instance.new("UICorner")
    hc2.CornerRadius = UDim.new(1, 0)
    hc2.Parent = handle

    local dragging = false

    local function update(input)
        local mx = input.Position.X
        local px = sliderBg.AbsolutePosition.X
        local sx = sliderBg.AbsoluteSize.X
        local newPct = math.clamp((mx - px) / sx, 0, 1)
        local val = math.floor(min + (newPct * (max - min)))
        fill.Size = UDim2.new(newPct, 0, 1, 0)
        handle.Position = UDim2.new(newPct, -8, 0.5, -8)
        label.Text = name..": "..val..(suffix or "")
        callback(val)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    sliderBg.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return holder
end

-------------------------------------------------
-- DROPDOWN COMPONENT
-------------------------------------------------
local function CreateDropdown(parent, name, options, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 46)
    holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.ZIndex = 55
    holder.Parent = parent

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 10)
    hc.Parent = holder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, 46)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 56
    label.Parent = holder

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(0, 120, 0, 30)
    display.Position = UDim2.new(1, -136, 0.5, -15)
    display.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    display.Text = default or options[1]
    display.Font = Enum.Font.GothamMedium
    display.TextSize = 12
    display.TextColor3 = Color3.fromRGB(255, 255, 255)
    display.AutoButtonColor = false
    display.ZIndex = 56
    display.Parent = holder

    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(0, 6)
    dc.Parent = display

    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 14, 0, 14)
    arrow.Position = UDim2.new(1, -22, 0.5, -7)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://7733717447"
    arrow.ImageColor3 = Color3.fromRGB(150, 150, 160)
    arrow.ZIndex = 57
    arrow.Parent = display

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 32)
    list.Position = UDim2.new(0, 0, 0, 46)
    list.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 60
    list.Parent = holder

    local ll = Instance.new("UIListLayout")
    ll.Parent = list

    local expanded = false

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 32)
        ob.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(28, 28, 36) or Color3.fromRGB(25, 25, 32)
        ob.Text = "  "..opt
        ob.Font = Enum.Font.Gotham
        ob.TextSize = 12
        ob.TextColor3 = Color3.fromRGB(200, 200, 210)
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.AutoButtonColor = false
        ob.ZIndex = 61
        ob.Parent = list

        ob.MouseEnter:Connect(function()
            Tween(ob, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.1)
            ob.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        ob.MouseLeave:Connect(function()
            Tween(ob, {BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(28, 28, 36) or Color3.fromRGB(25, 25, 32)}, 0.1)
            ob.TextColor3 = Color3.fromRGB(200, 200, 210)
        end)
        ob.MouseButton1Click:Connect(function()
            display.Text = opt
            callback(opt)
            expanded = false
            list.Visible = false
            Tween(holder, {Size = UDim2.new(1, 0, 0, 46)}, 0.2)
            arrow.Rotation = 0
        end)
    end

    display.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            list.Visible = true
            Tween(holder, {Size = UDim2.new(1, 0, 0, 46 + list.Size.Y.Offset)}, 0.2)
            arrow.Rotation = 180
        else
            Tween(holder, {Size = UDim2.new(1, 0, 0, 46)}, 0.2)
            arrow.Rotation = 0
            delay(0.2, function() if not expanded then list.Visible = false end end)
        end
    end)

    return holder
end

-------------------------------------------------
-- POPULATE TABS
-------------------------------------------------

-- COMBAT TAB
CreateToggle(combatTab, "Aim Assist", false, function(v) Features.AimAssist = v end)
CreateToggle(combatTab, "Auto Shoot", false, function(v) Features.AutoShoot = v end)
CreateSlider(combatTab, "Aim Strength", 0, 100, 35, function(v) Features.AimStrength = v end, "%")
CreateSlider(combatTab, "Aim FOV", 10, 300, 140, function(v) Features.AimFOV = v end, "")
CreateSlider(combatTab, "Smoothness", 1, 100, 12, function(v) Features.AimSmoothness = v / 100 end, "%")

-- VISUAL TAB
CreateToggle(visualTab, "Skeleton ESP", false, function(v) Features.SkeletonESP = v end)
CreateToggle(visualTab, "Tracer ESP", false, function(v) Features.TracerESP = v end)
CreateToggle(visualTab, "Box ESP", false, function(v) Features.BoxESP = v end)
CreateToggle(visualTab, "Line ESP", false, function(v) Features.LineESP = v end)
CreateSlider(visualTab, "Line Thickness", 1, 5, 2, function(v) end, "")
CreateDropdown(visualTab, "ESP Color", {"Cyan", "Red", "Green", "Purple", "Yellow", "White"}, "Cyan", function(v)
    local colors = {Cyan = Color3.fromRGB(0,170,255), Red = Color3.fromRGB(255,60,60), Green = Color3.fromRGB(60,255,120), Purple = Color3.fromRGB(180,60,255), Yellow = Color3.fromRGB(255,220,60), White = Color3.fromRGB(255,255,255)}
    Features.ESPColor = colors[v] or colors.Cyan
    FOVCircle.Color = Features.ESPColor
    iconStroke.Color = Features.ESPColor
    titleIcon.ImageColor3 = Features.ESPColor
end)

-- PLAYER TAB
CreateToggle(playerTab, "Auto Collect", false, function(v) end)
CreateToggle(playerTab, "Plant On Click", false, function(v) end)
CreateToggle(playerTab, "Auto Sell", false, function(v) end)
CreateDropdown(playerTab, "Select Fruit", {"Tomato", "Carrot", "Corn", "Wheat", "Pumpkin"}, "Tomato", function(v) end)

-- SETTINGS TAB
CreateToggle(settingsTab, "Anti AFK", true, function(v) end)
CreateToggle(settingsTab, "Stream Mode", false, function(v) gui.Enabled = not v end)

-------------------------------------------------
-- WINDOW DRAG
-------------------------------------------------
local dragging = false
local dragInput, dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
        Tween(main, {Size = UDim2.new(0, 420, 0, 44)}, 0.2)
        for _, c in ipairs(main:GetChildren()) do
            if c.Name ~= "TopBar" and c ~= topBarFix then c.Visible = false end
        end
    else
        Tween(main, {Size = UDim2.new(0, 420, 0, 340)}, 0.2)
        for _, c in ipairs(main:GetChildren()) do
            if c.Name ~= "Shadow" then c.Visible = true end
        end
        for n, content in pairs(tabContents) do content.Visible = (n == activeTab) end
    end
end)

hidBtn.MouseButton1Click:Connect(function() main.Visible = false end)

exBtn.MouseButton1Click:Connect(function()
    for _, data in pairs(ESP) do
        if data.Tracer then data.Tracer:Remove() end
        if data.Skeleton then for _, l in pairs(data.Skeleton) do l:Remove() end end
        if data.Box then for _, l in pairs(data.Box) do l:Remove() end end
        if data.Line then data.Line:Remove() end
    end
    FOVCircle:Remove()
    gui:Destroy()
end)

-------------------------------------------------
-- DRAWING SYSTEM
-------------------------------------------------
local function NewLine()
    local l = Drawing.new("Line")
    l.Visible = false
    l.Transparency = 1
    l.Thickness = 1.5
    return l
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Features.ESPColor
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Radius = Features.AimFOV

-------------------------------------------------
-- SKELETON DEFS
-------------------------------------------------
local R15Skeleton = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}
local R6Skeleton = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local function GetSkeleton(char)
    return char:FindFirstChild("UpperTorso") and R15Skeleton or R6Skeleton
end

-------------------------------------------------
-- ESP MANAGEMENT
-------------------------------------------------
local function CreateESP(player)
    if player == LocalPlayer then return end

    local skeleton = {}
    for i = 1, 14 do skeleton[i] = NewLine() end

    local box = {}
    for i = 1, 4 do box[i] = NewLine() end

    ESP[player] = {
        Skeleton = skeleton,
        Tracer = NewLine(),
        Box = box,
        Line = NewLine(),
        IsDead = false
    }

    local function trackHealth()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.HealthChanged:Connect(function(health)
                if health <= 0 then
                    ESP[player].IsDead = true
                    ESP[player].Tracer.Visible = false
                    ESP[player].Line.Visible = false
                    for _, l in pairs(ESP[player].Skeleton) do l.Visible = false end
                    for _, l in pairs(ESP[player].Box) do l.Visible = false end
                else
                    ESP[player].IsDead = false
                end
            end)
            hum.Died:Connect(function()
                ESP[player].IsDead = true
                ESP[player].Tracer.Visible = false
                ESP[player].Line.Visible = false
                for _, l in pairs(ESP[player].Skeleton) do l.Visible = false end
                for _, l in pairs(ESP[player].Box) do l.Visible = false end
            end)
        end
    end

    trackHealth()
    player.CharacterAdded:Connect(function()
        ESP[player].IsDead = false
        delay(0.5, trackHealth)
    end)
end

local function RemoveESP(player)
    local data = ESP[player]
    if not data then return end
    for _, l in pairs(data.Skeleton) do l:Remove() end
    data.Tracer:Remove()
    for _, l in pairs(data.Box) do l:Remove() end
    data.Line:Remove()
    ESP[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-------------------------------------------------
-- AIM & AUTO SHOOT
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
            if hum and hum.Health > 0 and head and ESP[p] and not ESP[p].IsDead then
                local pos, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

local IsScoped = false
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then IsScoped = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then IsScoped = false end
end)

-------------------------------------------------
-- RENDER LOOP
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()

    FOVCircle.Position = mousePos
    FOVCircle.Radius = Features.AimFOV
    FOVCircle.Color = Features.ESPColor
    FOVCircle.Visible = Features.AimAssist or Features.AutoShoot

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    -- Auto Shoot
    if Features.AutoShoot and IsScoped then
        local t = GetClosestPlayer()
        if t then
            pcall(function()
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end)
        end
    end

    for player, data in pairs(ESP) do
        if data.IsDead then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
            for _, l in pairs(data.Box) do if l then l.Visible = false end end
            continue
        end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not char or not hum or hum.Health <= 0 or not hrp or not head then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
            for _, l in pairs(data.Box) do if l then l.Visible = false end end
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
            for _, l in pairs(data.Box) do if l then l.Visible = false end end
            continue
        end

        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        local thick = math.clamp(3.5 - (dist / 300), 1, 3.5)
        local color = Features.ESPColor

        -- SKELETON
        if Features.SkeletonESP and not data.IsDead then
            local conns = GetSkeleton(char)
            for i, bones in ipairs(conns) do
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
                        line.Thickness = thick
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                elseif line then
                    line.Visible = false
                end
            end
        else
            for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
        end

        -- TRACER
        if Features.TracerESP and myRoot and not data.IsDead then
            local myPos, myVis = Camera:WorldToViewportPoint(myRoot.Position + Vector3.new(0, 2, 0))
            if myVis then
                data.Tracer.From = Vector2.new(myPos.X, myPos.Y)
                data.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                data.Tracer.Color = color
                data.Tracer.Thickness = thick
                data.Tracer.Visible = true
            else
                data.Tracer.Visible = false
            end
        else
            data.Tracer.Visible = false
        end

        -- BOX ESP
        if Features.BoxESP and not data.IsDead then
            local size = math.clamp(2000 / dist, 30, 150)
            local x, y = rootPos.X, rootPos.Y
            local topY = y - size * 1.3
            local botY = y + size * 0.5

            data.Box[1].From = Vector2.new(x - size/2, topY)
            data.Box[1].To = Vector2.new(x + size/2, topY)
            data.Box[1].Color = color
            data.Box[1].Thickness = thick
            data.Box[1].Visible = true

            data.Box[2].From = Vector2.new(x + size/2, topY)
            data.Box[2].To = Vector2.new(x + size/2, botY)
            data.Box[2].Color = color
            data.Box[2].Thickness = thick
            data.Box[2].Visible = true

            data.Box[3].From = Vector2.new(x + size/2, botY)
            data.Box[3].To = Vector2.new(x - size/2, botY)
            data.Box[3].Color = color
            data.Box[3].Thickness = thick
            data.Box[3].Visible = true

            data.Box[4].From = Vector2.new(x - size/2, botY)
            data.Box[4].To = Vector2.new(x - size/2, topY)
            data.Box[4].Color = color
            data.Box[4].Thickness = thick
            data.Box[4].Visible = true
        else
            for _, l in pairs(data.Box) do if l then l.Visible = false end end
        end

        -- LINE ESP (bottom screen to player)
        if Features.LineESP and not data.IsDead then
            data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Line.To = Vector2.new(rootPos.X, rootPos.Y)
            data.Line.Color = color
            data.Line.Thickness = thick
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

-- Anti-AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)
