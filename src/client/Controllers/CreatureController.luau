--[[
    CreatureController
    Client-side controller that handles creature proximity detection,
    interaction prompts (Befriend), and visual mutation effects.

    Merged from the gameplay scripter's draft with the base architecture.
]]

local Knit = require(script.Parent.Parent.Knit)

local CreatureController = Knit.CreateController {
    Name = "CreatureController",
}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

function CreatureController:KnitStart()
    print("[CreatureController] Initialized")

    -- Get reference to the CreatureService for befriend calls
    self.CreatureService = Knit.GetService("CreatureService")

    -- Listen for new creatures being added to the world
    CollectionService:GetInstanceAddedSignal("Creature"):Connect(function(creature)
        self:SetupCreature(creature)
    end)

    -- Setup existing creatures
    for _, creature in ipairs(CollectionService:GetTagged("Creature")) do
        self:SetupCreature(creature)
    end
end

--[[
    Sets up a creature instance with visual mutations and interaction prompt.
]]
function CreatureController:SetupCreature(creature: Instance)
    -- Apply client-side visual mutations
    self:ApplyVisualMutations(creature)

    -- Create a proximity prompt for befriending
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Befriend"
    prompt.ObjectText = creature:GetAttribute("CreatureType") or "Creature"
    prompt.HoldDuration = 1.0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = creature

    -- Wire up the befriend action
    prompt.Triggered:Connect(function(player)
        local creatureType = creature:GetAttribute("CreatureType")
        local creatureDef = require(game:GetService("ReplicatedStorage").Knit.Data.CreatureData)[creatureType]
        
        if creatureDef and creatureDef.InteractionType == "Rhythm" then
            self:StartRhythmGame(creature)
        else
            local result = self.CreatureService:Befriend(player, creature)
            if result.success then
                print(("[CreatureController] %s successfully befriended %s"):format(player.Name, result.displayName))
            end
        end
    end)
end

--[[
    Starts the rhythm mini-game for befriending certain creatures.
]]
function CreatureController:StartRhythmGame(creature: Instance)
    print("[CreatureController] Starting rhythm game for", creature.Name)
    
    local successBeats = 0
    local requiredBeats = 3
    local isGameActive = true
    
    -- Visual cue loop
    task.spawn(function()
        while isGameActive and creature and creature.Parent do
            -- Pulse the creature
            local originalColor = creature.Color
            local TweenService = game:GetService("TweenService")
            local info = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
            local pulse = TweenService:Create(creature, info, { Color = Color3.new(1, 1, 1) })
            pulse:Play()
            
            -- Wait for the "hit window"
            local startTime = os.clock()
            local hitWindow = 0.5
            local hasHit = false
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.KeyCode == Enum.KeyCode.E then
                    local elapsed = os.clock() - startTime
                    if elapsed <= hitWindow then
                        successBeats += 1
                        print("[CreatureController] Hit! Beats:", successBeats)
                        hasHit = true
                        -- Feedback
                        local light = creature:FindFirstChildWhichIsA("PointLight")
                        if light then
                            light.Brightness = light.Brightness * 2
                            task.delay(0.2, function() light.Brightness = light.Brightness / 2 end)
                        end
                    end
                    connection:Disconnect()
                end
            end)
            
            task.wait(1.5) -- Interval between pulses
            if connection then connection:Disconnect() end
            
            if successBeats >= requiredBeats then
                isGameActive = false
                print("[CreatureController] Rhythm game success!")
                self.CreatureService:Befriend(Players.LocalPlayer, creature)
                break
            end
        end
    end)
end

--[[
    Applies visual mutation effects to a creature based on attributes.
    These are client-side only — the server just sets attributes.
]]
function CreatureController:ApplyVisualMutations(creature: Instance)
    -- Giant mutation: Scale up the creature
    if creature:GetAttribute("Mutation_Giant") then
        if creature:IsA("BasePart") then
            creature.Size = creature.Size * 2
        elseif creature:IsA("Model") then
            creature:ScaleTo(2)
        end
    end

    -- Neon mutation: Glowing material + bright color
    if creature:GetAttribute("Mutation_Neon") then
        if creature:IsA("BasePart") then
            creature.Material = Enum.Material.Neon
            creature.Color = Color3.new(0, 1, 1) -- Cyan neon
        end
        -- For models, iterate through descendants
        for _, part in ipairs(creature:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Neon
            end
        end
    end

    -- Prismatic mutation: Rainbow shimmer via colored lighting
    if creature:GetAttribute("Mutation_Prismatic") then
        local light = Instance.new("PointLight")
        light.Brightness = 3
        light.Range = 15
        light.Color = Color3.fromHSV(os.clock() * 0.1 % 1, 1, 1)
        light.Parent = creature

        -- Animate the color
        task.spawn(function()
            while creature and creature.Parent do
                light.Color = Color3.fromHSV(os.clock() * 0.1 % 1, 1, 1)
                task.wait(0.1)
            end
        end)
    end

    -- Luminous mutation: Attach a soft point light
    if creature:GetAttribute("Mutation_Luminous") then
        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Range = 10
        light.Color = Color3.fromRGB(0, 200, 255)
        light.Parent = creature
    end
end

return CreatureController