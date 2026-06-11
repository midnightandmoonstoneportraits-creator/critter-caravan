--[[
    PlayerDataService
    Manages player persistence — collections, inventory, caravan state, and profile data.
    Uses the standard DataStore pattern with auto-save for all player-owned assets.
]]
local Knit = require(script.Parent.Parent.Knit)
local PlayerDataService = Knit.CreateService {
    Name = "PlayerDataService",
    Client = {
        GetProfile = Knit.CreateMethod(),
        GetCurrency = Knit.CreateMethod(),
    },
}

-- Dependencies
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Configuration
local DATASTORE_NAME = "CritterCaravan_PlayerData"
local AUTOSAVE_INTERVAL = 60 -- seconds between auto-saves

-- In-memory player profile cache
local profiles = {}
local saveQueue = {} -- track which players need saving
local dataStore

-- Attempt to get DataStore (may fail in certain environments)
pcall(function()
    dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
end)

--[[
    Creates a default profile for a new player.
]]
function PlayerDataService:CreateDefaultProfile()
    return {
        CollectedCreatures = {},
        Inventory = {
            Resources = {},     -- { resourceId = count, ... }
            Decorations = {},   -- { decorationId = count, ... }
            Currency = 0,       -- Soft currency for shop purchases
            PremiumCurrency = 0, -- Hard currency (Robux-purchased)
        },
        DiscoveryLog = {
            Biomes = {},        -- { biomeId = true, ... }
            Recipes = {},       -- { recipeId = true, ... }
        },
        CaravanData = {
            CurrentChassis = "StarterWagon",
            OwnedChassis = { StarterWagon = true },
            CurrentBiome = "BioluminescentForest",
            UnlockedBiomes = { BioluminescentForest = true },
            Decorations = {},      -- { slot = decorationId, ... }
            OwnedDecorations = {}, -- { decorationId = true, ... }
            Upgrades = {},         -- { upgradeId = true, ... }
            Vivarium = {},         -- { creatureId = { Type, Affinity, LastUpdate }, ... }
            Stats = {              -- Computed stats (base + upgrades)
                Speed = 10,
                Capacity = 5,
            },
        },
        PlayerLevel = 1,
        Experience = 0,
        Settings = {},
    }
end

--[[
    Loads a player's profile from DataStore or creates a default.
]]
function PlayerDataService:LoadProfile(player: Player)
    local userId = player.UserId
    local success, data = false, nil
    if dataStore then
        success, data = pcall(function()
            return dataStore:GetAsync(tostring(userId))
        end)
    end

    if success and data then
        profiles[player] = data
        print(("[PlayerDataService] Loaded profile for %s (userId: %d)"):format(player.Name, userId))
    else
        profiles[player] = self:CreateDefaultProfile()
        print(("[PlayerDataService] Created default profile for %s (userId: %d)"):format(player.Name, userId))
    end
end

--[[
    Saves a player's profile to DataStore.
]]
function PlayerDataService:SaveProfile(player: Player)
    local profile = profiles[player]
    if not profile then return end

    local userId = player.UserId
    if dataStore then
        local success, err = pcall(function()
            dataStore:SetAsync(tostring(userId), profile)
        end)
        if not success then
            warn(("[PlayerDataService] Failed to save profile for %s: %s"):format(player.Name, tostring(err)))
        else
            saveQueue[player] = nil
        end
    end
end

--[[
    Marks a player's profile as "dirty" (needs saving).
]]
function PlayerDataService:MarkDirty(player: Player)
    saveQueue[player] = true
end

--[[
    Periodically saves dirty profiles.
]]
function PlayerDataService:StartAutosave()
    while true do
        task.wait(AUTOSAVE_INTERVAL)
        for player in pairs(saveQueue) do
            if player:IsDescendantOf(game) then
                self:SaveProfile(player)
            else
                saveQueue[player] = nil
            end
        end
    end
end

--[[
    Returns the player's profile data.
]]
function PlayerDataService:GetProfile(player: Player)
    return profiles[player]
end

--[[
    Returns the player's current soft currency.
]]
function PlayerDataService:GetCurrency(player: Player)
    local profile = self:GetProfile(player)
    return profile and profile.Inventory.Currency or 0
end

--[[
    Adjusts the player's soft currency.
]]
function PlayerDataService:AdjustCurrency(player: Player, amount: number)
    local profile = self:GetProfile(player)
    if profile then
        profile.Inventory.Currency = math.max(0, profile.Inventory.Currency + amount)
        self:MarkDirty(player)
        return true
    end
    return false
end

--=============================================================================
-- CARAVAN & UPGRADES
--=============================================================================

--[[
    Applies a decoration to a specific slot on the caravan.
]]
function PlayerDataService:ApplyDecoration(player: Player, slot: string, decorationId: string)
    local profile = self:GetProfile(player)
    if profile then
        profile.CaravanData.Decorations[slot] = decorationId
        self:MarkDirty(player)
        return true
    end
    return false
end

--[[
    Removes a decoration from a specific slot.
]]
function PlayerDataService:RemoveDecoration(player: Player, slot: string)
    local profile = self:GetProfile(player)
    if profile then
        profile.CaravanData.Decorations[slot] = nil
        self:MarkDirty(player)
        return true
    end
    return false
end

--[[
    Checks if a player owns a decoration.
]]
function PlayerDataService:HasDecoration(player: Player, decorationId: string): boolean
    local profile = self:GetProfile(player)
    if profile then
        return profile.CaravanData.OwnedDecorations[decorationId] == true
    end
    return false
end

--[[
    Adds a decoration to the player's collection.
]]
function PlayerDataService:AddDecoration(player: Player, decorationId: string)
    local profile = self:GetProfile(player)
    if profile then
        profile.CaravanData.OwnedDecorations[decorationId] = true
        self:MarkDirty(player)
    end
end

--[[
    Checks if a player owns an upgrade.
]]
function PlayerDataService:HasUpgrade(player: Player, upgradeId: string): boolean
    local profile = self:GetProfile(player)
    if profile then
        return profile.CaravanData.Upgrades[upgradeId] == true
    end
    return false
end

--[[
    Adds an upgrade to the player's caravan.
]]
function PlayerDataService:AddUpgrade(player: Player, upgradeId: string)
    local profile = self:GetProfile(player)
    if profile then
        profile.CaravanData.Upgrades[upgradeId] = true
        self:RecalculateStats(player)
        self:MarkDirty(player)
    end
end

--[[
    Checks if a player owns a chassis.
]]
function PlayerDataService:HasChassis(player: Player, chassisId: string): boolean
    local profile = self:GetProfile(player)
    if profile then
        return profile.CaravanData.OwnedChassis[chassisId] == true
    end
    return false
end

--[[
    Adds a chassis to the player's collection.
]]
function PlayerDataService:AddChassis(player: Player, chassisId: string)
    local profile = self:GetProfile(player)
    if profile then
        profile.CaravanData.OwnedChassis[chassisId] = true
        self:MarkDirty(player)
    end
end

--[[
    Sets the player's current caravan chassis.
]]
function PlayerDataService:SetChassis(player: Player, chassisId: string)
    local profile = self:GetProfile(player)
    if profile and profile.CaravanData.OwnedChassis[chassisId] then
        profile.CaravanData.CurrentChassis = chassisId
        self:RecalculateStats(player)
        self:MarkDirty(player)
        return true
    end
    return false
end

--[[
    Recalculates the player's effective caravan stats (base chassis + upgrades).
]]
function PlayerDataService:RecalculateStats(player: Player)
    local profile = self:GetProfile(player)
    if not profile then return end

    local CaravanData = require(script.Parent.Parent.Parent.shared.Data.CaravanData)
    
    -- Start with chassis base stats
    local chassisId = profile.CaravanData.CurrentChassis
    local chassisDef = CaravanData.Chassis[chassisId]
    if not chassisDef then
        chassisDef = { Speed = 10, Capacity = 5 } -- fallback
    end

    local stats = {
        Speed = chassisDef.Speed or 10,
        Capacity = chassisDef.Capacity or 5,
    }

    -- Apply upgrade bonuses
    for upgradeId in pairs(profile.CaravanData.Upgrades) do
        local upgradeDef = CaravanData.Upgrades[upgradeId]
        if upgradeDef and upgradeDef.Effect then
            for stat, bonus in pairs(upgradeDef.Effect) do
                stats[stat] = (stats[stat] or 0) + bonus
            end
        end
    end

    profile.CaravanData.Stats = stats
end

--=============================================================================
-- DISCOVERY TRACKING
--=============================================================================

--[[
    Records a creature discovery for a player.
    Creates a new record or updates the count if already discovered.
]]
function PlayerDataService:AddDiscovery(player: Player, creatureType: string)
    local profile = self:GetProfile(player)
    if profile then
        if not profile.CollectedCreatures[creatureType] then
            profile.CollectedCreatures[creatureType] = {
                FirstDiscovered = os.time(),
                TotalFound = 0,
                MutationsFound = {},
            }
        end
        local record = profile.CollectedCreatures[creatureType]
        record.TotalFound += 1
        self:MarkDirty(player)
        print(("[PlayerDataService] %s discovered %s (total: %d)"):format(player.Name, creatureType, record.TotalFound))
    end
end

--[[
    Records a specific mutation found on a creature during discovery.
]]
function PlayerDataService:AddMutationDiscovery(player: Player, creatureType: string, mutation: string)
    local profile = self:GetProfile(player)
    if profile and profile.CollectedCreatures[creatureType] then
        local record = profile.CollectedCreatures[creatureType]
        if not record.MutationsFound[mutation] then
            record.MutationsFound[mutation] = true
            print(("[PlayerDataService] %s found mutation %s on %s"):format(player.Name, mutation, creatureType))
        end
        self:MarkDirty(player)
    end
end

--[[
    Adds a resource item to the player's inventory.
]]
function PlayerDataService:AddInventoryItem(player: Player, itemName: string, amount: number)
    local profile = self:GetProfile(player)
    if profile then
        if not profile.Inventory.Resources then
            profile.Inventory.Resources = {}
        end
        profile.Inventory.Resources[itemName] = (profile.Inventory.Resources[itemName] or 0) + amount
        self:MarkDirty(player)
        print(("[PlayerDataService] Added %d %s to %s's inventory"):format(amount, itemName, player.Name))
    end
end

--[[
    Records a discovery in the field journal (Biomes, Recipes, etc.).
]]
function PlayerDataService:AddDiscoveryLog(player: Player, category: string, id: string)
    local profile = self:GetProfile(player)
    if profile and profile.DiscoveryLog[category] then
        if not profile.DiscoveryLog[category][id] then
            profile.DiscoveryLog[category][id] = true
            self:MarkDirty(player)
            print(("[PlayerDataService] %s discovered %s: %s"):format(player.Name, category, id))
            return true
        end
    end
    return false
end

--=============================================================================
-- VIVARIUM & AFFINITY
--=============================================================================

--[[
    Adds a creature to the player's Vivarium.
]]
function PlayerDataService:AddCreatureToVivarium(player: Player, creatureType: string)
    local profile = self:GetProfile(player)
    if profile then
        local creatureId = HttpService:GenerateGUID(false)
        profile.CaravanData.Vivarium[creatureId] = {
            Type = creatureType,
            Affinity = 0,
            LastUpdate = os.time(),
        }
        self:MarkDirty(player)
        print(("[PlayerDataService] Added %s to %s's Vivarium (ID: %s)"):format(creatureType, player.Name, creatureId))
        return creatureId
    end
    return nil
end

--[[
    Updates a creature's affinity in the Vivarium.
]]
function PlayerDataService:UpdateCreatureAffinity(player: Player, creatureId: string, amount: number)
    local profile = self:GetProfile(player)
    if profile and profile.CaravanData.Vivarium[creatureId] then
        local creature = profile.CaravanData.Vivarium[creatureId]
        creature.Affinity = math.max(0, creature.Affinity + amount)
        creature.LastUpdate = os.time()
        self:MarkDirty(player)
        print(("[PlayerDataService] Updated affinity for %s on %s: %d"):format(creatureId, player.Name, creature.Affinity))
        return true
    end
    return false
end

-- Lifecycle events
Players.PlayerAdded:Connect(function(player)
    PlayerDataService:LoadProfile(player)
    -- Ensure stats are calculated on load
    PlayerDataService:RecalculateStats(player)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerDataService:SaveProfile(player)
    profiles[player] = nil
end)

-- Start auto-save
task.spawn(function()
    PlayerDataService:StartAutosave()
end)

-- Client methods
function PlayerDataService.Client:GetProfile(player: Player)
    return self.Server:GetProfile(player)
end

function PlayerDataService.Client:GetCurrency(player: Player)
    return self.Server:GetCurrency(player)
end

return PlayerDataService
