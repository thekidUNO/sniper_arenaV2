# Modern UNO HUB

```lua
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

local SkeletonESP = false
local TracerESP = false
local AimAssist = false

local AimStrength = 35
local AimFOV = 140

-------------------------------------------------
-- GUI
-------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "UnoModernHub"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local icon = Instance.new("ImageButton")
icon.Size = UDim2.new(0,58,0,58)
icon.Position = UDim2.new(0,20,0.5,-29)
icon.BackgroundColor3 = Color3.fromRGB(15,15,15)
icon.Image = "rbxassetid://7733960981"
icon.AutoButtonColor = false
icon.Parent = gui

Instance.new("UICorner", icon).CornerRadius = UDim.new(1,0)

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(0,170,255)
iconStroke.Thickness = 2
iconStroke.Parent = icon

local main = Instance.new("Frame")
main.Size = UDim2.new(0,370,0,300)
main.Position = UDim2.new(0.5,-185,0.5,-150)
main.BackgroundColor3 = Color3.fromRGB(12,12,12)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0,170,255)
stroke.Thickness = 2
stroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1,0,0,42)
top.BackgroundTransparency = 1
top.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6,0,1,0)
title.Position = UDim2.new(0,14,0,0)
title.BackgroundTransparency = 1
title.Text = "UNO HUB"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local function TopButton(txt,x,color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,28,0,28)
    b.Position = UDim2.new(1,x,0,7)
    b.Text = txt
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.BackgroundColor3 = color
    b.Parent = top

    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)

    return b
end

local minimize = TopButton("-",-96,Color3.fromRGB(40,40,40))
local hide = TopButton("O",-62,Color3.fromRGB(40,40,40))
local exit = TopButton("X",-28,Color3.fromRGB(255,70,70))

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-20,1,-56)
content.Position = UDim2.new(0,10,0,46)
content.BackgroundTransparency = 1
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,10)
layout.Parent = content

local function CreateToggle(name,callback)

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,48)
    holder.BackgroundColor3 = Color3.fromRGB(18,18,18)
    holder.BorderSizePixel = 0
    holder.Parent = content

    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,12)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0.6,0,1,0)
    txt.Position = UDim2.new(0,14,0,0)
    txt.BackgroundTransparency = 1
    txt.Text = name
    txt.TextColor3 = Color3.fromRGB(255,255,255)
    txt.Font = Enum.Font.GothamMedium
    txt.TextScaled = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = holder

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0,52,0,26)
    toggle.Position = UDim2.new(1,-66,0.5,-13)
    toggle.Text = ""
    toggle.BackgroundColor3 = Color3.fromRGB(45,45,45)
    toggle.Parent = holder

    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,22,0,22)
    knob.Position = UDim2.new(0,2,0.5,-11)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Parent = toggle

    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local state = false

    toggle.MouseButton1Click:Connect(function()

        state = not state

        if state then

            TweenService:Create(toggle,TweenInfo.new(0.2),{
                BackgroundColor3 = Color3.fromRGB(0,170,255)
            }):Play()

            TweenService:Create(knob,TweenInfo.new(0.2),{
                Position = UDim2.new(1,-24,0.5,-11)
            }):Play()

        else

            TweenService:Create(toggle,TweenInfo.new(0.2),{
                BackgroundColor3 = Color3.fromRGB(45,45,45)
            }):Play()

            TweenService:Create(knob,TweenInfo.new(0.2),{
                Position = UDim2.new(0,2,0.5,-11)
            }):Play()
        end

        callback(state)
    end)
end

CreateToggle("Skeleton ESP",function(v)
    SkeletonESP = v
end)

CreateToggle("Tracer ESP",function(v)
    TracerESP = v
end)

CreateToggle("Aim Assist",function(v)
    AimAssist = v
end)

local sliderHolder = Instance.new("Frame")
sliderHolder.Size = UDim2.new(1,0,0,58)
sliderHolder.BackgroundColor3 = Color3.fromRGB(18,18,18)
sliderHolder.BorderSizePixel = 0
sliderHolder.Parent = content

Instance.new("UICorner", sliderHolder).CornerRadius = UDim.new(0,12)

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(1,-20,0,20)
sliderLabel.Position = UDim2.new(0,12,0,6)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "Aim Strength : 35"
sliderLabel.TextColor3 = Color3.fromRGB(255,255,255)
sliderLabel.Font = Enum.Font.GothamMedium
sliderLabel.TextScaled = true
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = sliderHolder

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1,-24,0,12)
sliderBack.Position = UDim2.new(0,12,0,34)
sliderBack.BackgroundColor3 = Color3.fromRGB(40,40,40)
sliderBack.Parent = sliderHolder

Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1,0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.35,0,1,0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
sliderFill.Parent = sliderBack

Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1,0)

local draggingSlider = false

sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

UIS.InputChanged:Connect(function(input)

    if draggingSlider then

        local mouseX = UIS:GetMouseLocation().X
        local pos = sliderBack.AbsolutePosition.X
        local size = sliderBack.AbsoluteSize.X

        local percent = math.clamp((mouseX - pos) / size,0,1)

        sliderFill.Size = UDim2.new(percent,0,1,0)

        AimStrength = math.floor(percent * 100)

        sliderLabel.Text = "Aim Strength : "..AimStrength
    end
end)

-------------------------------------------------
-- DRAGGING
-------------------------------------------------

local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)

    local delta = input.Position - dragStart

    main.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

top.InputBegan:Connect(function(input)

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

top.InputChanged:Connect(function(input)
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
-- WINDOW BUTTONS
-------------------------------------------------

icon.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

local minimized = false

minimize.MouseButton1Click:Connect(function()

    minimized = not minimized

    if minimized then

        content.Visible = false

        TweenService:Create(main,TweenInfo.new(0.2),{
            Size = UDim2.new(0,370,0,44)
        }):Play()

    else

        content.Visible = true

        TweenService:Create(main,TweenInfo.new(0.2),{
            Size = UDim2.new(0,370,0,300)
        }):Play()
    end
end)

hide.MouseButton1Click:Connect(function()
    main.Visible = false
end)

exit.MouseButton1Click:Connect(function()

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
-- DRAWING
-------------------------------------------------

local function NewLine()

    local line = Drawing.new("Line")

    line.Visible = false
    line.Transparency = 1
    line.Thickness = 1.5

    return line
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Color = Color3.fromRGB(0,170,255)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Radius = AimFOV

-------------------------------------------------
-- SKELETONS
-------------------------------------------------

local R15Skeleton = {
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

local R6Skeleton = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local function GetSkeleton(character)

    if character:FindFirstChild("UpperTorso") then
        return R15Skeleton
    end

    return R6Skeleton
end

-------------------------------------------------
-- ESP SETUP
-------------------------------------------------

local function CreateESP(player)

    if player == LocalPlayer then
        return
    end

    local skeleton = {}

    for i = 1,14 do
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
-- AIM TARGET
-------------------------------------------------

local function GetClosestPlayer()

    local closest = nil
    local shortest = AimFOV

    for _,player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer then

            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then

                local pos,visible = Camera:WorldToViewportPoint(head.Position)

                if visible then

                    local dist = (
                        Vector2.new(pos.X,pos.Y)
                        - UIS:GetMouseLocation()
                    ).Magnitude

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

-------------------------------------------------
-- RENDER
-------------------------------------------------

RunService.RenderStepped:Connect(function()

    local mousePos = UIS:GetMouseLocation()

    FOVCircle.Position = mousePos

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

            local SkeletonConnections = GetSkeleton(char)

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

                data.Tracer.From = Vector2.new(myPos.X,myPos.Y)
                data.Tracer.To = Vector2.new(rootPos.X,rootPos.Y)

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

    -------------------------------------------------
    -- AIM ASSIST
    -------------------------------------------------

    if AimAssist then

        local target = GetClosestPlayer()

        if target then

            local predicted = target.Position

            local smoothness = math.clamp(
                AimStrength / 100,
                0.03,
                1
            )

            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(
                    Camera.CFrame.Position,
                    predicted
                ),
                smoothness * 0.12
            )
        end
    end
end)
```
