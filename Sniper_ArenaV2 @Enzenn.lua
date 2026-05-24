-- Modern UNO HUB v3.0
-- Full Feature Set: Box ESP, Line ESP, Skeleton, Tracer, Auto-Shoot, Movable Icon

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if game.CoreGui:FindFirstChild("UnoModernHub") then
    game.CoreGui.UnoModernHub:Destroy()
end

-- ESP Data Store
local ESP = {}

-- Feature States
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
    DeadESPColor = Color3.fromRGB(255, 50, 50)
}

-------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------

local function Tween(object, properties, duration)
    TweenService:Create(object, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

local function RoundCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = obj
    return corner
end

local function AddStroke(obj, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Features.ESPColor
    stroke.Thickness = thickness or 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = obj
    return stroke
end

local function AddShadow(obj)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://131604521"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = obj.ZIndex - 1
    shadow.Parent = obj
    return shadow
end

-------------------------------------------------
-- MAIN GUI SETUP
-------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "UnoModernHub"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Floating Toggle Icon (SMALLER: 40x40 instead of 50x50)
local icon = Instance.new("ImageButton")
icon.Name = "MenuIcon"
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(0, 20, 0.5, -20)
icon.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
icon.Image = "rbxassetid://7733960981"
icon.ImageColor3 = Features.ESPColor
icon.AutoButtonColor = false
icon.ZIndex = 100
icon.Parent = gui

RoundCorner(icon, 10)
AddStroke(icon, Features.ESPColor, 2)
AddShadow(icon)

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
            iconStartPos.X.Scale,
            iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale,
            iconStartPos.Y.Offset + delta.Y
        )
    end
end)

-- Main Window
local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = UDim2.new(0, 440, 0, 340)
main.Position = UDim2.new(0.5, -220, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.ZIndex = 50
main.Parent = gui

RoundCorner(main, 16)
AddStroke(main, Color3.fromRGB(40, 40, 50), 1.5)
AddShadow(main)

-- Title Bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
topBar.BorderSizePixel = 0
topBar.ZIndex = 51
topBar.Parent = main

RoundCorner(topBar, 16)

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 16)
topBarFix.Position = UDim2.new(0, 0, 1, -16)
topBarFix.BackgroundColor3 = topBar.BackgroundColor3
topBarFix.BorderSizePixel = 0
topBarFix.ZIndex = 51
topBarFix.Parent = topBar

local titleIcon = Instance.new("ImageLabel")
titleIcon.Size = UDim2.new(0, 24, 0, 24)
titleIcon.Position = UDim2.new(0, 14, 0, 10)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://7733960981"
titleIcon.ImageColor3 = Features.ESPColor
titleIcon.ZIndex = 52
titleIcon.Parent = topBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 120, 0, 44)
title.Position = UDim2.new(0, 44, 0, 0)
title.BackgroundTransparency = 1
title.Text = "UNO HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 52
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 120, 0, 16)
subtitle.Position = UDim2.new(0, 44, 0, 26)
subtitle.BackgroundTransparency = 1
subtitle.Text = "v3.0 | Ultimate"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 160)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 52
subtitle.Parent = topBar

-- Window Controls
local function CreateWindowButton(text, pos, color, hoverColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = pos
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.AutoButtonColor = false
    btn.ZIndex = 52
    btn.Parent = topBar

    RoundCorner(btn, 8)

    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = hoverColor}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = color}, 0.15)
    end)

    return btn
end

local minimizeBtn = CreateWindowButton("−", UDim2.new(1, -108, 0, 7), 
    Color3.fromRGB(45, 45, 55), Color3.fromRGB(60, 60, 75))
local hideBtn = CreateWindowButton("○", UDim2.new(1, -72, 0, 7), 
    Color3.fromRGB(45, 45, 55), Color3.fromRGB(60, 60, 75))
local exitBtn = CreateWindowButton("×", UDim2.new(1, -36, 0, 7), 
    Color3.fromRGB(220, 60, 60), Color3.fromRGB(255, 80, 80))

-------------------------------------------------
-- TAB SYSTEM
-------------------------------------------------

local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -20, 0, 36)
tabContainer.Position = UDim2.new(0, 10, 0, 50)
tabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
tabContainer.BorderSizePixel = 0
tabContainer.ZIndex = 50
tabContainer.Parent = main

RoundCorner(tabContainer, 10)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabContainer

local tabs = {}
local activeTab = "Combat"
local tabContents = {}

local function CreateTab(name, iconId)
    local tab = Instance.new("TextButton")
    tab.Name = name .. "Tab"
    tab.Size = UDim2.new(0, 95, 0, 30)
    tab.BackgroundColor3 = name == activeTab and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 38)
    tab.Text = "  " .. name
    tab.Font = Enum.Font.GothamSemibold
    tab.TextSize = 12
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.AutoButtonColor = false
    tab.ZIndex = 51
    tab.Parent = tabContainer

    RoundCorner(tab, 8)

    local tabIcon = Instance.new("ImageLabel")
    tabIcon.Size = UDim2.new(0, 16, 0, 16)
    tabIcon.Position = UDim2.new(0, 8, 0.5, -8)
    tabIcon.BackgroundTransparency = 1
    tabIcon.Image = iconId or "rbxassetid://7733960981"
    tabIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    tabIcon.ZIndex = 52
    tabIcon.Parent = tab

    local content = Instance.new("ScrollingFrame")
    content.Name = name .. "Content"
    content.Size = UDim2.new(1, -20, 1, -100)
    content.Position = UDim2.new(0, 10, 0, 92)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Features.ESPColor
    content.Visible = name == activeTab
    content.ZIndex = 50
    content.Parent = main
    content.CanvasSize = UDim2.new(0, 0, 0, 0)

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
    end)

    tabContents[name] = content
    tabs[name] = tab

    tab.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        Tween(tabs[activeTab], {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}, 0.2)
        tabContents[activeTab].Visible = false
        activeTab = name
        Tween(tab, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
        tabContents[name].Visible = true
    end)

    return content
end

local combatTab = CreateTab("Combat", "rbxassetid://7733673987")
local visualTab = CreateTab("Visual", "rbxassetid://7734052925")
local playerTab = CreateTab("Player", "rbxassetid://7733955511")
local settingsTab = CreateTab("Settings", "rbxassetid://7734115589")

-------------------------------------------------
-- MODERN TOGGLE
-------------------------------------------------

local function CreateModernToggle(parent, name, defaultState, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 44)
    holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    holder.BorderSizePixel = 0
    holder.Parent = parent

    RoundCorner(holder, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 48, 0, 26)
    toggleBg.Position = UDim2.new(1, -62, 0.5, -13)
    toggleBg.Text = ""
    toggleBg.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(45, 45, 55)
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = holder

    RoundCorner(toggleBg, 13)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = defaultState and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = toggleBg

    RoundCorner(knob, 10)

    local state = defaultState

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
-- MODERN SLIDER (0-100)
-------------------------------------------------

local function CreateModernSlider(parent, name, min, max, default, callback, showPercent)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 60)
    holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    holder.BorderSizePixel = 0
    holder.Parent = parent

    RoundCorner(holder, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default .. (showPercent and "%" or "")
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 8)
    sliderBg.Position = UDim2.new(0, 12, 0, 38)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = holder

    RoundCorner(sliderBg, 4)

    local fill = Instance.new("Frame")
    local percent = (default - min) / (max - min)
    fill.Size = UDim2.new(percent, 0, 1, 0)
    fill.BackgroundColor3 = Features.ESPColor
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg

    RoundCorner(fill, 4)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new(percent, -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.ZIndex = 2
    handle.Parent = sliderBg

    RoundCorner(handle, 8)

    local dragging = false

    local function updateSlider(input)
        local mouseX = input.Position.X
        local pos = sliderBg.AbsolutePosition.X
        local size = sliderBg.AbsoluteSize.X
        local newPercent = math.clamp((mouseX - pos) / size, 0, 1)
        local value = math.floor(min + (newPercent * (max - min)))

        fill.Size = UDim2.new(newPercent, 0, 1, 0)
        handle.Position = UDim2.new(newPercent, -8, 0.5, -8)
        label.Text = name .. ": " .. value .. (showPercent and "%" or "")

        callback(value)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)

    sliderBg.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
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
-- MODERN DROPDOWN
-------------------------------------------------

local function CreateModernDropdown(parent, name, options, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 44)
    holder.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Parent = parent

    RoundCorner(holder, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, 44)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(0, 120, 0, 30)
    display.Position = UDim2.new(1, -134, 0.5, -15)
    display.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    display.Text = default or options[1]
    display.Font = Enum.Font.GothamMedium
    display.TextSize = 12
    display.TextColor3 = Color3.fromRGB(255, 255, 255)
    display.AutoButtonColor = false
    display.Parent = holder

    RoundCorner(display, 6)

    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 14, 0, 14)
    arrow.Position = UDim2.new(1, -22, 0.5, -7)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://7733717447"
    arrow.ImageColor3 = Color3.fromRGB(150, 150, 160)
    arrow.Parent = display

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 32)
    list.Position = UDim2.new(0, 0, 0, 44)
    list.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 10
    list.Parent = holder

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = list

    local expanded = false

    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(28, 28, 36) or Color3.fromRGB(25, 25, 32)
        optBtn.Text = "  " .. option
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 11
        optBtn.Parent = list

        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)

        optBtn.MouseLeave:Connect(function()
            Tween(optBtn, {BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(28, 28, 36) or Color3.fromRGB(25, 25, 32)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end)

        optBtn.MouseButton1Click:Connect(function()
            display.Text = option
            callback(option)
            expanded = false
            list.Visible = false
            Tween(holder, {Size = UDim2.new(1, 0, 0, 44)}, 0.2)
            arrow.Rotation = 0
        end)
    end

    display.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            list.Visible = true
            Tween(holder, {Size = UDim2.new(1, 0, 0, 44 + list.Size.Y.Offset)}, 0.2)
            arrow.Rotation = 180
        else
            Tween(holder, {Size = UDim2.new(1, 0, 0, 44)}, 0.2)
            arrow.Rotation = 0
            delay(0.2, function()
                if not expanded then list.Visible = false end
            end)
        end
    end)

    return holder
end

-------------------------------------------------
-- ADD FEATURES TO TABS
-------------------------------------------------

-- Combat Tab
CreateModernToggle(combatTab, "Aim Assist", false, function(v)
    Features.AimAssist = v
end)

CreateModernToggle(combatTab, "Auto Shoot", false, function(v)
    Features.AutoShoot = v
end)

CreateModernSlider(combatTab, "Aim Strength", 0, 100, 35, function(v)
    Features.AimStrength = v
end, true)

CreateModernSlider(combatTab, "Aim FOV", 10, 300, 140, function(v)
    Features.AimFOV = v
end, false)

CreateModernSlider(combatTab, "Smoothness", 1, 100, 12, function(v)
    Features.AimSmoothness = v / 100
end, true)

-- Visual Tab
CreateModernToggle(visualTab, "Skeleton ESP", false, function(v)
    Features.SkeletonESP = v
end)

CreateModernToggle(visualTab, "Tracer ESP", false, function(v)
    Features.TracerESP = v
end)

CreateModernToggle(visualTab, "Box ESP", false, function(v)
    Features.BoxESP = v
end)

CreateModernToggle(visualTab, "Line ESP", false, function(v)
    Features.LineESP = v
end)

CreateModernSlider(visualTab, "Line Thickness", 1, 5, 2, function(v)
    -- Applied in render loop
end, false)

CreateModernDropdown(visualTab, "ESP Color", {"Cyan", "Red", "Green", "Purple", "Yellow", "White"}, "Cyan", function(v)
    local colors = {
        Cyan = Color3.fromRGB(0, 170, 255),
        Red = Color3.fromRGB(255, 60, 60),
        Green = Color3.fromRGB(60, 255, 120),
        Purple = Color3.fromRGB(180, 60, 255),
        Yellow = Color3.fromRGB(255, 220, 60),
        White = Color3.fromRGB(255, 255, 255)
    }
    Features.ESPColor = colors[v] or colors.Cyan
    FOVCircle.Color = Features.ESPColor
end)

-- Player Tab
CreateModernToggle(playerTab, "Auto Collect", false, function(v)
    -- Placeholder
end)

CreateModernToggle(playerTab, "Plant On Click", false, function(v)
    -- Placeholder
end)

CreateModernToggle(playerTab, "Auto Sell", false, function(v)
    -- Placeholder
end)

CreateModernDropdown(playerTab, "Select Fruit", {"Tomato", "Carrot", "Corn", "Wheat", "Pumpkin"}, "Tomato", function(v)
    -- Placeholder
end)

-- Settings Tab
CreateModernToggle(settingsTab, "Anti AFK", true, function(v)
    -- Placeholder
end)

CreateModernToggle(settingsTab, "Stream Mode", false, function(v)
    gui.Enabled = not v
end)

-------------------------------------------------
-- WINDOW DRAGGING
-------------------------------------------------

local dragging = false
local dragInput, dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Tween(main, {
            Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        }, 0.05)
    end
end)

-------------------------------------------------
-- WINDOW CONTROLS
-------------------------------------------------

icon.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    Tween(icon, {Rotation = main.Visible and 0 or 180}, 0.3)
end)

local minimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Tween(main, {Size = UDim2.new(0, 440, 0, 44)}, 0.2)
        for _, child in ipairs(main:GetChildren()) do
            if child.Name ~= "TopBar" and child ~= topBarFix then
                child.Visible = false
            end
        end
    else
        Tween(main, {Size = UDim2.new(0, 440, 0, 340)}, 0.2)
        for _, child in ipairs(main:GetChildren()) do
            if child.Name ~= "Shadow" then
                child.Visible = true
            end
        end
        for name, content in pairs(tabContents) do
            content.Visible = (name == activeTab)
        end
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

exitBtn.MouseButton1Click:Connect(function()
    for _, data in pairs(ESP) do
        if data.Tracer then data.Tracer:Remove() end
        if data.Skeleton then
            for _, line in pairs(data.Skeleton) do line:Remove() end
        end
        if data.Box then
            for _, line in pairs(data.Box) do line:Remove() end
        end
        if data.Line then data.Line:Remove() end
    end
    FOVCircle:Remove()
    gui:Destroy()
end)

-------------------------------------------------
-- DRAWING SYSTEM - ALL ESP TYPES
-------------------------------------------------

local function NewLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Transparency = 1
    line.Thickness = 1.5
    return line
end

local function NewQuad()
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.Transparency = 0.7
    quad.Thickness = 1.5
    quad.Filled = false
    return quad
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Color = Features.ESPColor
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Radius = Features.AimFOV

-------------------------------------------------
-- SKELETON DEFINITIONS
-------------------------------------------------

local R15Skeleton = {
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

local R6Skeleton = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local function GetSkeleton(character)
    if character:FindFirstChild("UpperTorso") then
        return R15Skeleton
    end
    return R6Skeleton
end

-------------------------------------------------
-- ESP CREATION (ALL TYPES)
-------------------------------------------------

local function CreateESP(player)
    if player == LocalPlayer then return end

    -- Skeleton Lines (14 max)
    local skeleton = {}
    for i = 1, 14 do
        skeleton[i] = NewLine()
    end

    -- Tracer Line
    local tracer = NewLine()

    -- Box ESP (4 lines for 2D box)
    local box = {}
    for i = 1, 4 do
        box[i] = NewLine()
    end

    -- Line ESP (single line from bottom screen to player)
    local lineESP = NewLine()

    ESP[player] = {
        Skeleton = skeleton,
        Tracer = tracer,
        Box = box,
        Line = lineESP,
        IsDead = false
    }

    -- Health tracking for instant cleanup
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
                    for _, line in pairs(ESP[player].Skeleton) do line.Visible = false end
                    for _, line in pairs(ESP[player].Box) do line.Visible = false end
                else
                    ESP[player].IsDead = false
                end
            end)

            hum.Died:Connect(function()
                ESP[player].IsDead = true
                ESP[player].Tracer.Visible = false
                ESP[player].Line.Visible = false
                for _, line in pairs(ESP[player].Skeleton) do line.Visible = false end
                for _, line in pairs(ESP[player].Box) do line.Visible = false end
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

    for _, line in pairs(data.Skeleton) do line:Remove() end
    data.Tracer:Remove()
    for _, line in pairs(data.Box) do line:Remove() end
    data.Line:Remove()
    ESP[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-------------------------------------------------
-- AIM TARGET + AUTO SHOOT
-------------------------------------------------

local function GetClosestPlayer()
    local closest = nil
    local shortest = Features.AimFOV
    local mousePos = UIS:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")

            if hum and hum.Health > 0 and head and not ESP[player].IsDead then
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

    return closest
end

-- Auto Shoot when scoped (right mouse held)
local IsScoped = false

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsScoped = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsScoped = false
    end
end)

-------------------------------------------------
-- RENDER LOOP - ALL ESP + AIM + AUTO SHOOT
-------------------------------------------------

RunService.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()

    -- Update FOV Circle
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Features.AimFOV
    FOVCircle.Color = Features.ESPColor
    FOVCircle.Visible = Features.AimAssist or Features.AutoShoot

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

    -- Auto Shoot Logic
    local targetForShoot = nil
    if Features.AutoShoot then
        targetForShoot = GetClosestPlayer()
        if targetForShoot and IsScoped then
            mouse1press()
            wait(0.05)
            mouse1release()
        end
    end

    for player, data in pairs(ESP) do
        -- INSTANT DEATH CHECK
        if data.IsDead then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
            for _, line in pairs(data.Box) do line.Visible = false end
            continue
        end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not char or not hum or hum.Health <= 0 or not hrp or not head then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
            for _, line in pairs(data.Box) do line.Visible = false end
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position)

        if not onScreen then
            data.Tracer.Visible = false
            data.Line.Visible = false
            for _, line in pairs(data.Skeleton) do line.Visible = false end
            for _, line in pairs(data.Box) do line.Visible = false end
            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        local thickness = math.clamp(3.5 - (distance / 300), 1, 3.5)
        local color = Features.ESPColor
        local screenHeight = Camera.ViewportSize.Y

        -------------------------------------------------
        -- SKELETON ESP
        -------------------------------------------------
        if Features.SkeletonESP and not data.IsDead then
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
            for _, line in pairs(data.Skeleton) do
                if line then line.Visible = false end
            end
        end

        -------------------------------------------------
        -- TRACER ESP
        -------------------------------------------------
        if Features.TracerESP and myRoot and not data.IsDead then
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

        -------------------------------------------------
        -- BOX ESP (2D Bounding Box)
        -------------------------------------------------
        if Features.BoxESP and not data.IsDead then
            local size = 2000 / distance
            local x = rootPos.X
            local y = rootPos.Y

            local topLeft = Vector2.new(x - size/2, y - size * 1.2)
            local topRight = Vector2.new(x + size/2, y - size * 1.2)
            local bottomLeft = Vector2.new(x - size/2, y + size/2)
            local bottomRight = Vector2.new(x + size/2, y + size/2)

            -- Top line
            data.Box[1].From = topLeft
            data.Box[1].To = topRight
            data.Box[1].Color = color
            data.Box[1].Thickness = thickness
            data.Box[1].Visible = true

            -- Right line
            data.Box[2].From = topRight
            data.Box[2].To = bottomRight
            data.Box[2].Color = color
            data.Box[2].Thickness = thickness
            data.Box[2].Visible = true

            -- Bottom line
            data.Box[3].From = bottomRight
            data.Box[3].To = bottomLeft
            data.Box[3].Color = color
            data.Box[3].Thickness = thickness
            data.Box[3].Visible = true

            -- Left line
            data.Box[4].From = bottomLeft
            data.Box[4].To = topLeft
            data.Box[4].Color = color
            data.Box[4].Thickness = thickness
            data.Box[4].Visible = true
        else
            for _, line in pairs(data.Box) do
                if line then line.Visible = false end
            end
        end

        -------------------------------------------------
        -- LINE ESP (Bottom Screen to Player)
        -------------------------------------------------
        if Features.LineESP and not data.IsDead then
            data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Line.To = Vector2.new(rootPos.X, rootPos.Y)
            data.Line.Color = color
            data.Line.Thickness = thickness
            data.Line.Visible = true
        else
            data.Line.Visible = false
        end
    end

    -------------------------------------------------
    -- AIM ASSIST
    -------------------------------------------------
    if Features.AimAssist then
        local target = GetClosestPlayer()

        if target then
            local predicted = target.Position
            local smoothness = math.clamp(Features.AimStrength / 100, 0.01, 1)

            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, predicted),
                smoothness * Features.AimSmoothness
            )
        end
    end
end)

-- Anti-AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)
