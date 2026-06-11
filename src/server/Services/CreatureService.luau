--[[
    CreatureService
    Server-side service responsible for creature spawning, mutation rolls,
    befriending interactions, and managing player discovery data.

    Merged from the gameplay scripter's draft with the base architecture.
]]

local Knit = require(script.Parent.Parent.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local KnitShared = ReplicatedStorage:FindFirstChild("Knit")

local CreatureData = require(KnitShared.Data.CreatureData)
local MutationData = require(KnitShared.Data.MutationData)
local BiomeData = require(KnitShared.Data.BiomeData)
local WeightedRandom = require(KnitShared.Util.WeightedRandom)

local CreatureService = Knit.CreateService {
    Name = "CreatureService",
    Client = {
        Befriend = Knit.CreateMethod(),
        RequestDiscovery = Knit.CreateMethod(),
        GetPlayerCollection = Knit.CreateMethod(),
    },
}

--=============================================================================
-- INITIALIZATION
--=============================================================================

function CreatureService:KnitStart()
    print("[CreatureService] Started")

    -- Start spawn loop: periodically check and spawn creatures
    task.spawn(function()
        while true do
            self:CheckAllBiomeSpawns()
            task.wait(10)
        end
    end)
end

--=============================================================================
-- SPAWNING
--=============================================================================

--[[
    Checks all biomes and spawns creatures if under capacity.
]]
function CreatureService:CheckAllBiomeSpawns()
    for biomeId, biomeDef in pairs(BiomeData) do
        local currentCount = #CollectionService:GetTagged("Creature")
        local maxCreatures = biomeDef.MaxCreatures or 15

        if currentCount < maxCreatures then
            -- Spawn with a chance per check
            if math.random() <= 0.3 then
                self:SpawnRandomCreature(biomeId)
            end
        end
    end
end

--[[
    Spawns a random creature in the given biome.
    Creates a physical part tagged for client detection.
]]
function CreatureService:SpawnRandomCreature(biomeId: string)
    local biomeDef = BiomeData[biomeId]
    if not biomeDef then return end

    -- Pick a random creature type from the biome's weighted pool
    local creatureType = WeightedRandom.GetRandomKey(biomeDef.CreaturePool)
    if not creatureType then return end

    local creatureDef = CreatureData[creatureType]
    if not creatureDef then return end

    -- Roll for mutations
    local mutations = {}
    for mutationKey, mutationDef in pairs(MutationData) do
        if WeightedRandom.Roll(mutationDef.Weight) then
            table.insert(mutations, mutationKey)
        end
    end

    -- Create a physical representation
    local creatureModel = Instance.new("Part")
    creatureModel.Name = creatureType
    creatureModel.Size = Vector3.new(3, 3, 3)
    creatureModel.Anchored = false
    creatureModel.CanCollide = true
    creatureModel.Position = Vector3.new(math.random(-80, 80), 5, math.random(-80, 80))
    creatureModel.BrickColor = BrickColor.Random()
    creatureModel.Parent = workspace

    CollectionService:AddTag(creatureModel, "Creature")
    creatureModel:SetAttribute("CreatureType", creatureType)

    -- Apply mutation attributes (read by CreatureController for client-side VFX)
    for _, mutation in ipairs(mutations) do
        creatureModel:SetAttribute("Mutation_" .. mutation, true)
    end

    print(("[CreatureService] Spawned %s in %s with %d mutations"):format(creatureType, biomeId, #mutations))
    return creatureModel
end

--[[
    Generates creature data for discovery rewards (non-spawn usage).
]]
function CreatureService:GenerateCreature(creatureType: string)
    local baseData = CreatureData[creatureType]
    if not baseData then
        warn("[CreatureService] Unknown creature type:", creatureType)
        return nil
    end

    local creature = {
        CreatureType = creatureType,
        DisplayName = baseData.DisplayName,
        BaseStats = table.clone(baseData.BaseStats),
        Mutations = {},
        Biomes = baseData.Biomes,
        ModelAssetId = baseData.ModelAssetId,
    }

    -- Roll for mutations
    for _, mutationKey in ipairs(baseData.PossibleMutations or {}) do
        local mutationDef = MutationData[mutationKey]
        if mutationDef and WeightedRandom.Roll(mutationDef.Weight) then
            table.insert(creature.Mutations, mutationKey)
            -- Apply stat modifiers
            for stat, modifier in pairs(mutationDef.StatModifiers or {}) do
                creature.BaseStats[stat] = (creature.BaseStats[stat] or 0) + modifier
            end
        end
    end

    return creature
end

--=============================================================================
-- BEFRIENDING (Discovery)
--=============================================================================

--[[
    Handles a player attempting to befriend a creature.
    1. Validates the creature instance exists and has the proper tag
    2. Checks if the player has the required offering items
    3. Records the discovery in PlayerDataService
    4. Destroys the creature instance
]]
function CreatureService:Befriend(player: Player, creatureInstance: Instance)
    if not creatureInstance or not CollectionService:HasTag(creatureInstance, "Creature") then
        return { success = false, error = "Invalid creature" }
    end

    local creatureType = creatureInstance:GetAttribute("CreatureType")
    local creatureDef = CreatureData[creatureType]
    if not creatureDef then
        return { success = false, error = "Unknown creature type" }
    end

    -- Check player inventory for offering (simplified: always succeeds for now)
    -- TODO: Integrate with inventory system for offering check
    local PlayerDataService = Knit.GetService("PlayerDataService")

    -- Record the discovery
    PlayerDataService:AddDiscovery(player, creatureType)

    -- Add to Vivarium (Collection)
    PlayerDataService:AddCreatureToVivarium(player, creatureType)

    -- Read mutation attributes for the discovery record
    for _, mutationKey in pairs({"Giant", "Neon", "Prismatic", "Luminous"}) do
        if creatureInstance:GetAttribute("Mutation_" .. mutationKey) then
            PlayerDataService:AddMutationDiscovery(player, creatureType, mutationKey)
        end
    end

    -- Destroy creature after befriending
    creatureInstance:Destroy()

    print(("[CreatureService] %s befriended %s"):format(player.Name, creatureType))
    return { success = true, creatureType = creatureType, displayName = creatureDef.DisplayName }
end

--[[
    Handles a discovery interaction from a client (non-befriend mode).
]]
function CreatureService:HandleDiscovery(player: Player, creatureData: table)
    local PlayerDataService = Knit.GetService("PlayerDataService")
    PlayerDataService:AddDiscovery(player, creatureData.CreatureType)
    print(("[CreatureService] Player %s discovered %s"):format(player.Name, creatureData.CreatureType))
    return true
end

--=============================================================================
-- CLIENT METHODS
--=============================================================================

function CreatureService.Client:Befriend(player: Player, creatureInstance: Instance)
    return self.Server:Befriend(player, creatureInstance)
end

function CreatureService.Client:RequestDiscovery(player: Player, creatureType: string)
    local creature = self.Server:GenerateCreature(creatureType)
    if not creature then
        return { success = false, error = "Invalid creature type" }
    end
    self.Server:HandleDiscovery(player, creature)
    return { success = true, creature = creature }
end

function CreatureService.Client:GetPlayerCollection(player: Player)
    local PlayerDataService = Knit.GetService("PlayerDataService")
    local profile = PlayerDataService:GetProfile(player)
    if profile then
        return { collected = profile.CollectedCreatures }
    end
    return { collected = {} }
end

return CreatureService