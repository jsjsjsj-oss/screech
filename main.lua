--[[Doors 全能辅助核心脚本]]
-- 加载配置
local Config = require(script.Parent.config)

-- 服务初始化
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- 玩家信息
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

-- ESP UI创建
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "DoorsESP"
ESPGui.Parent = CoreGui

-- 工具函数：创建ESP标签
local function createESPLabel(target, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, Config["esp-textsize"])
    label.Text = target.Name
    label.TextColor3 = color
    label.TextSize = Config["esp-textsize"]
    label.Font = Enum.Font.SourceSansBold
    label.BackgroundTransparency = 1
    label.Parent = ESPGui

    -- 追踪目标
    RunService.RenderStepped:Connect(function()
        if not target or not target.Parent then label:Destroy() return end
        local pos, onScreen = Camera:WorldToScreenPoint(target.Position)
        if onScreen then
            label.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
        else
            label.Visible = false
        end
    end)
    return label
end

-- 工具函数：创建追踪线
local function createTracer(target, color)
    local line = Instance.new("LineHandleAdornment")
    line.Adornee = RootPart
    line.ZIndex = 10
    line.Color3 = color
    line.Thickness = 2
    line.Parent = ESPGui

    RunService.RenderStepped:Connect(function()
        if not target or not target.Parent then line:Destroy() return end
        local pos = Camera:WorldToViewportPoint(target.Position)
        line.From = Vector3.new(0, 0, 0)
        line.To = Camera:ViewportPointToWorldPoint(Vector3.new(pos.X, pos.Y, Camera.NearPlaneDistance)) - RootPart.Position
    end)
    return line
end

-- 1. 上帝模式
if Config.Godmode then
    Humanoid.HealthChanged:Connect(function()
        Humanoid.Health = Humanoid.MaxHealth
    end)
    Humanoid.Died:Connect(function()
        Character = LocalPlayer.CharacterAdded:Wait()
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
    end)
end

-- 2. 飞行功能
local isFlying = Config.Fly
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode[Config["KeyF-fly"].key] then
        isFlying = not isFlying
        Humanoid.PlatformStand = isFlying
    end
end)

RunService.RenderStepped:Connect(function()
    if isFlying then
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir += Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir += Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir += Vector3.new(0, -1, 0) end
        
        RootPart.Velocity = moveDir.Unit * Config.FlySpeed
    end
end)

-- 3. 移动速度
if Config.WalkSpeed then
    Humanoid.WalkSpeed = Config.WalkSpeedVelocity
    Humanoid.JumpPower = Config.JumpBoost > 0 and Config.JumpBoost or Humanoid.JumpPower
end

-- 4. 全亮度
if Config.Fullbright then
    Lighting.Brightness = Config.Brightness
    Lighting.Contrast = 1
    Lighting.ColorShift_Top = Color3.new(1, 1, 1)
end

-- 5. 无雾
if Config.NoFog then
    Lighting.FogEnd = 10000
end

-- 6. ESP功能
RunService.RenderStepped:Connect(function()
    -- 门ESP
    if Config["Visual-esp-door"] then
        for _, door in ipairs(Workspace:GetDescendants()) do
            if door.Name:lower():find("door") and not door:FindFirstChild("Locked") then
                createESPLabel(door, Config["DoorEsp-color"])
                if Config["esp-tracers"] then createTracer(door, Config["DoorEsp-color"]) end
            end
        end
    end

    -- 物品ESP
    if Config["Visual-esp-item"] then
        for _, item in ipairs(Workspace:GetDescendants()) do
            if item.Name:lower():find("key") or item.Name:lower():find("item") then
                createESPLabel(item, Config["ItemEsp-color"])
                if Config["esp-tracers"] then createTracer(item, Config["ItemEsp-color"]) end
            end
        end
    end

    -- 金色物品ESP
    if Config["Visual-esp-gold"] then
        for _, gold in ipairs(Workspace:GetDescendants()) do
            if gold.Name:lower():find("gold") or gold.Name:lower():find("coin") then
                createESPLabel(gold, Config["GoldEsp-color"])
                if Config["esp-tracers"] then createTracer(gold, Config["GoldEsp-color"]) end
            end
        end
    end

    -- 实体ESP
    if Config["Visual-esp-entity"] then
        for _, entity in ipairs(Workspace:GetDescendants()) do
            if entity.Name:lower():find("screech") or entity.Name:lower():find("eyes") or entity.Name:lower():find("figure") then
                createESPLabel(entity, Config["EntityEsp-color"])
                if Config["esp-tracers"] then createTracer(entity, Config["EntityEsp-color"]) end
            end
        end
    end

    -- 玩家ESP
    if Config["Visual-esp-player"] then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    createESPLabel(playerRoot, Config["PlayerEsp-color"])
                    if Config["esp-tracers"] then createTracer(playerRoot, Config["PlayerEsp-color"]) end
                end
            end
        end
    end
end)

-- 7. 自动交互
local isAutoInteract = Config["Auto-interact"]
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode[Config["KeyP-autointeract"].key] then
        isAutoInteract = not isAutoInteract
    end
end)

spawn(function()
    while wait(0.1) do
        if isAutoInteract then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:FindFirstChild("ClickDetector") then
                    local dist = (RootPart.Position - obj.Position).Magnitude
                    if dist <= Config.MaxActivationDistance then
                        fireclickdetector(obj.ClickDetector)
                    end
                end
            end
        end
    end
end)

-- 8. 防惊吓（静音+隐藏）
if Config.AntiJumpscares then
    SoundService.Volume = 0.1
    -- 隐藏惊吓实体
    RunService.RenderStepped:Connect(function()
        for _, entity in ipairs(Workspace:GetDescendants()) do
            if entity.Name:lower():find("screech") or entity.Name:lower():find("jump") then
                entity.Transparency = 1
            end
        end
    end)
end

-- 9. 自动破解断路器
if Config.AutoBreakerSolver then
    local function solveBreaker()
        for _, breaker in ipairs(Workspace:GetDescendants()) do
            if breaker.Name:lower() == "breaker" and breaker:FindFirstChild("Button") then
                fireclickdetector(breaker.Button.ClickDetector)
            end
        end
    end
    solveBreaker()
    Workspace.DescendantAdded:Connect(function(desc)
        if desc.Name:lower() == "breaker" then solveBreaker() end
    end)
end

-- 10. 按键绑定：上帝模式切换
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode[Config.GodmodeKeybind.key] then
        Config.Godmode = not Config.Godmode
        if Config.Godmode then
            Humanoid.Health = Humanoid.MaxHealth
        end
    end
end)

-- 11. 按键绑定：第三人称切换
local isThirdPerson = Config.ThirdPerson
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode[Config["KeyC-ThirdPerson"].key] then
        isThirdPerson = not isThirdPerson
        Camera.CameraType = isThirdPerson and Enum.CameraType.Attach or Enum.CameraType.Custom
        if isThirdPerson then
            Camera.CFrame = RootPart.CFrame * CFrame.new(0, 2, 5)
        end
    end
end)

-- 12. 无镜头抖动
if Config.NoCamShake then
    Camera.ShakeEnabled = false
end

-- 13. 无限物品
if Config.InfiniteItems then
    LocalPlayer.Backpack.DescendantAdded:Connect(function(item)
        if item:IsA("Tool") then
            item.Clone().Parent = LocalPlayer.Backpack
        end
    end)
end

print("[Doors Cheat] 加载成功！按对应按键

