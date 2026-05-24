local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local SkeletonESP = false
local TracerESP = false
local Aimbot = false

local AimStrength = 50
local Sliding = false

local ESP = {}

local gui = Instance.new("ScreenGui")
gui.Name = "UnoHub"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,190,0,190)
frame.Position = UDim2.new(0,120,0,200)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0,170,255)
stroke.Thickness = 2
stroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundTransparency = 1
titleBar.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "UNO HUB"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = titleBar

local function CreateButton(text,y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85,0,0,30)
    btn.Position = UDim2.new(0.075,0,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.Text = text .. " : OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Parent = frame

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    return btn
end

local skeletonBtn = CreateButton("SKELETON",40)
local tracerBtn = CreateButton("TRACER",75)
local aimbotBtn = CreateButton("AIMBOT",110)

local sliderText = Instance.new("TextLabel")
sliderText.Size = UDim2.new(0.85,0,0,18)
sliderText.Position = UDim2.new(0.075,0,0,142)
sliderText.BackgroundTransparency = 1
sliderText.Text = "AIM STRENGTH : 50"
sliderText.TextColor3 = Color3.fromRGB(255,255,255)
sliderText.Font = Enum.Font.GothamBold
sliderText.TextScaled = true
sliderText.Parent = frame

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(0.85,0,0,12)
sliderBack.Position = UDim2.new(0.075,0,0,165)
sliderBack.BackgroundColor3 = Color3.fromRGB(40,40,40)
sliderBack.Parent = frame

Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1,0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5,0,1,0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
sliderFill.Parent = sliderBack

Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1,0)

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(1,0,1,0)
sliderButton.BackgroundTransparency = 1
sliderButton.Text = ""
sliderButton.Parent = sliderBack

local dragging = false
local dragInput
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)

    if Sliding then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

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

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)

    if dragging and input == dragInput then

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    if Sliding then

        local mouseX = UIS:GetMouseLocation().X

        local pos = sliderBack.AbsolutePosition.X
        local size = sliderBack.AbsoluteSize.X

        local percent = math.clamp((mouseX - pos) / size,0,1)

        AimStrength = math.floor(percent * 100)

        sliderFill.Size = UDim2.new(percent,0,1,0)
        sliderText.Text = "AIM STRENGTH : "..AimStrength
    end
end)

sliderButton.MouseButton1Down:Connect(function()
    Sliding = true
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        Sliding = false
    end
end)

local function UpdateButton(btn,state)

    if state then
        btn.Text = btn.Text:gsub("OFF","ON")
        btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
    else
        btn.Text = btn.Text:gsub("ON","OFF")
        btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    end
end

skeletonBtn.MouseButton1Click:Connect(function()
    SkeletonESP = not SkeletonESP
    UpdateButton(skeletonBtn,SkeletonESP)
end)

tracerBtn.MouseButton1Click:Connect(function()
    TracerESP = not TracerESP
    UpdateButton(tracerBtn,TracerESP)
end)

aimbotBtn.MouseButton1Click:Connect(function()
    Aimbot = not Aimbot
    UpdateButton(aimbotBtn,Aimbot)
end)

local function NewLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Transparency = 1
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
    {"RightLowerLeg","RightFoot"},
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

for _,p in ipairs(Players:GetPlayers()) do
    CreateESP(p)
end

Players.PlayerAdded:Connect(CreateESP)

local function GetClosestPlayer()

    local Closest = nil
    local ClosestDistance = math.huge

    for _,player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer then

            local char = player.Character

            if char then

                local hum = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")

                if hum and hum.Health > 0 and head then

                    local pos,visible = Camera:WorldToViewportPoint(head.Position)

                    if visible then

                        local dist = (
                            Vector2.new(pos.X,pos.Y) -
                            Vector2.new(Mouse.X,Mouse.Y)
                        ).Magnitude

                        if dist < ClosestDistance then
                            ClosestDistance = dist
                            Closest = head
                        end
                    end
                end
            end
        end
    end

    return Closest
end

RunService.RenderStepped:Connect(function()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player,data in pairs(ESP) do

        local char = player.Character

        if not char then
            continue
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not hum or hum.Health <= 0 or not hrp then
            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        local thickness = math.clamp(5 - (distance / 200),1,5)

        local color = Color3.fromHSV(
            (tick() % 5) / 5,
            1,
            1
        )

        for i,bones in ipairs(SkeletonConnections) do

            local part0 = char:FindFirstChild(bones[1])
            local part1 = char:FindFirstChild(bones[2])

            local line = data.Skeleton[i]

            if SkeletonESP and part0 and part1 then

                local pos0,vis0 = Camera:WorldToViewportPoint(part0.Position)
                local pos1,vis1 = Camera:WorldToViewportPoint(part1.Position)

                if vis0 and vis1 then

                    line.From = Vector2.new(pos0.X,pos0.Y)
                    line.To = Vector2.new(pos1.X,pos1.Y)

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

        if TracerESP and myRoot then

            local myPos,myVisible = Camera:WorldToViewportPoint(myRoot.Position)
            local enemyPos,enemyVisible = Camera:WorldToViewportPoint(hrp.Position)

            if myVisible and enemyVisible then

                data.Tracer.From = Vector2.new(myPos.X,myPos.Y)
                data.Tracer.To = Vector2.new(enemyPos.X,enemyPos.Y)

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

    if Aimbot then

        local target = GetClosestPlayer()

        if target then

            local targetPos = Camera:WorldToViewportPoint(target.Position)

            local smoothness = math.clamp(AimStrength / 100,0.01,1)

            local moveX = (targetPos.X - Mouse.X) * smoothness * 0.15
            local moveY = (targetPos.Y - Mouse.Y) * smoothness * 0.15

            if mousemoverel then
                mousemoverel(moveX, moveY)
            end
        end
    end
end)
