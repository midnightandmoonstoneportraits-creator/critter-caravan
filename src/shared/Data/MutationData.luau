--[[
	MutationData
	Definitions of all possible mutations, their rarity weights,
	stat modifiers, and visual effects.
]]

return {
	["Giant"] = {
		DisplayName = "Giant",
		Weight = 0.05, -- 5% chance
		StatModifiers = { Speed = -0.5, Appeal = 2 },
		Visuals = { Scale = 2.5 },
	},
	["Neon"] = {
		DisplayName = "Neon",
		Weight = 0.02, -- 2% chance
		StatModifiers = { Appeal = 3 },
		Visuals = { Material = Enum.Material.Neon, ColorShift = true },
	},
	["Prismatic"] = {
		DisplayName = "Prismatic",
		Weight = 0.01, -- 1% chance
		StatModifiers = { Appeal = 5, Speed = 1 },
		Visuals = { Rainbow = true, ParticleEffect = "Sparkles" },
	},
	["Luminous"] = {
		DisplayName = "Luminous",
		Weight = 0.03, -- 3% chance
		StatModifiers = { Appeal = 2 },
		Visuals = { Bloom = true, LightColor = Color3.fromRGB(0, 200, 255) },
	},
}
