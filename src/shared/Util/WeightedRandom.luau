--[[
	WeightedRandom
	Utility for performing weighted random selections.
	Used for creature spawning, mutation rolls, and loot tables.
]]

local WeightedRandom = {}

--[[
	Picks a random key from a weighted table.
	@param items { [string]: number } — Table mapping keys to weight values
	@return string | nil — The key of the selected item, or nil if empty
]]
function WeightedRandom.GetRandomKey(items: { [string]: number }): string?
	local totalWeight = 0
	for _, weight in pairs(items) do
		totalWeight += weight
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for key, weight in pairs(items) do
		cumulative += weight
		if roll <= cumulative then
			return key
		end
	end

	-- Fallback: return last key
	local lastKey = next(items)
	return lastKey
end

--[[
	Picks a random item from a weighted list (object format).
	@param items { [string]: { Weight: number } } — Table of items with Weight fields
	@return string | nil — The key of the selected item, or nil if empty
]]
function WeightedRandom:Pick(items: { [string]: { Weight: number } }): string?
	local weightMap = {}
	for key, item in pairs(items) do
		weightMap[key] = item.Weight
	end
	return WeightedRandom.GetRandomKey(weightMap)
end

--[[
	Returns true/false based on a percentage probability.
	@param probability number — Value between 0 and 1
	@return boolean
]]
function WeightedRandom.Roll(probability: number): boolean
	return math.random() <= probability
end

return WeightedRandom