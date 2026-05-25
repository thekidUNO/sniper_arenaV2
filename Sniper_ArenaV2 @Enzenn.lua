-- ╔══════════════════════════════════════════════╗
-- ║           UNO HUB v7.0 - STUDIO READY        ║
-- ║     Fixed: Mobile + PC, No Executor APIs     ║
-- ╚══════════════════════════════════════════════╝

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Camera         = workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer

-- ══════════════════════════════════════
-- [1] PLATFORM DETECTION (runs once)
-- ══════════════════════════════════════
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ══════════════════════════════════════
-- [2] STATE
-- ══════════════════════════════════════
local Features = {
    SkeletonESP    = false,
    TracerESP      = false,
    BoxESP         = false,
    NameESP        = false,
    AimAssist      = false,
    AimActive      = false,    -- replaces IsScoped, works on both platforms
    AimStrength    = 35,
    AimFOV         = 140,
    AimSmoothness  = 0.12,
    ESPColor       = Color3.fromRGB(0, 170, 255),
}

local ESP           = {}       -- stores Highlight + BillboardGui per player
local targetSnapshot = nil    -- locked once per frame, prevents jitter

-- ══════════════════════════════════════
-- [3] CLEANUP PREVIOUS INSTANCE
-- ══════════════════════════════════════
if game.CoreGui:FindFirstChild("UnoHubV7") then
    game.CoreGui.UnoHubV7:Destroy()
end
for _, p in ipairs(Players:GetPlayers()) do
    local char = p.Character
    if char then
        local old = char:FindFirstChild("_UnoESP")
        if old then old:Destroy() end
    end
end

-- ══════════════════════════════════════
-- [4] UTILITY
-- ══════════════════════════════════════
local function Tween(obj, props, dur)
    TweenService:Create(
        obj,
        TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

local function IsAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- ══════════════════════════════════════
-- [5] GUI SETUP
-- ══════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name               = "UnoHubV7"
gui.ResetOnSpawn       = false
gui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset     = true
gui.Parent             = game.CoreGui

-- ══════════════════════════════════════
-- [6] FOV INDICATOR (ScreenGui ImageLabel, no Drawing)
-- ══════════════════════════════════════
local fovFrame = Instance.new("Frame")
fovFrame.Name              = "FOVIndicator"
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel   = 0
fovFrame.AnchorPoint       = Vector2.new(0.5, 0.5)
fovFrame.ZIndex            = 10
fovFrame.Visible           = false
fovFrame.Parent            = gui

local fovCircle = Instance.new("ImageLabel")
fovCircle.Name             = "Circle"
fovCircle.BackgroundTransparency = 1
fovCircle.Image            = "rbxassetid://3570695787" -- circle outline asset
fovCircle.ImageColor3      = Features.ESPColor
fovCircle.ImageTransparency = 0.3
fovCircle.Size             = UDim2.new(1, 0, 1, 0)
fovCircle.Parent           = fovFrame

-- Update FOV circle size and position each frame (done in RenderStepped)

-- ══════════════════════════════════════
-- [7] MAIN WINDOW
-- ══════════════════════════════════════
local WINDOW_W = isMobile and 320 or 400
local WINDOW_H = isMobile and 280 or 320
local FONT_TITLE = isMobile and 14 or 16
local FONT_BODY  = isMobile and 12 or 14

local main = Instance.new("Frame")
main.Name              = "MainWindow"
main.Size              = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
main.Position          = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
main.BackgroundColor3  = Color3.fromRGB(15, 15, 18)
main.BorderSizePixel   = 0
main.Active            = true
main.Parent            = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color     = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1.5
mainStroke.Parent    = main

-- ── TOP BAR ──
local topBar = Instance.new("Frame")
topBar.Name            = "TopBar"
topBar.Size            = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
topBar.BorderSizePixel = 0
topBar.Parent          = main
mainCorner:Clone().Parent = topBar

local topFix = Instance.new("Frame")   -- hides bottom corners of topBar
topFix.Size            = UDim2.new(1, 0, 0, 20)
topFix.Position        = UDim2.new(0, 0, 1, -20)
topFix.BackgroundColor3 = topBar.BackgroundColor3
topFix.BorderSizePixel = 0
topFix.Parent          = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size            = UDim2.new(0, 200, 0, 42)
titleLabel.Position        = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text            = "UNO HUB  v7.0"
titleLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
titleLabel.Font            = Enum.Font.GothamBold
titleLabel.TextSize        = FONT_TITLE
titleLabel.TextXAlignment  = Enum.TextXAlignment.Left
titleLabel.Parent          = topBar

-- ── WINDOW CONTROL BUTTONS ──
local function MakeWinBtn(label, posX, bgColor, hoverColor)
    local btn = Instance.new("TextButton")
    btn.Size           = UDim2.new(0, isMobile and 36 or 28, 0, isMobile and 36 or 28)
    btn.Position       = UDim2.new(1, posX, 0.5, isMobile and -18 or -14)
    btn.Text           = label
    btn.TextScaled     = true
    btn.Font           = Enum.Font.GothamBold
    btn.TextColor3     = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = bgColor
    btn.AutoButtonColor = false
    btn.Parent         = topBar
    Instance.new("UICorner").Parent = btn
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = hoverColor}, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = bgColor}, 0.15) end)
    return btn
end

local exitBtn = MakeWinBtn("×", -36, Color3.fromRGB(210,55,55), Color3.fromRGB(255,75,75))
local hideBtn = MakeWinBtn("○", -76, Color3.fromRGB(45,45,55), Color3.fromRGB(65,65,80))
local minBtn  = MakeWinBtn("−", -116, Color3.fromRGB(45,45,55), Color3.fromRGB(65,65,80))

-- ══════════════════════════════════════
-- [8] TAB SYSTEM
-- ══════════════════════════════════════
local tabBar = Instance.new("Frame")
tabBar.Name            = "TabBar"
tabBar.Size            = UDim2.new(1, -16, 0, 34)
tabBar.Position        = UDim2.new(0, 8, 0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
tabBar.BorderSizePixel = 0
tabBar.Parent          = main
mainCorner:Clone().Parent = tabBar

local tabList = Instance.new("UIListLayout")
tabList.FillDirection       = Enum.FillDirection.Horizontal
tabList.Padding             = UDim.new(0, 6)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment   = Enum.VerticalAlignment.Center
tabList.Parent              = tabBar

local contentArea = Instance.new("Frame")
contentArea.Name           = "ContentArea"
contentArea.Size           = UDim2.new(1, -16, 1, -90)
contentArea.Position       = UDim2.new(0, 8, 0, 86)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true
contentArea.Parent         = main

local tabs        = {}
local tabContents = {}
local activeTab   = "Combat"

local function CreateTab(name)
    local tabW = isMobile and 90 or 110

    local btn = Instance.new("TextButton")
    btn.Name           = name.."Tab"
    btn.Size           = UDim2.new(0, tabW, 0, 28)
    btn.BackgroundColor3 = name == activeTab
        and Color3.fromRGB(0, 170, 255)
        or  Color3.fromRGB(32, 32, 40)
    btn.Text           = name
    btn.Font           = Enum.Font.GothamSemibold
    btn.TextSize       = FONT_BODY
    btn.TextColor3     = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.Parent         = tabBar
    Instance.new("UICorner").Parent = btn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name            = name.."Scroll"
    scroll.Size            = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
    scroll.Visible         = name == activeTab
    scroll.CanvasSize      = UDim2.new(0, 0, 0, 0)
    scroll.Parent          = contentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent  = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    tabs[name]        = btn
    tabContents[name] = scroll

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        Tween(tabs[activeTab], {BackgroundColor3 = Color3.fromRGB(32,32,40)}, 0.2)
        tabContents[activeTab].Visible = false
        activeTab = name
        Tween(btn, {BackgroundColor3 = Color3.fromRGB(0,170,255)}, 0.2)
        scroll.Visible = true
    end)

    return scroll
end

local combatScroll = CreateTab("Combat")
local visualScroll = CreateTab("Visual")

-- ══════════════════════════════════════
-- [9] COMPONENTS
-- ══════════════════════════════════════

-- ── TOGGLE ──
local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -8, 0, isMobile and 52 or 48)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel  = 0
    frame.Parent           = parent
    Instance.new("UICorner").Parent = frame

    local label = Instance.new("TextLabel")
    label.Size             = UDim2.new(0.6, 0, 1, 0)
    label.Position         = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text             = text
    label.TextColor3       = Color3.fromRGB(235, 235, 245)
    label.Font             = Enum.Font.GothamMedium
    label.TextSize         = FONT_BODY
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.Parent           = frame

    -- Larger touch target on mobile
    local trackW = isMobile and 60 or 52
    local knobS  = isMobile and 26 or 22

    local track = Instance.new("TextButton")
    track.Size             = UDim2.new(0, trackW, 0, knobS + 6)
    track.Position         = UDim2.new(1, -(trackW + 14), 0.5, -(knobS/2 + 3))
    track.Text             = ""
    track.BackgroundColor3 = default
        and Color3.fromRGB(0, 170, 255)
        or  Color3.fromRGB(50, 50, 60)
    track.AutoButtonColor  = false
    track.Parent           = frame
    local tc = Instance.new("UICorner")
    tc.CornerRadius        = UDim.new(1, 0)
    tc.Parent              = track

    local knob = Instance.new("Frame")
    knob.Size              = UDim2.new(0, knobS, 0, knobS)
    knob.Position          = default
        and UDim2.new(1, -(knobS + 3), 0.5, -knobS/2)
        or  UDim2.new(0, 3, 0.5, -knobS/2)
    knob.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    knob.Parent            = track
    local kc = Instance.new("UICorner")
    kc.CornerRadius        = UDim.new(1, 0)
    kc.Parent              = knob

    local state = default

    track.MouseButton1Click:Connect(function()
        state = not state
        if state then
            Tween(track, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
            Tween(knob, {Position = UDim2.new(1, -(knobS + 3), 0.5, -knobS/2)}, 0.2)
        else
            Tween(track, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.2)
            Tween(knob, {Position = UDim2.new(0, 3, 0.5, -knobS/2)}, 0.2)
        end
        callback(state)
    end)
end

-- ── SLIDER (FIXED: global InputChanged, not local) ──
local function CreateSlider(parent, labelText, min, max, default, callback, suffix)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -8, 0, isMobile and 72 or 64)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel  = 0
    frame.Parent           = parent
    Instance.new("UICorner").Parent = frame

    local label = Instance.new("TextLabel")
    label.Size             = UDim2.new(1, -20, 0, 22)
    label.Position         = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text             = labelText..": "..default..(suffix or "")
    label.TextColor3       = Color3.fromRGB(235, 235, 245)
    label.Font             = Enum.Font.GothamMedium
    label.TextSize         = FONT_BODY
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.Parent           = frame

    local trackH = isMobile and 14 or 10
    local handleS = isMobile and 24 or 18

    local track = Instance.new("TextButton")
    track.Size             = UDim2.new(1, -24, 0, trackH)
    track.Position         = UDim2.new(0, 12, 0, isMobile and 44 or 38)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    track.Text             = ""
    track.AutoButtonColor  = false
    track.Parent           = frame
    local tc = Instance.new("UICorner")
    tc.CornerRadius        = UDim.new(1, 0)
    tc.Parent              = track

    local pct = (default - min) / (max - min)

    local fill = Instance.new("Frame")
    fill.Size              = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3  = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel   = 0
    fill.Parent            = track
    local fc = Instance.new("UICorner")
    fc.CornerRadius        = UDim.new(1, 0)
    fc.Parent              = fill

    local handle = Instance.new("Frame")
    handle.Size            = UDim2.new(0, handleS, 0, handleS)
    handle.Position        = UDim2.new(pct, -handleS/2, 0.5, -handleS/2)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent          = track
    local hc = Instance.new("UICorner")
    hc.CornerRadius        = UDim.new(1, 0)
    hc.Parent              = handle

    local dragging = false
    local currentValue = default

    local function updateFromInput(input)
        local mouseX = input.Position.X
        local barX   = track.AbsolutePosition.X
        local barW   = track.AbsoluteSize.X
        local newPct = math.clamp((mouseX - barX) / barW, 0, 1)
        currentValue = math.floor(min + (newPct * (max - min)))

        fill.Size     = UDim2.new(newPct, 0, 1, 0)
        handle.Position = UDim2.new(newPct, -handleS/2, 0.5, -handleS/2)
        label.Text    = labelText..": "..currentValue..(suffix or "")
        callback(currentValue)
    end

    -- Start drag
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)

    -- FIXED: Global listener catches movement even outside track
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input)
        end
    end)

    -- Release drag
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ── DROPDOWN ──
local function CreateDropdown(parent, labelText, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -8, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    frame.BorderSizePixel  = 0
    frame.ClipsDescendants = true
    frame.Parent           = parent
    Instance.new("UICorner").Parent = frame

    local label = Instance.new("TextLabel")
    label.Size             = UDim2.new(0.45, 0, 0, 48)
    label.Position         = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text             = labelText
    label.TextColor3       = Color3.fromRGB(235, 235, 245)
    label.Font             = Enum.Font.GothamMedium
    label.TextSize         = FONT_BODY
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.Parent           = frame

    local display = Instance.new("TextButton")
    display.Size           = UDim2.new(0, 110, 0, 30)
    display.Position       = UDim2.new(1, -126, 0.5, -15)
    display.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    display.Text           = default or options[1]
    display.Font           = Enum.Font.GothamMedium
    display.TextSize       = FONT_BODY - 1
    display.TextColor3     = Color3.fromRGB(255, 255, 255)
    display.AutoButtonColor = false
    display.Parent         = frame
    Instance.new("UICorner").Parent = display

    local list = Instance.new("Frame")
    list.Size              = UDim2.new(1, 0, 0, #options * 30)
    list.Position          = UDim2.new(0, 0, 0, 48)
    list.BackgroundColor3  = Color3.fromRGB(28, 28, 36)
    list.BorderSizePixel   = 0
    list.Visible           = false
    list.Parent            = frame
    Instance.new("UIListLayout").Parent = list

    local expanded = false

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size            = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundColor3 = i % 2 == 0
            and Color3.fromRGB(32,32,42)
            or  Color3.fromRGB(28,28,36)
        optBtn.Text            = "  "..opt
        optBtn.Font            = Enum.Font.Gotham
        optBtn.TextSize        = FONT_BODY - 1
        optBtn.TextColor3      = Color3.fromRGB(200, 200, 210)
        optBtn.TextXAlignment  = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.Parent          = list

        optBtn.MouseButton1Click:Connect(function()
            display.Text = opt
            callback(opt)
            expanded = false
            list.Visible = false
            Tween(frame, {Size = UDim2.new(1, -8, 0, 48)}, 0.2)
        end)
    end

    display.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            list.Visible = true
            Tween(frame, {Size = UDim2.new(1, -8, 0, 48 + list.Size.Y.Offset)}, 0.2)
        else
            Tween(frame, {Size = UDim2.new(1, -8, 0, 48)}, 0.2)
            task.delay(0.2, function()   -- FIXED: task.delay not delay()
                if not expanded then list.Visible = false end
            end)
        end
    end)
end

-- ══════════════════════════════════════
-- [10] POPULATE TABS
-- ══════════════════════════════════════

-- COMBAT TAB
CreateToggle(combatScroll, "Aim Assist", false, function(v)
    Features.AimAssist = v
    fovFrame.Visible   = v
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

-- VISUAL TAB
CreateToggle(visualScroll, "Skeleton ESP", false, function(v)
    Features.SkeletonESP = v
    for _, data in pairs(ESP) do
        if data.Highlight then
            data.Highlight.Enabled = v or Features.BoxESP
        end
    end
end)

CreateToggle(visualScroll, "Box ESP", false, function(v)
    Features.BoxESP = v
    for _, data in pairs(ESP) do
        if data.Highlight then
            data.Highlight.Enabled = v or Features.SkeletonESP
        end
    end
end)

CreateToggle(visualScroll, "Tracer ESP", false, function(v)
    Features.TracerESP = v
    for _, data in pairs(ESP) do
        if data.Beam then
            data.Beam.Enabled = v
        end
    end
end)

CreateToggle(visualScroll, "Name ESP", false, function(v)
    Features.NameESP = v
    for _, data in pairs(ESP) do
        if data.Billboard then
            data.Billboard.Enabled = v
        end
    end
end)

CreateDropdown(visualScroll, "ESP Color", {"Cyan","Red","Green","Purple","Yellow","White"}, "Cyan", function(v)
    local colors = {
        Cyan   = Color3.fromRGB(0,170,255),
        Red    = Color3.fromRGB(255,60,60),
        Green  = Color3.fromRGB(60,255,120),
        Purple = Color3.fromRGB(180,60,255),
        Yellow = Color3.fromRGB(255,220,60),
        White  = Color3.fromRGB(255,255,255),
    }
    Features.ESPColor = colors[v] or colors.Cyan
    fovCircle.ImageColor3 = Features.ESPColor
    for _, data in pairs(ESP) do
        if data.Highlight then
            data.Highlight.OutlineColor = Features.ESPColor
            data.Highlight.FillColor   = Features.ESPColor
        end
    end
end)

-- ══════════════════════════════════════
-- [11] ESP SYSTEM (uses Highlight + BillboardGui)
--      No Drawing API - works in real Studio games
-- ══════════════════════════════════════
local function SetupESP(player)
    if player == LocalPlayer then return end

    local function AttachToChar(char)
        -- Remove old if exists
        local old = char:FindFirstChild("_UnoESP")
        if old then old:Destroy() end

        local container = Instance.new("Folder")
        container.Name = "_UnoESP"
        container.Parent = char

        -- Highlight (Box + Skeleton combined in one)
        local hl = Instance.new("SelectionBox")
        hl = Instance.new("Highlight")
        hl.Name            = "HLInstance"
        hl.Adornee         = char
        hl.FillColor       = Features.ESPColor
        hl.FillTransparency = 0.6
        hl.OutlineColor    = Features.ESPColor
        hl.OutlineTransparency = 0
        hl.Enabled         = Features.SkeletonESP or Features.BoxESP
        hl.Parent          = container

        -- BillboardGui for name tag above head
        local head = char:FindFirstChild("Head")
        local bb = Instance.new("BillboardGui")
        bb.Name            = "NameTag"
        bb.Size            = UDim2.new(0, 100, 0, 30)
        bb.StudsOffset     = Vector3.new(0, 3, 0)
        bb.Adornee         = head
        bb.AlwaysOnTop     = true
        bb.Enabled         = Features.NameESP
        bb.Parent          = container

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size    = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text    = player.Name
        nameLabel.TextColor3 = Features.ESPColor
        nameLabel.Font    = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Parent  = bb

        ESP[player] = {
            Highlight = hl,
            Billboard = bb,
            Container = container,
        }
    end

    -- Attach now if character exists
    if player.Character then
        AttachToChar(player.Character)
    end

    -- Re-attach on respawn
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5) -- wait for char to fully load
        AttachToChar(char)
    end)
end

local function RemoveESP(player)
    local data = ESP[player]
    if data and data.Container then
        pcall(function() data.Container:Destroy() end)
    end
    ESP[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do SetupESP(p) end
Players.PlayerAdded:Connect(SetupESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- ══════════════════════════════════════
-- [12] TARGETING (FIXED: snapshot once per frame)
-- ══════════════════════════════════════
local function GetClosestPlayer()
    local closest  = nil
    local shortest = Features.AimFOV
    local center   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            local char = p.Character
            local head = char and char:FindFirstChild("Head")
            if head then
                local pos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest  = head
                    end
                end
            end
        end
    end

    return closest
end

-- ══════════════════════════════════════
-- [13] INPUT - PLATFORM SPLIT
-- ══════════════════════════════════════
if isMobile then
    -- ── MOBILE: Virtual AIM button ──
    local aimBtn = Instance.new("TextButton")
    aimBtn.Name            = "AimButton"
    aimBtn.Size            = UDim2.new(0, 80, 0, 80)   -- finger friendly
    aimBtn.Position        = UDim2.new(1, -100, 1, -190)
    aimBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    aimBtn.BackgroundTransparency = 0.4
    aimBtn.Text            = "AIM"
    aimBtn.Font            = Enum.Font.GothamBold
    aimBtn.TextSize        = 16
    aimBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
    aimBtn.AutoButtonColor = false
    aimBtn.ZIndex          = 20
    aimBtn.Parent          = gui

    local aimCorner = Instance.new("UICorner")
    aimCorner.CornerRadius = UDim.new(1, 0)
    aimCorner.Parent       = aimBtn

    aimBtn.MouseButton1Down:Connect(function()
        Features.AimActive = true
        Tween(aimBtn, {BackgroundTransparency = 0.1}, 0.1)
    end)
    aimBtn.MouseButton1Up:Connect(function()
        Features.AimActive = false
        Tween(aimBtn, {BackgroundTransparency = 0.4}, 0.1)
    end)
else
    -- ── PC: Right click or Q key ──
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2
        or input.KeyCode == Enum.KeyCode.Q then
            Features.AimActive = true
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2
        or input.KeyCode == Enum.KeyCode.Q then
            Features.AimActive = false
        end
    end)
end

-- ══════════════════════════════════════
-- [14] WINDOW DRAG
-- ══════════════════════════════════════
local winDragging  = false
local winDragStart = nil
local winStartPos  = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        winDragging  = true
        winDragStart = input.Position
        winStartPos  = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if winDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - winDragStart
        -- Clamp to screen so window can't be lost
        local vp = Camera.ViewportSize
        local newX = math.clamp(winStartPos.X.Offset + delta.X, 0, vp.X - WINDOW_W)
        local newY = math.clamp(winStartPos.Y.Offset + delta.Y, 0, vp.Y - WINDOW_H)
        main.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        winDragging = false
    end
end)

-- ══════════════════════════════════════
-- [15] WINDOW CONTROL LOGIC
-- ══════════════════════════════════════
local minimized = false

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Tween(main, {Size = UDim2.new(0, WINDOW_W, 0, 42)}, 0.2)
        tabBar.Visible     = false
        contentArea.Visible = false
    else
        Tween(main, {Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)}, 0.2)
        tabBar.Visible     = true
        contentArea.Visible = true
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

exitBtn.MouseButton1Click:Connect(function()
    for _, data in pairs(ESP) do
        pcall(function()
            if data.Container then data.Container:Destroy() end
        end)
    end
    task.delay(0.1, function()
        pcall(function() gui:Destroy() end)
    end)
end)

-- ══════════════════════════════════════
-- [16] HOME ICON (toggle window)
-- ══════════════════════════════════════
local icon = Instance.new("ImageButton")
icon.Name              = "HomeIcon"
icon.Size              = UDim2.new(0, isMobile and 50 or 40, 0, isMobile and 50 or 40)
icon.Position          = UDim2.new(0, 16, 0.5, -25)
icon.BackgroundColor3  = Color3.fromRGB(25, 25, 30)
icon.Image             = "rbxassetid://7733960981"
icon.ImageColor3       = Features.ESPColor
icon.AutoButtonColor   = false
icon.ZIndex            = 20
icon.Parent            = gui
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 10)
iconCorner.Parent = icon
local iconStroke = Instance.new("UIStroke")
iconStroke.Color     = Features.ESPColor
iconStroke.Thickness = 2
iconStroke.Parent    = icon

-- Icon drag
local iconDragging  = false
local iconDragStart = nil
local iconStartPos  = nil

icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging  = true
        iconDragStart = input.Position
        iconStartPos  = icon.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if iconDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - iconDragStart
        icon.Position = UDim2.new(
            iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
        )
    end
end)

icon.MouseButton1Click:Connect(function()
    if not iconDragging then
        main.Visible = not main.Visible
    end
end)

-- ══════════════════════════════════════
-- [17] RENDER LOOP
-- ══════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    -- FOV CIRCLE (ScreenGui, not Drawing)
    fovFrame.Visible = Features.AimAssist
    if Features.AimAssist then
        local diameter = Features.AimFOV * 2
        fovFrame.Size     = UDim2.new(0, diameter, 0, diameter)
        fovFrame.Position = UDim2.new(0, center.X - Features.AimFOV, 0, center.Y - Features.AimFOV)
        fovCircle.ImageColor3 = Features.ESPColor
    end

    -- SNAPSHOT TARGET ONCE (prevents jitter)
    if Features.AimAssist and Features.AimActive then
        targetSnapshot = GetClosestPlayer()
    else
        targetSnapshot = nil
    end

    -- AIM ASSIST (uses snapshot, never re-targets mid-lerp)
    if targetSnapshot then
        local smooth = Features.AimSmoothness * (Features.AimStrength / 100)
        smooth = math.clamp(smooth, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(
            CFrame.new(Camera.CFrame.Position, targetSnapshot.Position),
            smooth
        )
    end
end)

-- ══════════════════════════════════════
-- [18] ANTI AFK (fixed)
-- ══════════════════════════════════════
local VU = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)

-- ══════════════════════════════════════
-- END OF SCRIPT
-- ══════════════════════════════════════
