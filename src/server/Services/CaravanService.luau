--[[
    CaravanService
    Server-side service for caravan management — building, upgrading,
    decoration placement, biome transitions, and state persistence.

    Integrates with PlayerDataService for all save/load operations.
    References static data from src/shared/Data/CaravanData.luau and BiomeData.luau.
]]

local Knit = require(script.Parent.Parent.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnitShared = ReplicatedStorage:FindFirstChild("Knit")

local CaravanData = require(KnitShared.Data.CaravanData)
local BiomeData = require(KnitShared.Data.BiomeData)

local CaravanService = Knit.CreateService {
    Name = "CaravanService",
    Client = {
        -- Decoration
        GetCaravanData = Knit.CreateMethod(),
        ApplyDecoration = Knit.CreateMethod(),
        RemoveDecoration = Knit.CreateMethod(),
        GetAvailableDecorations = Knit.CreateMethod(),
        PurchaseDecoration = Knit.CreateMethod(),
        -- Upgrades
        GetAvailableUpgrades = Knit.CreateMethod(),
        PurchaseUpgrade = Knit.CreateMethod(),
        GetAppliedUpgrades = Knit.CreateMethod(),
        -- Chassis
        GetAvailableChassis = Knit.CreateMethod(),
        PurchaseChassis = Knit.CreateMethod(),
        SetChassis = Knit.CreateMethod(),
        -- Biomes
        MoveToBiome = Knit.CreateMethod(),
        GetAvailableBiomes = Knit.CreateMethod(),
    },
}

--=============================================================================
-- HELPERS
--=============================================================================

--[[
    Gets the PlayerDataService (cached).
]]
function CaravanService:GetPlayerDataService()
    if not self._pds then
        self._pds = Knit.GetService("PlayerDataService")
    end
    return self._pds
end

--=============================================================================
-- DECORATION SYSTEM
--=============================================================================

--[[
    Returns the full caravan data for a player (for UI rendering).
]]
function CaravanService:GetCaravanData(player: Player)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if profile then
        return profile.CaravanData
    end
    return nil
end

--[[
    Applies a decoration to a specific slot on the player's caravan.
    Slots are defined by the decoration's Category (e.g., "Lighting", "Foliage").
    @param decorationId string — The decoration key from CaravanData.Decorations
    @param slot string — Optional slot identifier (e.g., "Front", "Roof", "Interior").
                          Defaults to the decoration's Category.
    @return { success: boolean, error?: string }
]]
function CaravanService:ApplyDecoration(player: Player, decorationId: string, slot: string?)
    -- Validate decoration exists
    local decorationDef = CaravanData.Decorations[decorationId]
    if not decorationDef then
        return { success = false, error = "Unknown decoration: " .. decorationId }
    end

    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return { success = false, error = "Profile not loaded" }
    end

    -- Check player owns the decoration
    if not pds:HasDecoration(player, decorationId) then
        return { success = false, error = "You don't own this decoration" }
    end

    -- Determine slot: use provided slot, or fall back to category
    local targetSlot = slot or decorationDef.Category

    -- If that slot already has a decoration, remove the old one first
    local oldDecoration = profile.CaravanData.Decorations[targetSlot]
    if oldDecoration then
        -- Put old decoration back in inventory
        pds:GiveDecoration(player, oldDecoration)
    end

    -- Place the new decoration
    profile.CaravanData.Decorations[targetSlot] = decorationId
    pds:MarkDirty(player)

    print(("[CaravanService] %s applied %s to slot %s"):format(player.Name, decorationId, targetSlot))
    return { success = true, slot = targetSlot, decorationId = decorationId }
end

--[[
    Removes a decoration from a specific slot on the player's caravan.
    @param slot string — The slot to clear.
    @return { success: boolean, error?: string }
]]
function CaravanService:RemoveDecoration(player: Player, slot: string)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return { success = false, error = "Profile not loaded" }
    end

    local currentDecoration = profile.CaravanData.Decorations[slot]
    if not currentDecoration then
        return { success = false, error = "No decoration in this slot" }
    end

    -- Return decoration to inventory
    pds:GiveDecoration(player, currentDecoration)

    -- Clear the slot
    profile.CaravanData.Decorations[slot] = nil
    pds:MarkDirty(player)

    print(("[CaravanService] %s removed %s from slot %s"):format(player.Name, currentDecoration, slot))
    return { success = true }
end

--[[
    Returns the list of decorations the player owns and can apply.
]]
function CaravanService:GetAvailableDecorations(player: Player)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return {}
    end

    local available = {}
    for decorationId, count in pairs(profile.Inventory.Decorations) do
        if count > 0 and CaravanData.Decorations[decorationId] then
            table.insert(available, {
                id = decorationId,
                displayName = CaravanData.Decorations[decorationId].DisplayName,
                category = CaravanData.Decorations[decorationId].Category,
                rarity = CaravanData.Decorations[decorationId].Rarity,
                count = count,
                isApplied = false, -- client checks against active decorations
            })
        end
    end

    return available
end

--[[
    Purchases a decoration from the shop using soft currency.
    @param decorationId string — The decoration to buy.
    @return { success: boolean, error?: string }
]]
function CaravanService:PurchaseDecoration(player: Player, decorationId: string)
    local decorationDef = CaravanData.Decorations[decorationId]
    if not decorationDef then
        return { success = false, error = "Unknown decoration" }
    end

    local pds = self:GetPlayerDataService()
    local price = decorationDef.ShopPrice

    if pds:SpendCurrency(player, price) then
        pds:GiveDecoration(player, decorationId)
        print(("[CaravanService] %s purchased decoration %s for %d"):format(player.Name, decorationId, price))
        return { success = true, displayName = decorationDef.DisplayName }
    else
        return { success = false, error = "Not enough currency" }
    end
end

--=============================================================================
-- UPGRADE SYSTEM
--=============================================================================

--[[
    Returns the list of upgrades available for purchase.
    Filters out upgrades the player has already maxed.
    @param player Player
    @return { { id, displayName, cost, description } }
]]
function CaravanService:GetAvailableUpgrades(player: Player)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return {}
    end

    local available = {}
    for upgradeId, upgradeDef in pairs(CaravanData.Upgrades) do
        -- Show all upgrades; client can grey out purchased ones
        local purchased = profile.CaravanData.Upgrades[upgradeId] == true
        table.insert(available, {
            id = upgradeId,
            displayName = upgradeDef.DisplayName,
            cost = upgradeDef.Cost,
            tier = upgradeDef.Tier,
            description = upgradeDef.Description,
            purchased = purchased,
            effect = upgradeDef.Effect,
        })
    end

    return available
end

--[[
    Purchases an upgrade using soft currency.
    Upgrades are one-time purchases that permanently boost stats.
    @param upgradeId string — The upgrade key from CaravanData.Upgrades
    @return { success: boolean, error?: string }
]]
function CaravanService:PurchaseUpgrade(player: Player, upgradeId: string)
    local upgradeDef = CaravanData.Upgrades[upgradeId]
    if not upgradeDef then
        return { success = false, error = "Unknown upgrade" }
    end

    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return { success = false, error = "Profile not loaded" }
    end

    -- Check if already purchased (one-time purchase)
    if profile.CaravanData.Upgrades[upgradeId] then
        return { success = false, error = "Upgrade already applied" }
    end

    -- Check currency
    if not pds:SpendCurrency(player, upgradeDef.Cost) then
        return { success = false, error = "Not enough currency" }
    end

    -- Apply the upgrade
    pds:AddUpgrade(player, upgradeId)

    -- Check if this upgrade unlocks a biome
    if upgradeDef.UnlocksBiome then
        local biomeId = upgradeDef.UnlocksBiome
        profile.CaravanData.UnlockedBiomes[biomeId] = true
        print(("[CaravanService] Upgrade %s unlocked biome: %s"):format(upgradeId, biomeId))
    end

    print(("[CaravanService] %s purchased upgrade %s for %d"):format(player.Name, upgradeId, upgradeDef.Cost))
    return { success = true, displayName = upgradeDef.DisplayName, effect = upgradeDef.Effect }
end

--[[
    Returns the list of upgrades the player has applied.
]]
function CaravanService:GetAppliedUpgrades(player: Player)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return {}
    end

    local applied = {}
    for upgradeId in pairs(profile.CaravanData.Upgrades) do
        local def = CaravanData.Upgrades[upgradeId]
        if def then
            table.insert(applied, {
                id = upgradeId,
                displayName = def.DisplayName,
                effect = def.Effect,
            })
        end
    end

    return applied
end

--=============================================================================
-- CHASSIS SYSTEM
--=============================================================================

--[[
    Returns the list of chassis the player can view (owned + unowned).
]]
function CaravanService:GetAvailableChassis(player: Player)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return {}
    end

    local available = {}
    for chassisId, chassisDef in pairs(CaravanData.Chassis) do
        local owned = profile.CaravanData.OwnedChassis[chassisId] == true
        local isCurrent = profile.CaravanData.CurrentChassis == chassisId
        table.insert(available, {
            id = chassisId,
            displayName = chassisDef.DisplayName,
            description = chassisDef.Description,
            speed = chassisDef.Speed,
            capacity = chassisDef.Capacity,
            owned = owned,
            isCurrent = isCurrent,
            unlockCondition = chassisDef.UnlockCondition,
        })
    end

    return available
end

--[[
    Purchases a new caravan chassis and equips it.
    @param chassisId string — The chassis key from CaravanData.Chassis
    @return { success: boolean, error?: string }
]]
function CaravanService:PurchaseChassis(player: Player, chassisId: string)
    local chassisDef = CaravanData.Chassis[chassisId]
    if not chassisDef then
        return { success = false, error = "Unknown chassis" }
    end

    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return { success = false, error = "Profile not loaded" }
    end

    -- Check if already owned
    if profile.CaravanData.OwnedChassis[chassisId] then
        -- Already owned, just equip it
        return self.Client:SetChassis(player, chassisId)
    end

    -- Check unlock condition
    if type(chassisDef.UnlockCondition) == "table" then
        if chassisDef.UnlockCondition.Type == "Level" then
            if profile.PlayerLevel < chassisDef.UnlockCondition.Value then
                return { success = false, error = ("Requires level %d"):format(chassisDef.UnlockCondition.Value) }
            end
        end
    end

    -- Add and equip
    pds:AddChassis(player, chassisId)
    pds:SetChassis(player, chassisId)

    print(("[CaravanService] %s purchased chassis %s"):format(player.Name, chassisId))
    return { success = true, displayName = chassisDef.DisplayName }
end

--[[
    Equips a chassis the player already owns.
]]
function CaravanService:SetChassis(player: Player, chassisId: string)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return { success = false, error = "Profile not loaded" }
    end

    if not profile.CaravanData.OwnedChassis[chassisId] then
        return { success = false, error = "You don't own this chassis" }
    end

    profile.CaravanData.CurrentChassis = chassisId
    pds:RecalculateStats(player)
    pds:MarkDirty(player)

    local def = CaravanData.Chassis[chassisId]
    print(("[CaravanService] %s equipped chassis %s"):format(player.Name, chassisId))
    return { success = true, displayName = def.DisplayName, stats = profile.CaravanData.Stats }
end

--=============================================================================
-- BIOME TRANSITION SYSTEM
--=============================================================================

--[[
    Moves the player's caravan to a different biome.
    Validates level requirements and biome existence.
    @param biomeId string — The biome key from BiomeData
    @return { success: boolean, error?: string, biomeData?: table }
]]
function CaravanService:MoveToBiome(player: Player, biomeId: string)
    local biomeDef = BiomeData[biomeId]
    if not biomeDef then
        return { success = false, error = "Unknown biome: " .. biomeId }
    end

    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return { success = false, error = "Profile not loaded" }
    end

    -- Check if already in this biome
    if profile.CaravanData.CurrentBiome == biomeId then
        return { success = false, error = "Already in this biome" }
    end

    -- Check level requirement
    if profile.PlayerLevel < biomeDef.RequiredLevel then
        return {
            success = false,
            error = ("Requires level %d to enter %s"):format(biomeDef.RequiredLevel, biomeDef.DisplayName),
        }
    end

    -- Check upgrade requirement (e.g., Lantern Gate)
    if biomeDef.RequiredUpgrade then
        if not profile.CaravanData.Upgrades[biomeDef.RequiredUpgrade] then
            local upgradeDef = CaravanData.Upgrades[biomeDef.RequiredUpgrade]
            local upgradeName = upgradeDef and upgradeDef.DisplayName or biomeDef.RequiredUpgrade
            return {
                success = false,
                error = ("You need the %s to enter %s"):format(upgradeName, biomeDef.DisplayName),
                requiresUpgrade = biomeDef.RequiredUpgrade,
            }
        end
    end

    -- Unlock the biome (in case it's a first visit)
    profile.CaravanData.UnlockedBiomes[biomeId] = true

    -- Update current biome
    local oldBiome = profile.CaravanData.CurrentBiome
    profile.CaravanData.CurrentBiome = biomeId
    pds:MarkDirty(player)

    print(("[CaravanService] %s moved from %s to %s"):format(player.Name, oldBiome, biomeId))

    return {
        success = true,
        biomeId = biomeId,
        displayName = biomeDef.DisplayName,
        creaturePool = biomeDef.CreaturePool,
        colorScheme = biomeDef.ColorScheme,
    }
end

--[[
    Returns the list of biomes the player can access (level-gated).
]]
function CaravanService:GetAvailableBiomes(player: Player)
    local pds = self:GetPlayerDataService()
    local profile = pds:GetProfile(player)
    if not profile then
        return {}
    end

    local available = {}
    for biomeId, biomeDef in pairs(BiomeData) do
        local unlocked = profile.CaravanData.UnlockedBiomes[biomeId] == true
        local isCurrent = profile.CaravanData.CurrentBiome == biomeId
        table.insert(available, {
            id = biomeId,
            displayName = biomeDef.DisplayName,
            description = biomeDef.Description,
            requiredLevel = biomeDef.RequiredLevel,
            order = biomeDef.Order,
            unlocked = unlocked or profile.PlayerLevel >= biomeDef.RequiredLevel,
            isCurrent = isCurrent,
            colorScheme = biomeDef.ColorScheme,
        })
    end

    -- Sort by order
    table.sort(available, function(a, b)
        return a.order < b.order
    end)

    return available
end

--=============================================================================
-- CLIENT METHODS (Remote proxies)
--=============================================================================

-- Decoration
function CaravanService.Client:GetCaravanData(player: Player)
    return self.Server:GetCaravanData(player)
end
function CaravanService.Client:ApplyDecoration(player: Player, decorationId: string, slot: string?)
    return self.Server:ApplyDecoration(player, decorationId, slot)
end
function CaravanService.Client:RemoveDecoration(player: Player, slot: string)
    return self.Server:RemoveDecoration(player, slot)
end
function CaravanService.Client:GetAvailableDecorations(player: Player)
    return self.Server:GetAvailableDecorations(player)
end
function CaravanService.Client:PurchaseDecoration(player: Player, decorationId: string)
    return self.Server:PurchaseDecoration(player, decorationId)
end

-- Upgrades
function CaravanService.Client:GetAvailableUpgrades(player: Player)
    return self.Server:GetAvailableUpgrades(player)
end
function CaravanService.Client:PurchaseUpgrade(player: Player, upgradeId: string)
    return self.Server:PurchaseUpgrade(player, upgradeId)
end
function CaravanService.Client:GetAppliedUpgrades(player: Player)
    return self.Server:GetAppliedUpgrades(player)
end

-- Chassis
function CaravanService.Client:GetAvailableChassis(player: Player)
    return self.Server:GetAvailableChassis(player)
end
function CaravanService.Client:PurchaseChassis(player: Player, chassisId: string)
    return self.Server:PurchaseChassis(player, chassisId)
end
function CaravanService.Client:SetChassis(player: Player, chassisId: string)
    return self.Server:SetChassis(player, chassisId)
end

-- Biomes
function CaravanService.Client:MoveToBiome(player: Player, biomeId: string)
    return self.Server:MoveToBiome(player, biomeId)
end
function CaravanService.Client:GetAvailableBiomes(player: Player)
    return self.Server:GetAvailableBiomes(player)
end

return CaravanService