--[[
    NestingService
    Handles passive affinity growth and social grooming interactions.
]]
local Knit = require(script.Parent.Parent.Knit)
local Players = game:GetService("Players")

local CollectionService = game:GetService("CollectionService")

local NestingService = Knit.CreateService {
    Name = "NestingService",
    Client = {
        GroomCreature = Knit.CreateMethod(),
    },
}

--[[
    Spawns a creature from the Vivarium into the world.
]]
function NestingService:SpawnVivariumCreature(player: Player, creatureId: string, data: any)
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- For now, spawn near player
    local spawnPos = rootPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
    
    local creatureModel = Instance.new("Part")
    creatureModel.Name = data.Type .. "_" .. creatureId
    creatureModel.Size = Vector3.new(2, 2, 2)
    creatureModel.Position = spawnPos
    creatureModel.Anchored = false
    creatureModel.CanCollide = true
    creatureModel.Parent = workspace
    
    -- Tag for NestingController
    CollectionService:AddTag(creatureModel, "VivariumCreature")
    creatureModel:SetAttribute("CreatureId", creatureId)
    creatureModel:SetAttribute("CreatureType", data.Type)
    
    print(("[NestingService] Spawned vivarium creature %s for %s"):format(data.Type, player.Name))
    return creatureModel
end

-- Constants
local PASSIVE_AFFINITY_RATE = 1 -- affinity per interval
local PASSIVE_INTERVAL = 600 -- 10 minutes
local GROOMING_AFFINITY_BOOST = 5
local GROOMING_COOLDOWN = 300 -- 5 minutes
local MAX_AFFINITY = 100

-- In-memory cooldowns for grooming
local groomingCooldowns = {} -- { [player] = { [creatureId] = lastGroomTime } }

function NestingService:KnitStart()
    print("[NestingService] Started")

    -- Handle players joining
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            -- Wait a bit for profile to load
            task.wait(2)
            local PlayerDataService = Knit.GetService("PlayerDataService")
            local profile = PlayerDataService:GetProfile(player)
            if profile and profile.CaravanData.Vivarium then
                for id, data in pairs(profile.CaravanData.Vivarium) do
                    self:SpawnVivariumCreature(player, id, data)
                end
            end
        end)
        
        self:ProcessPassiveAffinity(player)
    end)

    -- Periodic passive affinity check for online players
    task.spawn(function()
        while true do
            task.wait(60) -- Check every minute
            for _, player in ipairs(Players:GetPlayers()) do
                self:ProcessPassiveAffinity(player)
            end
        end
    end)
end

--[[
    Calculates and applies passive affinity gain based on elapsed time.
]]
function NestingService:ProcessPassiveAffinity(player: Player)
    local PlayerDataService = Knit.GetService("PlayerDataService")
    local profile = PlayerDataService:GetProfile(player)
    if not profile or not profile.CaravanData.Vivarium then return end

    local now = os.time()
    for creatureId, data in pairs(profile.CaravanData.Vivarium) do
        local elapsed = now - data.LastUpdate
        if elapsed >= PASSIVE_INTERVAL then
            local gain = math.floor(elapsed / PASSIVE_INTERVAL) * PASSIVE_AFFINITY_RATE
            if gain > 0 and data.Affinity < MAX_AFFINITY then
                PlayerDataService:UpdateCreatureAffinity(player, creatureId, gain)
            else
                -- Just update the timestamp if no gain but interval passed (to prevent massive jumps if rate is 0)
                data.LastUpdate = now
                PlayerDataService:MarkDirty(player)
            end
        end
    end
end

--[[
    Handles the grooming interaction.
]]
function NestingService:GroomCreature(player: Player, creatureId: string)
    local PlayerDataService = Knit.GetService("PlayerDataService")
    local profile = PlayerDataService:GetProfile(player)
    
    if not profile or not profile.CaravanData.Vivarium[creatureId] then
        return { success = false, error = "Creature not found in Vivarium" }
    end

    local now = os.time()
    local playerCooldowns = groomingCooldowns[player]
    if not playerCooldowns then
        playerCooldowns = {}
        groomingCooldowns[player] = playerCooldowns
    end

    local lastGroom = playerCooldowns[creatureId] or 0
    if now - lastGroom < GROOMING_COOLDOWN then
        local remaining = math.ceil(GROOMING_COOLDOWN - (now - lastGroom))
        return { success = false, error = "Grooming on cooldown", cooldown = remaining }
    end

    -- Apply boost
    local creature = profile.CaravanData.Vivarium[creatureId]
    if creature.Affinity >= MAX_AFFINITY then
        return { success = false, error = "Affinity is already maxed!" }
    end

    PlayerDataService:UpdateCreatureAffinity(player, creatureId, GROOMING_AFFINITY_BOOST)
    playerCooldowns[creatureId] = now

    print(("[NestingService] %s groomed creature %s"):format(player.Name, creatureId))
    return { success = true, newAffinity = profile.CaravanData.Vivarium[creatureId].Affinity }
end

-- Client methods
function NestingService.Client:GroomCreature(player: Player, creatureId: string)
    return self.Server:GroomCreature(player, creatureId)
end

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
    groomingCooldowns[player] = nil
end)

return NestingService
