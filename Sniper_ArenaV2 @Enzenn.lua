-- Modern UNO HUB v17.0 — FOV Trigger Aimbot, Auto Headshot Fix, ESP Stability
-- Fixes: FOV-based trigger mode, auto headshot locking, FOV circle resize,
-- ESP consistency, bounding box cache invalidation, skeleton cache sync,
-- smoothness inversion, aim strength uncapped, dead player cleanup

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-------------------------------------------------
-- EXECUTOR COMPATIBILITY
-------------------------------------------------
local Executor = {
    Drawing = typeof(Drawing) == "table" and Drawing.new ~= nil,
    GetHUI = typeof(gethui) == "function",
}

if not Executor.Drawing then
    warn("[UNO HUB] Drawing API unsupported. ESP disabled.")
end

-------------------------------------------------
-- RESOURCE MANAGER
-------------------------------------------------
local Janitor = {
    Connections = {},
    Drawings = {},
    Tweens = {},
    Threads = {},
}

function Janitor:Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self.Connections, conn)
    return conn
end

function Janitor:AddDrawing(drawing)
    if drawing then
        self.Drawings[drawing] = true
    end
    return drawing
end

function Janitor:RemoveDrawing(drawing)
    if drawing and self.Drawings[drawing] then
        self.Drawings[drawing] = nil
        pcall(function() drawing:Remove() end)
    end
end

function Janitor:AddTween(tween)
    if tween then
        table.insert(self.Tweens, tween)
    end
    return tween
end

function Janitor:AddThread(thread)
    if thread then
        table.insert(self.Threads, thread)
    end
    return thread
end

function Janitor:Cleanup()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}

    for _, tween in ipairs(self.Tweens) do
        pcall(function() tween:Cancel() end)
    end
    self.Tweens = {}

    for drawing, _ in pairs(self.Drawings) do
        pcall(function() drawing:Remove() end)
    end
    self.Drawings = {}

    for _, thread in ipairs(self.Threads) do
        pcall(function() task.cancel(thread) end)
    end
    self.Threads = {}
end

-------------------------------------------------
-- SAFE PARENTING
-------------------------------------------------
local function SafeParent(gui)
    if Executor.GetHUI then
        gui.Parent = gethui()
    else
        gui.Parent = game.CoreGui
    end
end

-------------------------------------------------
-- CLEANUP ON RE-EXECUTE
-------------------------------------------------
local oldGui = game.CoreGui:FindFirstChild("UnoModernHub")
if oldGui then pcall(function() oldGui:Destroy() end) end
if Executor.GetHUI then
    for _, v in ipairs(gethui():GetChildren()) do
        if v.Name == "UnoModernHub" then pcall(function() v:Destroy() end) end
    end
end

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local isPC = not isMobile

-------------------------------------------------
-- TWEEN MANAGER
-------------------------------------------------
local ActiveTweens = {}
local TweenCompletions = {}

local function SafeTween(obj, props, dur, style, dir)
    if not obj or not obj.Parent then return end
    if ActiveTweens[obj] then
        pcall(function() ActiveTweens[obj]:Cancel() end)
        if TweenCompletions[obj] then
            pcall(function() TweenCompletions[obj]:Disconnect() end)
            TweenCompletions[obj] = nil
        end
    end
    local tween = TweenService:Create(obj, TweenInfo.new(
        dur or 0.2,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props)
    ActiveTweens[obj] = tween
    Janitor:AddTween(tween)

    local completionConn = tween.Completed:Connect(function()
        if ActiveTweens[obj] == tween then
            ActiveTweens[obj] = nil
        end
        if TweenCompletions[obj] == completionConn then
            TweenCompletions[obj] = nil
        end
    end)
    TweenCompletions[obj] = completionConn
    table.insert(Janitor.Connections, completionConn)

    tween:Play()
    return tween
end

-------------------------------------------------
-- INTERACTION LOCK
-------------------------------------------------
local InteractionLock = {
    None = 0,
    Slider = 1,
    Window = 2,
    Icon = 3,
}
local CurrentLock = InteractionLock.None

-------------------------------------------------
-- FEATURES
-------------------------------------------------
local Features = {
    SkeletonESP = false,
    TracerESP = false,
    BoxESP = false,
    LineESP = false,
    AimAssist = false,
    AutoHeadshot = false,
    AimActive = false,           -- Computed: true when target in FOV + visible
    AimMode = "FOV Trigger",     -- "FOV Trigger" or "Hold to Aim"
    AimStrength = 100,           -- Default 100% for instant snap feel
    AimSmoothness = 0,           -- Default 0% for instant snap feel
    AimFOV = 140,
    ESPColor = Color3.fromRGB(0, 170, 255),
    ESPThickness = 2,
    PredictionMs = 0,
    RenderDistance = 1500,
    TeamCheck = false,
    AlwaysShowFOV = true,
}

local ThicknessSettings = {
    Skeleton = 1.5,
    Tracer = 1.5,
    Box = 2,
    Line = 1.5,
}

local ESP = {}
local targetSnapshot = nil
local targetSnapshotPlayer = nil

-------------------------------------------------
-- RAYCAST PARAMS
-------------------------------------------------
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = {LocalPlayer.Character}
RayParams.IgnoreWater = true

Janitor:Connect(LocalPlayer.CharacterAdded, function(char)
    RayParams.FilterDescendantsInstances = {char}
end)

-- Multi-pass transparent reraycast (up to 5 attempts)
local function IsVisible(targetPart, targetCharacter)
    if not targetPart or not targetPart.Parent then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local maxDistance = direction.Magnitude
    if maxDistance <= 0 then return true end
    direction = direction.Unit * maxDistance

    local currentOrigin = origin
    local remainingDist = maxDistance

    for _ = 1, 5 do
        local result = workspace:Raycast(currentOrigin, direction.Unit * remainingDist, RayParams)
        if not result then
            return true
        end

        if result.Instance:IsDescendantOf(targetCharacter) then
            return true
        end

        if result.Instance.Transparency > 0.95 then
            currentOrigin = result.Position + direction.Unit * 0.1
            remainingDist = maxDistance - (currentOrigin - origin).Magnitude
            if remainingDist <= 0 then
                return true
            end
        else
            return false
        end
    end

    return false
end

-- Occlusion cache
local OcclusionCache = {}
local OcclusionCacheTime = 0.05

local function IsVisibleCached(targetPart, targetCharacter)
    if not targetPart or not targetPart.Parent then return false end
    local cacheKey = tostring(targetPart)
    local now = tick()
    local cached = OcclusionCache[cacheKey]

    if cached and (now - cached.Time) < OcclusionCacheTime then
        return cached.Result
    end

    local result = IsVisible(targetPart, targetCharacter)
    OcclusionCache[cacheKey] = {
        Result = result,
        Time = now,
    }
    return result
end

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
-- VISIBILITY SYSTEM
-------------------------------------------------
local CachedTargets = {}

local function UpdateTargetCache()
    table.clear(CachedTargets)
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if Features.TeamCheck then
                local myTeam = LocalPlayer.Team
                local theirTeam = p.Team
                if myTeam ~= nil and theirTeam ~= nil and theirTeam == myTeam then
                    continue
                end
            end

            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hum.Health > 0 and head and hrp then
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                local rootPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position)

                if headOnScreen and rootOnScreen and headPos.Z > 0 and rootPos.Z > 0 then
                    local distFromCenter = (Vector2.new(headPos.X, headPos.Y) - screenCenter).Magnitude
                    local worldDist = (Camera.CFrame.Position - hrp.Position).Magnitude

                    if distFromCenter <= Features.AimFOV and worldDist <= Features.RenderDistance then
                        table.insert(CachedTargets, {
                            Player = p,
                            Character = char,
                            Humanoid = hum,
                            Head = head,
                            HRP = hrp,
                            HeadPos = headPos,
                            RootPos = rootPos,
                            Distance = worldDist,
                            DistFromCenter = distFromCenter,
                            Velocity = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero,
                        })
                    end
                end
            end
        end
    end
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
local WIN_H = isMobile and 300 or 340

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
subText.Text = "v17.0 | FOV Trigger"
subText.TextColor3 = Color3.fromRGB(130, 130, 140)
subText.Font = Enum.Font.Gotham
subText.TextSize = 9
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.Parent = topBar

-- Buttons
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

    Janitor:Connect(btn.MouseEnter, function()
        SafeTween(btn, {BackgroundColor3 = hover}, 0.15)
    end)
    Janitor:Connect(btn.MouseLeave, function()
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

    Janitor:Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)

    tabs[name] = btn
    tabContents[name] = scroll

    Janitor:Connect(btn.MouseButton1Click, function()
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
-- TOGGLE
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
    Janitor:Connect(track.MouseButton1Click, function()
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
-- SLIDER
-- =============================================
local ActiveSliderId = nil
local sliderRegistry = {}

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

    local sliderId = frame

    local function updateSlider(inputPos)
        if CurrentLock ~= InteractionLock.None and CurrentLock ~= InteractionLock.Slider then return end
        local barX = track.AbsolutePosition.X
        local barW = track.AbsoluteSize.X
        if barW <= 0 then return end
        local newPct = math.clamp((inputPos.X - barX) / barW, 0, 1)
        local value = math.round(min + (newPct * (max - min)))

        fill.Size = UDim2.new(newPct, 0, 1, 0)
        handle.Position = UDim2.new(newPct, -handle.Size.X.Offset/2, 0.5, -handle.Size.Y.Offset/2)
        label.Text = labelText..": "..value..(suffix or "")

        callback(value)
    end

    sliderRegistry[sliderId] = {
        update = updateSlider,
        frame = frame,
    }

    Janitor:Connect(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if CurrentLock == InteractionLock.None then
                CurrentLock = InteractionLock.Slider
                ActiveSliderId = sliderId
                updateSlider(input.Position)
            end
        end
    end)

    return frame
end

-- =============================================
-- CENTRALIZED INPUT
-- =============================================
Janitor:Connect(UIS.InputChanged, function(input)
    if ActiveSliderId and sliderRegistry[ActiveSliderId] then
        sliderRegistry[ActiveSliderId].update(input.Position)
    end
end)

Janitor:Connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if ActiveSliderId then
            CurrentLock = InteractionLock.None
            ActiveSliderId = nil
        end
    end
end)

-- =============================================
-- DROPDOWN
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
    local dropdownBusy = false
    local dropdownResetTimer = nil

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

        Janitor:Connect(optBtn.MouseEnter, function()
            SafeTween(optBtn, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        Janitor:Connect(optBtn.MouseLeave, function()
            SafeTween(optBtn, {BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(32, 32, 42) or Color3.fromRGB(28, 28, 36)}, 0.1)
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end)
        Janitor:Connect(optBtn.MouseButton1Click, function()
            if dropdownBusy then return end
            display.Text = opt
            callback(opt)
            expanded = false
            dropdownBusy = true
            pcall(function()
                SafeTween(frame, {Size = UDim2.new(1, -6, 0, isMobile and 52 or 44)}, 0.2)
            end)
            arrow.Text = "▼"
            if dropdownResetTimer then task.cancel(dropdownResetTimer) end
            dropdownResetTimer = task.delay(0.3, function()
                if not expanded then list.Visible = false end
                dropdownBusy = false
                dropdownResetTimer = nil
            end)
        end)
    end

    Janitor:Connect(display.MouseButton1Click, function()
        if dropdownBusy then return end
        expanded = not expanded
        if expanded then
            list.Visible = true
            pcall(function()
                SafeTween(frame, {Size = UDim2.new(1, -6, 0, (isMobile and 52 or 44) + list.Size.Y.Offset)}, 0.2)
            end)
            arrow.Text = "▲"
        else
            pcall(function()
                SafeTween(frame, {Size = UDim2.new(1, -6, 0, isMobile and 52 or 44)}, 0.2)
            end)
            arrow.Text = "▼"
            if dropdownResetTimer then task.cancel(dropdownResetTimer) end
            dropdownResetTimer = task.delay(0.3, function()
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

CreateToggle(combatScroll, "Auto Headshot", false, function(v)
    Features.AutoHeadshot = v
end)

CreateDropdown(combatScroll, "Aim Mode", {"FOV Trigger", "Hold to Aim"}, "FOV Trigger", function(v)
    Features.AimMode = v
    -- Reset aim state when switching modes
    Features.AimActive = false
    targetSnapshot = nil
    targetSnapshotPlayer = nil
end)

CreateSlider(combatScroll, "Aim Strength", 0, 100, 100, function(v)
    Features.AimStrength = v
end, "%")

CreateSlider(combatScroll, "Smoothness", 0, 100, 0, function(v)
    Features.AimSmoothness = v
end, "%")

CreateSlider(combatScroll, "Prediction", 0, 250, 0, function(v)
    Features.PredictionMs = v
end, "ms")

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

CreateToggle(visualScroll, "Team Check", false, function(v)
    Features.TeamCheck = v
end)

CreateToggle(visualScroll, "Always Show FOV", true, function(v)
    Features.AlwaysShowFOV = v
end)

CreateSlider(visualScroll, "Line Thickness", 1, 5, 2, function(v)
    Features.ESPThickness = v
    ThicknessSettings.Skeleton = v * 0.75
    ThicknessSettings.Tracer = v * 0.75
    ThicknessSettings.Box = v
    ThicknessSettings.Line = v * 0.75
end, "")

CreateSlider(visualScroll, "Render Distance", 100, 3000, 1500, function(v)
    Features.RenderDistance = v
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
    if FOVCircle then
        FOVCircle.Color = Features.ESPColor
    end
end)

-- =============================================
-- DRAG
-- =============================================
local isDraggingWindow = false
local isDraggingIcon = false
local dragStart = nil
local dragStartPos = nil
local iconDragDelta = Vector2.zero
local IconMoved = false

Janitor:Connect(icon.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if CurrentLock == InteractionLock.None then
            CurrentLock = InteractionLock.Icon
            isDraggingIcon = true
            dragStart = input.Position
            dragStartPos = icon.Position
            iconDragDelta = Vector2.zero
            IconMoved = false
        end
    end
end)

Janitor:Connect(topBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if CurrentLock == InteractionLock.None then
            CurrentLock = InteractionLock.Window
            isDraggingWindow = true
            dragStart = input.Position
            dragStartPos = main.Position
        end
    end
end)

Janitor:Connect(UIS.InputChanged, function(input)
    if not isDraggingWindow and not isDraggingIcon then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local delta = input.Position - dragStart

    if isDraggingIcon then
        iconDragDelta = delta
        if delta.Magnitude > 5 then
            IconMoved = true
        end
        icon.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    elseif isDraggingWindow then
        main.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    end
end)

Janitor:Connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingWindow = false
        isDraggingIcon = false
        if CurrentLock == InteractionLock.Window or CurrentLock == InteractionLock.Icon then
            CurrentLock = InteractionLock.None
        end
    end
end)

Janitor:Connect(icon.MouseButton1Click, function()
    if IconMoved then
        IconMoved = false
        return
    end
    main.Visible = not main.Visible
end)

-- =============================================
-- PC AIM INPUT (Hold to Aim mode only)
-- =============================================
if isPC then
    Janitor:Connect(UIS.InputBegan, function(input, gameProcessed)
        if Features.AimMode == "Hold to Aim" and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
            Features.AimActive = true
        end
    end)

    Janitor:Connect(UIS.InputEnded, function(input)
        if Features.AimMode == "Hold to Aim" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            Features.AimActive = false
            targetSnapshot = nil
            targetSnapshotPlayer = nil
        end
    end)
end

-- =============================================
-- MOBILE AIM (Hold to Aim mode only)
-- =============================================
if isMobile then
    local aimBtn = Instance.new("TextButton")
    aimBtn.Name = "AimButton"
    aimBtn.Size = UDim2.new(0, 70, 0, 70)
    aimBtn.Position = UDim2.new(1, -90, 1, -140)
    aimBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    aimBtn.BackgroundTransparency = 0.3
    aimBtn.Text = "AIM"
    aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimBtn.Font = Enum.Font.GothamBold
    aimBtn.TextSize = 14
    aimBtn.Parent = gui
    NewCorner(aimBtn, 35)

    local aimBtnStroke = Instance.new("UIStroke")
    aimBtnStroke.Color = Color3.fromRGB(0, 170, 255)
    aimBtnStroke.Thickness = 2
    aimBtnStroke.Parent = aimBtn

    Janitor:Connect(aimBtn.InputBegan, function(input)
        if Features.AimMode == "Hold to Aim" and input.UserInputType == Enum.UserInputType.Touch then
            Features.AimActive = true
            SafeTween(aimBtn, {BackgroundTransparency = 0}, 0.1)
        end
    end)

    Janitor:Connect(aimBtn.InputEnded, function(input)
        if Features.AimMode == "Hold to Aim" and input.UserInputType == Enum.UserInputType.Touch then
            Features.AimActive = false
            targetSnapshot = nil
            targetSnapshotPlayer = nil
            SafeTween(aimBtn, {BackgroundTransparency = 0.3}, 0.1)
        end
    end)
end

-- =============================================
-- WINDOW BUTTONS
-- =============================================
local minimized = false
Janitor:Connect(minBtn.MouseButton1Click, function()
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

Janitor:Connect(hideBtn.MouseButton1Click, function()
    main.Visible = false
end)

-- =============================================
-- EXIT CLEANUP
-- =============================================
Janitor:Connect(exitBtn.MouseButton1Click, function()
    if FOVCircle then
        FOVCircle.Visible = false
    end

    Janitor:Cleanup()
    targetSnapshot = nil
    targetSnapshotPlayer = nil

    for player, _ in pairs(ESP) do
        if PlayerHealthConnections[player] then
            PlayerHealthConnections[player] = nil
        end
    end
    ESP = {}

    pcall(function() gui:Destroy() end)
end)

-- =============================================
-- DRAWING
-- =============================================
local function NewLine()
    if not Executor.Drawing then return nil end
    local line = Drawing.new("Line")
    line.Visible = false
    line.Transparency = 1
    line.Thickness = 1.5
    return Janitor:AddDrawing(line)
end

local FOVCircle
if Executor.Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Color = Features.ESPColor
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Radius = Features.AimFOV
    FOVCircle.Transparency = 1
    Janitor:AddDrawing(FOVCircle)
end

-- =============================================
-- SKELETON
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
-- ESP SETUP
-- =============================================
local PlayerHealthConnections = {}
local PlayerSkeletonParts = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    if not Executor.Drawing then return end

    local char = player.Character
    local skeletonCount = 5
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
        SkeletonCount = skeletonCount,
    }

    local function CacheSkeletonParts(char)
        if not char then return end
        local parts = {}
        local connections = GetSkeleton(char)
        for _, bones in ipairs(connections) do
            local p0 = char:FindFirstChild(bones[1])
            local p1 = char:FindFirstChild(bones[2])
            table.insert(parts, {p0, p1})
        end
        PlayerSkeletonParts[player] = parts
    end

    local function SetupHealth(expectedChar)
        if PlayerHealthConnections[player] then
            for _, conn in ipairs(PlayerHealthConnections[player]) do
                pcall(function() conn:Disconnect() end)
            end
        end
        PlayerHealthConnections[player] = {}

        local char = player.Character
        if char ~= expectedChar then return end
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local healthConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
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
        table.insert(PlayerHealthConnections[player], healthConn)

        local diedConn = hum.Died:Connect(function()
            local data = ESP[player]
            if data then
                data.IsDead = true
                data.Tracer.Visible = false
                data.Line.Visible = false
                for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
                for _, l in pairs(data.Box) do if l then l.Visible = false end end
            end
        end)
        table.insert(PlayerHealthConnections[player], diedConn)
    end

    CacheSkeletonParts(char)
    SetupHealth(char)

    Janitor:Connect(player.CharacterAdded, function(newChar)
        if not newChar or not newChar.Parent then return end

        -- Clear bounding box cache on respawn
        BoundingBoxCache[player] = nil

        local data = ESP[player]
        if data then
            data.IsDead = false
            local newSkel = GetSkeleton(newChar)
            local newCount = #newSkel
            if newCount ~= data.SkeletonCount then
                for _, l in pairs(data.Skeleton) do
                    if l then Janitor:RemoveDrawing(l) end
                end
                data.Skeleton = {}
                for i = 1, newCount do data.Skeleton[i] = NewLine() end
                data.SkeletonCount = newCount
            end
        end

        CacheSkeletonParts(newChar)

        task.delay(0.5, function()
            SetupHealth(newChar)
        end)
    end)
end

local function RemoveESP(player)
    if PlayerHealthConnections[player] then
        for _, conn in ipairs(PlayerHealthConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
        PlayerHealthConnections[player] = nil
    end
    PlayerSkeletonParts[player] = nil
    BoundingBoxCache[player] = nil

    local data = ESP[player]
    if not data then return end
    for _, l in pairs(data.Skeleton) do if l then Janitor:RemoveDrawing(l) end end
    if data.Tracer then Janitor:RemoveDrawing(data.Tracer) end
    for _, l in pairs(data.Box) do if l then Janitor:RemoveDrawing(l) end end
    if data.Line then Janitor:RemoveDrawing(data.Line) end
    ESP[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Janitor:Connect(Players.PlayerAdded, CreateESP)
Janitor:Connect(Players.PlayerRemoving, RemoveESP)

-- =============================================
-- AIM TARGETING
-- =============================================
local function GetBestTarget()
    if #CachedTargets == 0 then return nil, nil end

    local bestScore = math.huge
    local bestTarget = nil
    local bestPlayer = nil

    for _, target in ipairs(CachedTargets) do
        if not target.Head or not target.Head.Parent then
            continue
        end
        if not target.HRP or not target.HRP.Parent then
            continue
        end
        if not target.Humanoid or target.Humanoid.Health <= 0 then
            continue
        end

        local crosshairWeight = target.DistFromCenter * 0.7
        local distanceWeight = (target.Distance / 10) * 0.2
        local velocityPenalty = target.Velocity.Magnitude * 0.1

        local score = crosshairWeight + distanceWeight + velocityPenalty

        if score < bestScore then
            if IsVisibleCached(target.Head, target.Character) then
                bestScore = score
                bestTarget = target.Head
                bestPlayer = target.Player
            end
        end
    end

    return bestTarget, bestPlayer
end

-- =============================================
-- RENDER LOOP
-- =============================================
local LastESP = 0
local ESPThrottle = 0.016
local LastTargetScan = 0
local TargetScanInterval = 0.25

local RenderSnapshots = {}

local SmoothedFPS = 60

local function UpdateESPThrottle(dt)
    local instantFPS = dt > 0 and (1 / dt) or 60
    SmoothedFPS = SmoothedFPS * 0.9 + instantFPS * 0.1

    if SmoothedFPS < 30 then
        ESPThrottle = 0.05
    elseif SmoothedFPS < 45 then
        ESPThrottle = 0.033
    elseif SmoothedFPS < 60 then
        ESPThrottle = 0.025
    else
        ESPThrottle = 0.016
    end
end

-- Bounding box cache
local BoundingBoxCache = {}
local BoundingBoxCacheInterval = 0.2
local LastBoundingBoxUpdate = 0

local function UpdateBoundingBoxCache(now)
    if now - LastBoundingBoxUpdate < BoundingBoxCacheInterval then return end
    LastBoundingBoxUpdate = now

    for player, data in pairs(ESP) do
        if data.IsDead then
            BoundingBoxCache[player] = nil
            continue
        end
        local char = player.Character
        if char then
            local success, cf, size = pcall(function()
                return char:GetBoundingBox()
            end)
            if success and cf and size then
                BoundingBoxCache[player] = {
                    CFrame = cf,
                    Size = size,
                    Time = now,
                }
            else
                BoundingBoxCache[player] = nil
            end
        else
            BoundingBoxCache[player] = nil
        end
    end
end

Janitor:Connect(RunService.RenderStepped, function(dt)
    local now = tick()

    UpdateESPThrottle(dt)

    -- =============================================
    -- TARGET CACHE UPDATE
    -- =============================================
    if now - LastTargetScan >= TargetScanInterval then
        LastTargetScan = now
        UpdateTargetCache()
    end

    -- Update bounding box cache
    UpdateBoundingBoxCache(now)

    -- Update FOV circle
    if FOVCircle then
        FOVCircle.NumSides = Features.AimFOV < 80 and 32 or (Features.AimFOV < 160 and 48 or 64)
    end

    -- =============================================
    -- AIMBOT STATE MANAGEMENT
    -- =============================================
    -- Validate current target
    if targetSnapshot and targetSnapshotPlayer then
        local char = targetSnapshotPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")

        if not hum or hum.Health <= 0 or not head or head ~= targetSnapshot then
            targetSnapshot = nil
            targetSnapshotPlayer = nil
        else
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then
                targetSnapshot = nil
                targetSnapshotPlayer = nil
            elseif not IsVisibleCached(head, char) then
                targetSnapshot = nil
                targetSnapshotPlayer = nil
            end
        end
    end

    -- FOV Trigger mode: auto-acquire target when enemy enters FOV
    if Features.AimMode == "FOV Trigger" and Features.AimAssist then
        if not targetSnapshot then
            local head, player = GetBestTarget()
            if head and player then
                targetSnapshot = head
                targetSnapshotPlayer = player
                Features.AimActive = true
            else
                Features.AimActive = false
            end
        else
            -- Keep AimActive true as long as we have a valid target
            Features.AimActive = true
        end
    end

    -- =============================================
    -- AIM EXECUTION
    -- =============================================
    if Features.AimAssist and Features.AimActive and targetSnapshot then
        -- FIX: Smoothness is now correct — 0% = instant, 100% = very smooth
        -- Strength controls how much of the delta we apply per frame
        local strengthFactor = Features.AimStrength / 100
        local smoothFactor = math.clamp(1 - (Features.AimSmoothness / 100), 0.001, 1.0)

        -- Combined alpha: strength * smoothness, with FPS compensation
        local baseAlpha = strengthFactor * smoothFactor
        local fpsCompensatedAlpha = math.clamp(baseAlpha * (dt * 60), 0.001, 1.0)

        -- Auto Headshot: always aim at head position
        local aimTarget = targetSnapshot
        if Features.AutoHeadshot and targetSnapshotPlayer then
            local char = targetSnapshotPlayer.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head and head.Parent then
                    aimTarget = head
                end
            end
        end

        if aimTarget and aimTarget.Parent then
            local predictedPos = aimTarget.Position
            if Features.PredictionMs > 0 then
                local hrp = aimTarget.Parent:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
                    predictedPos = aimTarget.Position + (vel * (Features.PredictionMs / 1000))
                end
            end

            local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, fpsCompensatedAlpha)
        end
    end

    -- =============================================
    -- FOV CIRCLE VISIBILITY
    -- =============================================
    if Executor.Drawing and FOVCircle then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = Features.AimFOV
        FOVCircle.Color = Features.ESPColor

        if Features.AlwaysShowFOV then
            FOVCircle.Visible = Features.AimAssist
        else
            FOVCircle.Visible = Features.AimAssist and Features.AimActive
        end
    end

    -- =============================================
    -- ESP (Throttled)
    -- =============================================
    if now - LastESP < ESPThrottle then return end
    LastESP = now
    if not Executor.Drawing then return end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    table.clear(RenderSnapshots)

    for player, data in pairs(ESP) do
        data.Tracer.Visible = false
        data.Line.Visible = false
        for _, l in pairs(data.Skeleton) do if l then l.Visible = false end end
        for _, l in pairs(data.Box) do if l then l.Visible = false end end

        if data.IsDead then continue end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not char or not hum or hum.Health <= 0 or not hrp or not head then
            continue
        end

        -- Team check in render
        if Features.TeamCheck then
            local myTeam = LocalPlayer.Team
            local theirTeam = player.Team
            if myTeam ~= nil and theirTeam ~= nil and theirTeam == myTeam then
                continue
            end
        end

        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not rootOnScreen or rootPos.Z < 0 then
            continue
        end

        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        if not headOnScreen or headPos.Z < 0 then
            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude

        table.insert(RenderSnapshots, {
            Player = player,
            Data = data,
            Character = char,
            Head = head,
            HRP = hrp,
            RootPos = rootPos,
            HeadPos = headPos,
            Distance = distance,
        })
    end

    for _, snap in ipairs(RenderSnapshots) do
        local data = snap.Data
        local char = snap.Character
        local head = snap.Head
        local hrp = snap.HRP
        local rootPos = snap.RootPos
        local headPos = snap.HeadPos
        local distance = snap.Distance

        local distScale = math.clamp(3.5 - (distance / 300), 0.5, 3.5)
        local color = Features.ESPColor

        -- SKELETON
        if Features.SkeletonESP then
            local cachedParts = PlayerSkeletonParts[snap.Player]
            if cachedParts then
                for i, parts in ipairs(cachedParts) do
                    local p0 = parts[1]
                    local p1 = parts[2]
                    local line = data.Skeleton[i]
                    if p0 and p0.Parent and p1 and p1.Parent and line then
                        local v0, vis0 = Camera:WorldToViewportPoint(p0.Position)
                        local v1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        if vis0 and vis1 and v0.Z > 0 and v1.Z > 0 then
                            line.From = Vector2.new(v0.X, v0.Y)
                            line.To = Vector2.new(v1.X, v1.Y)
                            line.Color = color
                            line.Thickness = ThicknessSettings.Skeleton * distScale
                            line.Visible = true
                        end
                    end
                end
            end
        end

        -- TRACER
        if Features.TracerESP and myRoot then
            local myPos, myVis = Camera:WorldToViewportPoint(myRoot.Position + Vector3.new(0, 2, 0))
            if myVis and myPos.Z > 0 then
                data.Tracer.From = Vector2.new(myPos.X, myPos.Y)
                data.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                data.Tracer.Color = color
                data.Tracer.Thickness = ThicknessSettings.Tracer * distScale
                data.Tracer.Visible = true
            end
        end

        -- BOX ESP
        if Features.BoxESP then
            local boxCache = BoundingBoxCache[snap.Player]
            if boxCache and boxCache.CFrame and boxCache.Size then
                local cf = boxCache.CFrame
                local size = boxCache.Size

                local corners = {
                    cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                    cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                    cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                    cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                    cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                    cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                    cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                    cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                }

                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                local anyVisible = false

                for _, cornerCF in ipairs(corners) do
                    local pos, onScreen = Camera:WorldToViewportPoint(cornerCF.Position)
                    if onScreen and pos.Z > 0 then
                        anyVisible = true
                        minX = math.min(minX, pos.X)
                        minY = math.min(minY, pos.Y)
                        maxX = math.max(maxX, pos.X)
                        maxY = math.max(maxY, pos.Y)
                    end
                end

                if anyVisible then
                    data.Box[1].From = Vector2.new(minX, minY)
                    data.Box[1].To = Vector2.new(maxX, minY)
                    data.Box[1].Color = color
                    data.Box[1].Thickness = ThicknessSettings.Box * distScale
                    data.Box[1].Visible = true

                    data.Box[2].From = Vector2.new(maxX, minY)
                    data.Box[2].To = Vector2.new(maxX, maxY)
                    data.Box[2].Color = color
                    data.Box[2].Thickness = ThicknessSettings.Box * distScale
                    data.Box[2].Visible = true

                    data.Box[3].From = Vector2.new(maxX, maxY)
                    data.Box[3].To = Vector2.new(minX, maxY)
                    data.Box[3].Color = color
                    data.Box[3].Thickness = ThicknessSettings.Box * distScale
                    data.Box[3].Visible = true

                    data.Box[4].From = Vector2.new(minX, maxY)
                    data.Box[4].To = Vector2.new(minX, minY)
                    data.Box[4].Color = color
                    data.Box[4].Thickness = ThicknessSettings.Box * distScale
                    data.Box[4].Visible = true
                end
            else
                -- Fallback
                local legPos, legVis = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                if legVis and legPos.Z > 0 then
                    local boxHeight = math.abs(headPos.Y - legPos.Y)
                    local boxWidth = boxHeight * 0.6
                    local centerX = rootPos.X
                    local topY = headPos.Y - boxHeight * 0.1
                    local botY = legPos.Y

                    data.Box[1].From = Vector2.new(centerX - boxWidth/2, topY)
                    data.Box[1].To = Vector2.new(centerX + boxWidth/2, topY)
                    data.Box[1].Color = color
                    data.Box[1].Thickness = ThicknessSettings.Box * distScale
                    data.Box[1].Visible = true

                    data.Box[2].From = Vector2.new(centerX + boxWidth/2, topY)
                    data.Box[2].To = Vector2.new(centerX + boxWidth/2, botY)
                    data.Box[2].Color = color
                    data.Box[2].Thickness = ThicknessSettings.Box * distScale
                    data.Box[2].Visible = true

                    data.Box[3].From = Vector2.new(centerX + boxWidth/2, botY)
                    data.Box[3].To = Vector2.new(centerX - boxWidth/2, botY)
                    data.Box[3].Color = color
                    data.Box[3].Thickness = ThicknessSettings.Box * distScale
                    data.Box[3].Visible = true

                    data.Box[4].From = Vector2.new(centerX - boxWidth/2, botY)
                    data.Box[4].To = Vector2.new(centerX - boxWidth/2, topY)
                    data.Box[4].Color = color
                    data.Box[4].Thickness = ThicknessSettings.Box * distScale
                    data.Box[4].Visible = true
                end
            end
        end

        -- LINE ESP
        if Features.LineESP then
            local bottomOffset = isMobile and 120 or 80
            data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - bottomOffset)
            data.Line.To = Vector2.new(rootPos.X, rootPos.Y)
            data.Line.Color = color
            data.Line.Thickness = ThicknessSettings.Line * distScale
            data.Line.Visible = true
        end
    end
end)

-- =============================================
-- LOCK DEADLOCK FAILSAFE
-- =============================================
Janitor:AddThread(task.spawn(function()
    while gui and gui.Parent do
        task.wait(3)
        if CurrentLock ~= InteractionLock.None then
            local anyInput = false
            for _, input in ipairs(UIS:GetMouseButtonsPressed()) do
                anyInput = true
                break
            end
            if not anyInput and isMobile then
                for _, touch in ipairs(UIS:GetTouches()) do
                    anyInput = true
                    break
                end
            end
            if not anyInput then
                CurrentLock = InteractionLock.None
                ActiveSliderId = nil
                isDraggingWindow = false
                isDraggingIcon = false
            end
        end
    end
end))
