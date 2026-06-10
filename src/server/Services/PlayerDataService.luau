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
            Decorations = {},   -- { decorationId = count, ... }
            Currency = 0,       -- Soft currency for shop purchases
            PremiumCurrency = 0, -- Hard currency (Robux-purchased)
        },
        CaravanData = {
            CurrentChassis = "StarterWagon",
            OwnedChassis = { StarterWagon = true },
            CurrentBiome = "BioluminescentForest",
            UnlockedBiomes = { BioluminescentForest = true },
            Decorations = {},      -- { slot = decorationId, ... }
            OwnedDecorations = {}, -- { decorationId = true, ... }
            Upgrades = {},         -- { upgradeId = true, ... }
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
        end
    end
    saveQueue[player] = nil
end

--[[
    Auto-save loop: saves all dirty profiles every AUTOSAVE_INTERVAL seconds.
]]
function PlayerDataService:StartAutosave()
    while true do
        task.wait(AUTOSAVE_INTERVAL)
        for player, _ in pairs(saveQueue) do
            self:SaveProfile(player)
        end
    end
end

--[[
    Marks a profile as needing save.
]]
function PlayerDataService:MarkDirty(player: Player)
    if profiles[player] then
        saveQueue[player] = true
    end
end

--[[
    Returns a player's profile. Used by other services (CaravanService, CreatureService).
]]
function PlayerDataService:GetProfile(player: Player)
    return profiles[player]
end

--[[
    Returns a player's currency balance.
]]
function PlayerDataService:GetCurrency(player: Player)
    local profile = self:GetProfile(player)
    if profile then
        return profile.Inventory.Currency
    end
    return 0
end

--[[
    Adds currency to a player's balance.
    @return number — New balance
]]
function PlayerDataService:AddCurrency(player: Player, amount: number): number
    local profile = self:GetProfile(player)
    if profile then
        profile.Inventory.Currency = math.max(0, profile.Inventory.Currency + amount)
        self:MarkDirty(player)
        return profile.Inventory.Currency
    end
    return 0
end

--[[
    Spends currency from a player's balance.
    @return boolean — Whether the purchase was successful
]]
function PlayerDataService:SpendCurrency(player: Player, amount: number): boolean
    local profile = self:GetProfile(player)
    if profile and profile.Inventory.Currency >= amount then
        profile.Inventory.Currency -= amount
        self:MarkDirty(player)
        return true
    end
    return false
end

--[[
    Adds a decoration to the player's inventory.
]]
function PlayerDataService:GiveDecoration(player: Player, decorationId: string)
    local profile = self:GetProfile(player)
    if profile then
        profile.Inventory.Decorations[decorationId] = (profile.Inventory.Decorations[decorationId] or 0) + 1
        profile.CaravanData.OwnedDecorations[decorationId] = true
        self:MarkDirty(player)
    end
end

--[[
    Checks if a player owns a decoration.
]]
function PlayerDataService:HasDecoration(player: Player, decorationId: string): boolean
    local profile = self:GetProfile(player)
    if profile then
        return profile.Inventory.Decorations[decorationId] ~= nil and profile.Inventory.Decorations[decorationId] > 0
    end
    return false
end

--[[
    Removes one instance of a decoration from a player's inventory.
]]
function PlayerDataService:ConsumeDecoration(player: Player, decorationId: string): boolean
    local profile = self:GetProfile(player)
    if profile and profile.Inventory.Decorations[decorationId] and profile.Inventory.Decorations[decorationId] > 0 then
        profile.Inventory.Decorations[decorationId] -= 1
        if profile.Inventory.Decorations[decorationId] <= 0 then
            profile.Inventory.Decorations[decorationId] = nil
            profile.CaravanData.OwnedDecorations[decorationId] = nil
        end
        self:MarkDirty(player)
        return true
    end
    return false
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
-- BREEDING SYSTEM
--=============================================================================

--[[
    Sets or clears the active breeding process for a player.
]]
function PlayerDataService:SetBreedingProcess(player: Player, process: table?)
    local profile = self:GetProfile(player)
    if profile then
        profile.BreedingProcess = process
        self:MarkDirty(player)
    end
end

--[[
    Adds an entry to the player's breeding history.
]]
function PlayerDataService:AddBreedingHistory(player: Player, entry: table)
    local profile = self:GetProfile(player)
    if profile then
        if not profile.BreedingHistory then
            profile.BreedingHistory = {}
        end
        table.insert(profile.BreedingHistory, entry)
        -- Keep only last 50 entries
        if #profile.BreedingHistory > 50 then
            table.remove(profile.BreedingHistory, 1)
        end
        self:MarkDirty(player)
    end
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