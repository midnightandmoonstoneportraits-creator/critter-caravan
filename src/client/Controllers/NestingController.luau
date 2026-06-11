--[[
    NestingController
    Handles client-side interactions for nesting and grooming.
]]
local Knit = require(script.Parent.Parent.Knit)
local CollectionService = game:GetService("CollectionService")

local NestingController = Knit.CreateController {
    Name = "NestingController",
}

function NestingController:KnitStart()
    print("[NestingController] Initialized")
    self.NestingService = Knit.GetService("NestingService")

    -- Listen for vivarium creatures
    CollectionService:GetInstanceAddedSignal("VivariumCreature"):Connect(function(creature)
        self:SetupGrooming(creature)
    end)

    for _, creature in ipairs(CollectionService:GetTagged("VivariumCreature")) do
        self:SetupGrooming(creature)
    end
end

--[[
    Sets up a grooming prompt on a vivarium creature.
]]
function NestingController:SetupGrooming(creature: Instance)
    local creatureId = creature:GetAttribute("CreatureId")
    if not creatureId then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pet"
    prompt.ObjectText = creature:GetAttribute("CreatureType") or "Creature"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = creature

    prompt.Triggered:Connect(function()
        local result = self.NestingService:GroomCreature(creatureId)
        if result.success then
            self:PlayGroomingEffects(creature)
            print("[NestingController] Groomed creature! New affinity:", result.newAffinity)
        else
            warn("[NestingController] Failed to groom:", result.error)
            -- Optionally show UI cooldown if result.cooldown exists
        end
    end)
end

--[[
    Plays happy animations/VFX for grooming.
]]
function NestingController:PlayGroomingEffects(creature: Instance)
    -- Visual Feedback: Hearts or Sparkles
    local hearts = Instance.new("ParticleEmitter")
    hearts.Texture = "rbxassetid://241532452" -- Heart icon
    hearts.Size = NumberSequence.new(0.5)
    hearts.Lifetime = NumberRange.new(1, 2)
    hearts.Rate = 20
    hearts.Speed = NumberRange.new(2, 5)
    hearts.VelocitySpread = 180
    hearts.Parent = creature:IsA("Model") and (creature.PrimaryPart or creature:FindFirstChildWhichIsA("BasePart")) or creature

    -- Sound effect
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://180954430" -- Happy chime/sparkle
    sound.Volume = 0.5
    sound.Parent = hearts.Parent
    sound:Play()

    -- Happy jump animation (tween)
    local target = hearts.Parent
    if target:IsA("BasePart") then
        local originalPos = target.Position
        local TweenService = game:GetService("TweenService")
        local info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
        local jump = TweenService:Create(target, info, { Position = originalPos + Vector3.new(0, 2, 0) })
        jump:Play()
    end

    -- Cleanup particles after a bit
    task.delay(1.5, function()
        hearts.Enabled = false
        task.wait(2)
        hearts:Destroy()
        sound:Destroy()
    end)
end

return NestingController
