--[[
	NestingNookService
	Server-side service for the Creature Breeding & Mutation system.
	Handles parent pairing, compatibility checks, outcome calculation,
	breeding timers, and mutation reveal sequencing.

	Based on GDD Section 3 — Creature Mutation System.
]]

local Knit = require(script.Parent.Parent.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnitShared = ReplicatedStorage:FindFirstChild("Knit")

local CreatureData = require(KnitShared.Data.CreatureData)
local BreedingData = require(KnitShared.Data.BreedingData)
local WeightedRandom = require(KnitShared.Util.WeightedRandom)

local NestingNookService = Knit.CreateService {
	Name = "NestingNookService",
	Client = {
		-- Breeding management
		StartBreeding = Knit.CreateMethod(),
		GetBreedingStatus = Knit.CreateMethod(),
		CancelBreeding = Knit.CreateMethod(),
		ClaimOffspring = Knit.CreateMethod(),
		-- Queries
		GetCompatibleCreatures = Knit.CreateMethod(),
		GetBreedingHistory = Knit.CreateMethod(),
		-- Catalysts
		ApplyCatalyst = Knit.CreateMethod(),
		GetAvailableCatalysts = Knit.CreateMethod(),
	},
}

-- Active breeding processes: { [player] = breedingData }
local activeBreedings = {}

--=============================================================================
-- COMPATIBILITY
--=============================================================================

--[[
	Checks if two creature types are compatible for breeding.
	They must share at least one trait tag.
]]
function NestingNookService:AreCompatible(creatureTypeA: string, creatureTypeB: string): boolean
	local defA = CreatureData[creatureTypeA]
	local defB = CreatureData[creatureTypeB]

	if not defA or not defB then
		return false
	end

	-- Must share at least one trait
	for _, traitA in ipairs(defA.Traits or {}) do
		for _, traitB in ipairs(defB.Traits or {}) do
			if traitA == traitB then
				return true
			end
		end
	end

	return false
end

--[[
	Returns list of creature types from the player's collection that
	are compatible with a given creature type.
]]
function NestingNookService:GetCompatibleCreatures(player: Player, withCreatureType: string)
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		return {}
	end

	local compatible = {}
	for collectedType in pairs(profile.CollectedCreatures) do
		if collectedType ~= withCreatureType and self:AreCompatible(withCreatureType, collectedType) then
			table.insert(compatible, collectedType)
		end
	end

	return compatible
end

--=============================================================================
-- BREEDING CORE
--=============================================================================

--[[
	Starts the breeding process for two parent creatures.
	Validates compatibility, checks ownership (at least 2 of each),
	calculates outcome, and starts a timer.
]]
function NestingNookService:StartBreeding(player: Player, parentA: string, parentB: string, catalystId: string?)
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		return { success = false, error = "Profile not loaded" }
	end

	-- Validate creature types exist
	local defA = CreatureData[parentA]
	local defB = CreatureData[parentB]
	if not defA or not defB then
		return { success = false, error = "Unknown creature type" }
	end

	-- Check already breeding
	if activeBreedings[player] then
		return { success = false, error = "Already breeding! Wait for the current process to complete." }
	end

	-- Check compatibility
	if not self:AreCompatible(parentA, parentB) then
		return { success = false, error = "These creatures aren't compatible. They need to share a trait." }
	end

	-- Check player owns at least 1 of each parent
	local recordA = profile.CollectedCreatures[parentA]
	local recordB = profile.CollectedCreatures[parentB]
	if not recordA or recordA.TotalFound < 1 then
		return { success = false, error = "You don't have enough " .. defA.DisplayName .. "s" }
	end
	if not recordB or recordB.TotalFound < 1 then
		return { success = false, error = "You don't have enough " .. defB.DisplayName .. "s" }
	end

	-- Consume catalyst if provided
	local catalystDef
	if catalystId then
		catalystDef = BreedingData.Catalysts[catalystId]
		if not catalystDef then
			return { success = false, error = "Unknown catalyst" }
		end
		-- Check ownership (simplified - always succeeds for now)
		-- TODO: Check inventory for catalyst item
	end

	-- Calculate offspring outcome
	local offspring = self:CalculateOffspring(parentA, parentB, catalystDef)

	-- Determine breeding time based on rarity
	local rarityTier = offspring.RarityTier or "Common"
	local breedTime = BreedingData.BreedingTimes[rarityTier] or 900

	-- Mark parents as consumed (one of each)
	recordA.TotalFound -= 1
	recordB.TotalFound -= 1

	-- Store the breeding process
	activeBreedings[player] = {
		parentA = parentA,
		parentB = parentB,
		offspring = offspring,
		catalystId = catalystId,
		startTime = os.time(),
		duration = breedTime,
		completed = false,
		claimed = false,
	}

	PlayerDataService:SetBreedingProcess(player, activeBreedings[player])

	print(("[NestingNookService] %s started breeding %s + %s (rarity: %s, time: %ds)"):format(
		player.Name, parentA, parentB, rarityTier, breedTime))

	return {
		success = true,
		parentADisplay = defA.DisplayName,
		parentBDisplay = defB.DisplayName,
		duration = breedTime,
		rarityTier = rarityTier,
	}
end

--[[
	Calculates the offspring result from two parents.
	Uses the rarity outcome table and inheritance rules from BreedingData.
]]
function NestingNookService:CalculateOffspring(parentA: string, parentB: string, catalyst: table?)
	local defA = CreatureData[parentA]
	local defB = CreatureData[parentB]

	-- 1. Determine rarity outcome
	local rarityKey = defA.RarityTier .. "_" .. defB.RarityTier
	local rarityTable = BreedingData.RarityTable[rarityKey]
	local offspringRarity = WeightedRandom.GetRandomKey(rarityTable or { Common = 1 })

	-- 2. Determine base type (70% Parent A, 30% Parent B)
	local parentAChance = BreedingData.BaseInheritance.ParentAChance
	if catalyst and catalyst.Effect and catalyst.Effect.ParentAChance then
		parentAChance = catalyst.Effect.ParentAChance
	end

	local baseType = parentA
	if math.random() > parentAChance then
		baseType = parentB
	end

	-- 3. Mutations roll based on rarity
	local mutationRolled = false
	local resultMutations = {}
	local possibleMutations = defA.PossibleMutations or {}
	-- Merge possible mutations from both parents
	local mutationPool = {}
	for _, m in ipairs(defA.PossibleMutations or {}) do
		mutationPool[m] = true
	end
	for _, m in ipairs(defB.PossibleMutations or {}) do
		mutationPool[m] = true
	end

	local mutationList = {}
	for m in pairs(mutationPool) do
		table.insert(mutationList, m)
	end

	-- Higher rarity offspring = more mutation chances
	local mutationCount = {
		Common = 0,
		Uncommon = 1,
		Rare = 2,
		Mythic = 3,
	}
	local numMutations = mutationCount[offspringRarity] or 0

	-- Guaranteed mutation if Chaos Spore catalyst used
	if catalyst and catalyst.Effect and catalyst.Effect.GuaranteedMutation then
		numMutations = math.max(numMutations, 1)
	end

	for _ = 1, numMutations do
		local mutationKey = mutationList[math.random(#mutationList)]
		if mutationKey then
			table.insert(resultMutations, mutationKey)
			mutationRolled = true
		end
	end

	-- 4. Build offspring data
	local offspring = {
		BaseType = baseType,
		ParentA = parentA,
		ParentB = parentB,
		RarityTier = offspringRarity,
		Mutations = resultMutations,
		DisplayName = CreatureData[baseType].DisplayName,
		Description = "A bred creature from " .. defA.DisplayName .. " and " .. defB.DisplayName,
		HasMutation = mutationRolled,
	}

	return offspring
end

--[[
	Gets the current breeding status for a player.
]]
function NestingNookService:GetBreedingStatus(player: Player)
	local process = activeBreedings[player]
	if not process then
		return { active = false }
	end

	local elapsed = os.time() - process.startTime
	local remaining = math.max(0, process.duration - elapsed)
	local completed = remaining <= 0

	-- Auto-complete if time has passed
	if completed and not process.completed then
		process.completed = true
		self:PersistBreeding(player)
	end

	return {
		active = true,
		completed = process.completed or completed,
		claimed = process.claimed,
		parentA = process.parentA,
		parentB = process.parentB,
		totalDuration = process.duration,
		remainingSeconds = remaining,
		progress = completed and 1 or (elapsed / process.duration),
	}
end

--[[
	Cancels an active breeding process.
]]
function NestingNookService:CancelBreeding(player: Player)
	local process = activeBreedings[player]
	if not process then
		return { success = false, error = "No active breeding process" }
	end

	-- If already completed, can't cancel
	if process.completed then
		return { success = false, error = "Breeding already complete. Claim the offspring instead." }
	end

	-- Return the parents to the player
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local profile = PlayerDataService:GetProfile(player)
	if profile then
		local defA = CreatureData[process.parentA]
		local defB = CreatureData[process.parentB]
		if defA then profile.CollectedCreatures[process.parentA].TotalFound += 1 end
		if defB then profile.CollectedCreatures[process.parentB].TotalFound += 1 end
	end

	activeBreedings[player] = nil
	PlayerDataService:SetBreedingProcess(player, nil)

	return { success = true, message = "Breeding cancelled. Parents returned." }
end

--[[
	Claims the offspring from a completed breeding process.
]]
function NestingNookService:ClaimOffspring(player: Player)
	local process = activeBreedings[player]
	if not process then
		return { success = false, error = "No active breeding process" }
	end

	local elapsed = os.time() - process.startTime
	if elapsed < process.duration then
		return { success = false, error = "Breeding is not yet complete!" }
	end

	if process.claimed then
		return { success = false, error = "Offspring already claimed!" }
	end

	-- Record the offspring in the player's collection
	local PlayerDataService = Knit.GetService("PlayerDataService")
	PlayerDataService:AddDiscovery(player, process.offspring.BaseType)

	-- Record any mutations on the offspring
	for _, mutation in ipairs(process.offspring.Mutations) do
		PlayerDataService:AddMutationDiscovery(player, process.offspring.BaseType, mutation)
	end

	-- Mark as claimed
	process.claimed = true
	activeBreedings[player] = nil
	PlayerDataService:SetBreedingProcess(player, nil)

	-- Log the breeding in history
	PlayerDataService:AddBreedingHistory(player, {
		parentA = process.parentA,
		parentB = process.parentB,
		offspringType = process.offspring.BaseType,
		offspringRarity = process.offspring.RarityTier,
		mutations = process.offspring.Mutations,
		timestamp = os.time(),
	})

	print(("[NestingNookService] %s claimed offspring: %s (%s)"):format(
		player.Name, process.offspring.DisplayName, process.offspring.RarityTier))

	return {
		success = true,
		offspring = process.offspring,
	}
end

--[[
	Applies a catalyst to the active breeding process.
]]
function NestingNookService:ApplyCatalyst(player: Player, catalystId: string)
	local process = activeBreedings[player]
	if not process then
		return { success = false, error = "No active breeding process" }
	end

	if process.completed then
		return { success = false, error = "Breeding already complete" }
	end

	local catalystDef = BreedingData.Catalysts[catalystId]
	if not catalystDef then
		return { success = false, error = "Unknown catalyst" }
	end

	process.catalystId = catalystId
	-- Recalculate offspring with catalyst applied
	process.offspring = self:CalculateOffspring(process.parentA, process.parentB, catalystDef)

	self:PersistBreeding(player)

	return { success = true, catalystName = catalystDef.DisplayName }
end

--[[
	Returns the player's available catalysts.
]]
function NestingNookService:GetAvailableCatalysts(player: Player)
	-- TODO: Read from player inventory
	-- For now, return all catalysts as purchasable from shop
	local available = {}
	for catId, catDef in pairs(BreedingData.Catalysts) do
		table.insert(available, {
			id = catId,
			displayName = catDef.DisplayName,
			description = catDef.Description,
			rarity = catDef.Rarity,
			price = catDef.ShopPrice,
			owned = true, -- simplified: always show as owned
		})
	end
	return available
end

--=============================================================================
-- PERSISTENCE
--=============================================================================

--[[
	Persists the current breeding process to PlayerDataService.
]]
function NestingNookService:PersistBreeding(player: Player)
	local process = activeBreedings[player]
	local PlayerDataService = Knit.GetService("PlayerDataService")
	PlayerDataService:SetBreedingProcess(player, process)
end

--[[
	Returns the player's breeding history.
]]
function NestingNookService:GetBreedingHistory(player: Player)
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local profile = PlayerDataService:GetProfile(player)
	if profile then
		return profile.BreedingHistory or {}
	end
	return {}
end

--=============================================================================
-- CLIENT METHODS
--=============================================================================

function NestingNookService.Client:StartBreeding(player: Player, parentA: string, parentB: string, catalystId: string?)
	return self.Server:StartBreeding(player, parentA, parentB, catalystId)
end
function NestingNookService.Client:GetBreedingStatus(player: Player)
	return self.Server:GetBreedingStatus(player)
end
function NestingNookService.Client:CancelBreeding(player: Player)
	return self.Server:CancelBreeding(player)
end
function NestingNookService.Client:ClaimOffspring(player: Player)
	return self.Server:ClaimOffspring(player)
end
function NestingNookService.Client:GetCompatibleCreatures(player: Player, withCreatureType: string)
	return self.Server:GetCompatibleCreatures(player, withCreatureType)
end
function NestingNookService.Client:GetBreedingHistory(player: Player)
	return self.Server:GetBreedingHistory(player)
end
function NestingNookService.Client:ApplyCatalyst(player: Player, catalystId: string)
	return self.Server:ApplyCatalyst(player, catalystId)
end
function NestingNookService.Client:GetAvailableCatalysts(player: Player)
	return self.Server:GetAvailableCatalysts(player)
end

return NestingNookService
