--[[
	BreedingData
	Static definitions for the creature breeding system.
	Contains rarity outcome tables, catalyst definitions, and compatibility rules.

	Based on GDD Section 3.2 — Mutation Mechanics.
]]

return {
	-- Breeding timer durations in seconds
	BreedingTimes = {
		Common = 900,    -- 15 minutes
		Uncommon = 1800, -- 30 minutes
		Rare = 2700,     -- 45 minutes
		Mythic = 3600,   -- 60 minutes
	},

	-- Rarity outcome tables
	-- Key = "ParentARarity_ParentBRarity"
	-- Each entry maps to { resultRarity = percentage }
	RarityTable = {
		Common_Common = {
			Common = 0.85,
			Uncommon = 0.14,
			Rare = 0.01,
		},
		Common_Uncommon = {
			Common = 0.65,
			Uncommon = 0.30,
			Rare = 0.05,
		},
		Common_Rare = {
			Common = 0.50,
			Uncommon = 0.35,
			Rare = 0.14,
			Mythic = 0.01,
		},
		Uncommon_Uncommon = {
			Common = 0.40,
			Uncommon = 0.50,
			Rare = 0.09,
			Mythic = 0.01,
		},
		Uncommon_Rare = {
			Common = 0.20,
			Uncommon = 0.45,
			Rare = 0.30,
			Mythic = 0.05,
		},
		Rare_Rare = {
			Uncommon = 0.20,
			Rare = 0.65,
			Mythic = 0.15,
		},
		Rare_Mythic = {
			Uncommon = 0.10,
			Rare = 0.50,
			Mythic = 0.40,
		},
		Mythic_Mythic = {
			Rare = 0.30,
			Mythic = 0.70,
		},
	},

	-- Rarity numerical ordering for calculations
	RarityOrder = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Mythic = 4,
	},

	-- Base type inheritance: chance to inherit from Parent A vs Parent B
	BaseInheritance = {
		ParentAChance = 0.70, -- 70% from Parent A
		ParentBChance = 0.30, -- 30% from Parent B
	},

	-- Mutation catalyst definitions
	Catalysts = {
		StabilizerCrystal = {
			DisplayName = "Stabilizer Crystal",
			Description = "Increases chance of inheriting a specific parent's base type.",
			Effect = { ParentAChance = 0.90 },
			Rarity = "Rare",
			ShopPrice = 500,
		},
		ChaosSpore = {
			DisplayName = "Chaos Spore",
			Description = "Guarantees at least one mutation on the offspring.",
			Effect = { GuaranteedMutation = true },
			Rarity = "Rare",
			ShopPrice = 400,
		},
		PrismShard = {
			DisplayName = "Prism Shard",
			Description = "Adds a chance for an entirely new color not present in either parent.",
			Effect = { NewColorChance = 0.30 },
			Rarity = "Rare",
			ShopPrice = 600,
		},
		LunarBloom = {
			DisplayName = "Lunar Bloom",
			Description = "Skews toward Nocturnal and glowing traits.",
			Effect = { TraitBias = "Nocturnal" },
			Rarity = "Uncommon",
			ShopPrice = 300,
		},
	},

	-- Rarity color representations for UI
	RarityColors = {
		Common = Color3.fromRGB(180, 180, 180),
		Uncommon = Color3.fromRGB(100, 200, 100),
		Rare = Color3.fromRGB(80, 160, 255),
		Mythic = Color3.fromRGB(200, 120, 255),
	},
}
