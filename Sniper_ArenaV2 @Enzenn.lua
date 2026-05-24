# UNO HUB — Fixed GUI + Stable ESP

```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local ESP = {}

local SkeletonESP = false
local TracerESP = false

-------------------------------------------------
-- GUI
-------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "UnoHub"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local Open = true
local Minimized = false

local appButton = Instance.new("ImageButton")
appButton.Size = UDim2.new(0,60,0,60)
appButton.Position = UDim2.new(0,20,0.5,-30)
appButton.BackgroundColor3 = Color3.fromRGB(15,15,15)
appButton.Image = "rbxassetid://7733960981"
appButton.Parent = gui

Instance.new("UICorner", appButton).CornerRadius = UDim.new(1,0)

local appStroke = Instance.new("UIStroke")
appStroke.Color = Color3.fromRGB(0,170,255)
appStroke.Thickness = 2
appStroke.Parent = appButton

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,320,0,240)
frame.Position = UDim2.new(0.5,-160,0.5,-120)
frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0,170,255)
frameStroke.Thickness = 2
frameStroke.Parent = frame

local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1,0,0,36)
topbar.BackgroundTransparency = 1
topbar.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.5,0,1,0)
title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1
title.Text = "UNO HUB"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Parent = topbar

local function CreateTopButton(text,x,color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,28,0,28)
    b.Position = UDim2.new(1,x,0,4)
    b.Text = text
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.BackgroundColor3 = color
    b.Parent = topbar

    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)

    return b
end

local minimizeBtn = CreateTopButton("-",-96,Color3.fromRGB(35,35,35))
local hideBtn = CreateTopButton("O",-62,Color3.fromRGB(35,35,35))
local exitBtn = CreateTopButton("X",-28,Color3.fromRGB(255,70,70))

local container = Instance.new("Frame")
container.Size = UDim2.new(1,-20,1,-50)
container.Position = UDim2.new(0,10,0,40)
container.BackgroundTransparency = 1
container.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,10)
layout.Parent = container

local function CreateToggle(name)

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,42)
    holder.BackgroundColor3 = Color3.fromRGB(22,22,22)
    holder.BorderSizePixel = 0
    holder.Parent = container

    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,10)

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0.7,0,1,0)
    text.Position = UDim2.new(0,12,0,0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.TextColor3 = Color3.fromRGB(255,255,255)
    text.Font = Enum.Font.GothamMedium
    text.TextScaled = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = holder

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0,50,0,24)
    toggle.Position = UDim2.new(1,-62,0.5,-12)
    toggle.BackgroundColor3 = Color3.fromRGB(45,45,45)
    toggle.Text = ""
    toggle.Parent = holder

    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,20,0,20)
    knob.Position = UDim2.new(0,2,0.5,-10)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Parent = toggle

    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local state = false

    local function Set(v)
        state = v

        if state then
            TweenService:Create(toggle,TweenInfo.new(0.2),{
                BackgroundColor3 = Color3.fromRGB(0,170,255)
            }):Play()

            TweenService:Create(knob,TweenInfo.new(0.2),{
                Position = UDim2.new(1,-22,0.5,-10)
            }):Play()
        else
            TweenService:Create(toggle,TweenInfo.new(0.2),{
                BackgroundColor3 = Color3.fromRGB(45,45,45)
            }):Play()

            TweenService:Create(knob,TweenInfo.new(0.2),{
                Position = UDim2.new(0,2,0.5,-10)
            }):Play()
        end
    end

    toggle.MouseButton1Click:Connect(function()
        Set(not state)

        if name == "Skeleton ESP" then
            SkeletonESP = state
        elseif name == "Tracer ESP" then
            TracerESP = state
        end
    end)

    return holder
end

CreateToggle("Skeleton ESP")
CreateToggle("Tracer ESP")

-------------------------------------------------
-- DRAGGING
-------------------------------------------------

local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart

    frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-------------------------------------------------
-- BUTTONS
-------------------------------------------------

appButton.MouseButton1Click:Connect(function()

    Open = not Open

    frame.Visible = Open
end)

minimizeBtn.MouseButton1Click:Connect(function()

    Minimized = not Minimized

    if Minimized then
        container.Visible = false

        TweenService:Create(frame,TweenInfo.new(0.2),{
            Size = UDim2.new(0,320,0,40)
        }):Play()
    else
        container.Visible = true

        TweenService:Create(frame,TweenInfo.new(0.2),{
            Size = UDim2.new(0,320,0,240)
        }):Play()
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    Open = false
end)

exitBtn.MouseButton1Click:Connect(function()

    for _,data in pairs(ESP) do

        if data.Tracer then
            data.Tracer:Remove()
        end

        if data.Skeleton then
            for _,line in pairs(data.Skeleton) do
                line:Remove()
            end
        end
    end

    gui:Destroy()
end)

-------------------------------------------------
-- ESP
-------------------------------------------------

local function NewLine()

    local line = Drawing.new("Line")

    line.Visible = false
    line.Transparency = 1
    line.Thickness = 1.5

    return line
end

local SkeletonConnections = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"}
}

local function CreateESP(player)

    if player == LocalPlayer then
        return
    end

    local skeleton = {}

    for i = 1,#SkeletonConnections do
        skeleton[i] = NewLine()
    end

    local tracer = NewLine()

    ESP[player] = {
        Skeleton = skeleton,
        Tracer = tracer
    }
end

local function RemoveESP(player)

    local data = ESP[player]

    if not data then
        return
    end

    for _,line in pairs(data.Skeleton) do
        line:Remove()
    end

    data.Tracer:Remove()

    ESP[player] = nil
end

for _,player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-------------------------------------------------
-- RENDER
-------------------------------------------------

RunService.RenderStepped:Connect(function()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player,data in pairs(ESP) do

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not char or not hum or hum.Health <= 0 or not hrp then

            data.Tracer.Visible = false

            for _,line in pairs(data.Skeleton) do
                line.Visible = false
            end

            continue
        end

        local rootPos,onScreen = Camera:WorldToViewportPoint(hrp.Position)

        if not onScreen then

            data.Tracer.Visible = false

            for _,line in pairs(data.Skeleton) do
                line.Visible = false
            end

            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude

        local thickness = math.clamp(
            3 - (distance / 400),
            1,
            3
        )

        local color = Color3.fromRGB(0,170,255)

        -------------------------------------------------
        -- SKELETON
        -------------------------------------------------

        if SkeletonESP then

            for i,bones in ipairs(SkeletonConnections) do

                local p0 = char:FindFirstChild(bones[1])
                local p1 = char:FindFirstChild(bones[2])

                local line = data.Skeleton[i]

                if p0 and p1 then

                    local v0,vis0 = Camera:WorldToViewportPoint(p0.Position)
                    local v1,vis1 = Camera:WorldToViewportPoint(p1.Position)

                    if vis0 and vis1 then

                        line.From = Vector2.new(v0.X,v0.Y)
                        line.To = Vector2.new(v1.X,v1.Y)

                        line.Color = color
                        line.Thickness = thickness
                        line.Visible = true

                    else
                        line.Visible = false
                    end

                else
                    line.Visible = false
                end
            end

        else

            for _,line in pairs(data.Skeleton) do
                line.Visible = false
            end
        end

        -------------------------------------------------
        -- TRACER
        -------------------------------------------------

        if TracerESP and myRoot then

            local myPos,myVisible = Camera:WorldToViewportPoint(
                myRoot.Position + Vector3.new(0,2,0)
            )

            if myVisible then

                data.Tracer.From = Vector2.new(
                    myPos.X,
                    myPos.Y
                )

                data.Tracer.To = Vector2.new(
                    rootPos.X,
                    rootPos.Y
                )

                data.Tracer.Color = color
                data.Tracer.Thickness = thickness
                data.Tracer.Visible = true

            else
                data.Tracer.Visible = false
            end

        else
            data.Tracer.Visible = false
        end
    end
end)
```

This version fixes:

* broken skeleton flicker
* tracer stretching
* UI drag bugs
* hide/minimize issues
* full unload cleanup
* floating app icon
* smoother UI
* stable ESP rendering
* dead player cleanup
* cleaner modern look
