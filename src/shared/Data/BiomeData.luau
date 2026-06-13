--[[
	BiomeData
	Static definitions of all explorable biomes in the game world.
	Each biome has a unique environment, creature pool, resources, and requirements.

	BioluminescentBog added per BIOLUMINESCENT_BOG_DESIGN.md v1.0.
	SunnyMeadows Crooked Brook zone added for the Lantern Gate transition.
]]

return {
	SunnyMeadows = {
		DisplayName = "Sunny Meadows",
		Description = "A cheerful, sunlit grassland with gentle breezes and friendly critters.",
		Order = 0,
		RequiredLevel = 0,
		MaxCreatures = 15,
		CreaturePool = {
			["Glowpuff"] = 100,
			["Shellback"] = 70,
		},
		Zones = {
			CrookedBrook = {
				DisplayName = "Crooked Brook",
				Description = "A winding stream at the southern edge of the meadows.",
				HasLanternGate = true,
				TransitionTo = "BioluminescentBog",
				SpawnPoints = { 10, 5 },
			},
		},
		ResourceNodes = {
			["Wild Berries"] = { Total = 20, RespawnTime = 45 },
			["Wood"] = { Total = 15, RespawnTime = 60 },
		},
		ColorScheme = {
			Primary = Color3.fromRGB(100, 200, 100),
			Secondary = Color3.fromRGB(255, 220, 150),
			Ambient = Color3.fromRGB(180, 210, 160),
		},
		AtmosphereRef = "SunnyMeadows",
	},
	BioluminescentBog = {
		DisplayName = "Bioluminescent Bog",
		Description = "A mystical, glowing swamp filled with bioluminescent flora and strange creatures.",
		Order = 1,
		RequiredLevel = 0,
		RequiredUpgrade = "ReinforcedLantern",
		MaxCreatures = 24, -- 14 Sporedancers + 10 Glowpuff-bog
		CaravanSpeedModifier = 0.7, -- 30% speed reduction in bog terrain
		GridSize = { Width = 288, Height = 288 },
		EntrancePoint = { X = 20, Z = 144 },
		HeartCrystalCenter = { X = 144, Z = 260 },
		CreaturePool = {
			["Sporedancer"] = 100,
			["Glowpuff_Bog"] = 70,
		},
		Zones = {
			MistVeil = {
				DisplayName = "Mist Veil",
				Description = "The entrance zone — a transition corridor from Sunny Meadows.",
				Order = 1,
				SpawnPoints = { Creature = 3, Resource = 4 },
				MaxActiveCreatures = { Sporedancer = 2, Glowpuff_Bog = 1 },
				ResourceDensity = { Glowbulb = 3, BogAmber = 1, MistVial = 0 },
				RespawnTimer = 60,
				GuaranteedSpawn = "Sporedancer",
				IsEntrance = true,
			},
			FireflyGrove = {
				DisplayName = "Firefly Grove",
				Description = "An open area with giant glowing mushrooms and dense firefly swarms.",
				Order = 2,
				SpawnPoints = { Creature = 5, Resource = 13 },
				MaxActiveCreatures = { Sporedancer = 4, Glowpuff_Bog = 2 },
				ResourceDensity = { Glowbulb = 7, BogAmber = 4, MistVial = 2 },
				RespawnTimer = 60,
				HasPOI = { "FireflySwarmHeart", "LuminescentLotusPond", "GlowcapCircle" },
			},
			SunkenRuins = {
				DisplayName = "Sunken Ruins",
				Description = "Partially submerged ruins of an ancient stone structure.",
				Order = 3,
				SpawnPoints = { Creature = 4, Resource = 13 },
				MaxActiveCreatures = { Sporedancer = 3, Glowpuff_Bog = 2 },
				ResourceDensity = { Glowbulb = 4, BogAmber = 6, MistVial = 3 },
				RespawnTimer = 90,
				HasPOI = { "CrumbledObservatory", "SubmergedVault", "WhisperingPillars" },
				RequiresLightLevel = 0.4,
			},
			MistWeaversHut = {
				DisplayName = "Mist Weaver's Hut",
				Description = "A hermit's hut on stilts, surrounded by the thickest mist.",
				Order = 4,
				SpawnPoints = { Creature = 2, Resource = 14 },
				MaxActiveCreatures = { Sporedancer = 2, Glowpuff_Bog = 3 },
				ResourceDensity = { Glowbulb = 2, BogAmber = 4, MistVial = 8 },
				RespawnTimer = 90,
				HasPOI = { "WeaversHut", "RopeBridge", "AlchemistsCache" },
			},
			GlowingHeart = {
				DisplayName = "Glowing Heart",
				Description = "The deepest zone — a crystal formation pulsing with bioluminescent energy.",
				Order = 5,
				SpawnPoints = { Creature = 3, Resource = 10 },
				MaxActiveCreatures = { Sporedancer = 3, Glowpuff_Bog = 2, PrismSporedancer = 1 },
				ResourceDensity = { Glowbulb = 2, BogAmber = 4, MistVial = 4 },
				RespawnTimer = 60,
				HasPOI = { "HeartCrystal" },
				HasSpecialResource = { HeartShard = { RespawnTime = 86400 } }, -- 24h
				IsDestination = true,
			},
		},
		ResourceNodes = {
			Glowbulb = {
				DisplayName = "Glowbulb",
				Description = "A glowing bulbous mushroom that provides soft light.",
				HarvestTime = 2.5,
				YieldPerNode = { Min = 2, Max = 4 },
			},
			BogAmber = {
				DisplayName = "Bog Amber",
				Description = "Fossilized resin nugget embedded in mud.",
				HarvestTime = 3.0,
				YieldPerNode = { Min = 1, Max = 2 },
			},
			MistVial = {
				DisplayName = "Mist Vial",
				Description = "Ethereal vapor collected from mist vents.",
				HarvestTime = 4.0,
				YieldPerNode = { Min = 1, Max = 2 },
			},
			HeartShard = {
				DisplayName = "Heart Shard",
				Description = "A rare crystal fragment from the Heart Crystal itself.",
				HarvestTime = 5.0,
				YieldPerNode = { Min = 1, Max = 1 },
				RespawnTime = 86400, -- 24 hours
			},
		},
		LanternGate = {
			RequiredUpgrade = "ReinforcedLantern",
			LocationZone = "CrookedBrook",
			PromptText = "This path is too dark to travel. Your caravan needs a sturdier lantern to light the way.",
			UnlockPromptText = "The vines glow and retract as your lantern illuminates the path ahead.",
		},
		TransitionGradient = {
			Stage1 = { Distance = 10, Description = "Grass becomes damp. Tiny glowing spores appear." },
			Stage2 = { Distance = 20, Description = "Mud patches appear. Fog begins to form." },
			Stage3 = { Distance = 30, Description = "Full swamp terrain. Dense fog. Lantern Gate." },
		},
		ColorScheme = {
			Primary = Color3.fromRGB(0, 120, 140),
			Secondary = Color3.fromRGB(100, 200, 200),
			Ambient = Color3.fromRGB(30, 50, 50),
		},
		AtmosphereRef = "BioluminescentBog",
	},
	CrystalCaverns = {
		DisplayName = "Crystal Caverns",
		Description = "Underground caves filled with massive crystals and reflective pools.",
		Order = 2,
		RequiredLevel = 3,
		MaxCreatures = 10,
		CreaturePool = {
			["CrystalFinnedFish"] = 100,
			["EmberSalamander"] = 80,
		},
		ColorScheme = {
			Primary = Color3.fromRGB(150, 100, 255),
			Secondary = Color3.fromRGB(255, 200, 255),
			Ambient = Color3.fromRGB(40, 20, 60),
		},
		AtmosphereRef = "CrystalCaverns",
	},
	DeepSeaTrench = {
		DisplayName = "Deep Sea Trench",
		Description = "The darkest depths of the ocean, home to mysterious abyssal life.",
		Order = 3,
		RequiredLevel = 6,
		MaxCreatures = 8,
		CreaturePool = {
			["DeepSeaJelly"] = 100,
			["AbyssalAngler"] = 60,
		},
		ColorScheme = {
			Primary = Color3.fromRGB(0, 50, 120),
			Secondary = Color3.fromRGB(0, 200, 255),
			Ambient = Color3.fromRGB(5, 5, 20),
		},
		AtmosphereRef = "DeepSeaTrench",
	},
}