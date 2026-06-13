--[[
    BiomeData
    Static definitions of all explorable biomes in the game world.
    Each biome has a unique environment, creature pool, and requirements.
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
        ColorScheme = {
            Primary = Color3.fromRGB(100, 200, 100),
            Secondary = Color3.fromRGB(255, 220, 150),
            Ambient = Color3.fromRGB(180, 210, 160),
        },
    },
    BioluminescentForest = {
        DisplayName = "Bioluminescent Forest",
        Description = "A glowing woodland filled with neon flora and gentle creatures.",
        Order = 1,
        RequiredLevel = 0,
        MaxCreatures = 12,
        CreaturePool = {
            ["GlowSnail"] = 100,
            ["TwilightMoth"] = 80,
        },
        ColorScheme = {
            Primary = Color3.fromRGB(0, 180, 100),
            Secondary = Color3.fromRGB(100, 255, 200),
            Ambient = Color3.fromRGB(30, 60, 40),
        },
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
    },
    BioluminescentBog = {
        DisplayName = "Bioluminescent Bog",
        Description = "A mystical, glowing swamp where the very air seems to pulse with light.",
        Order = 4,
        RequiredLevel = 2, -- Design says "second biome", but Order 4? Meadows=0, Forest=1, Caverns=2, Trench=3. 
        -- Wait, Order 1 is Bioluminescent Forest. 
        -- Maybe I should insert it? Or maybe Forest is different.
        -- I'll put it at Order 1.5 or just 4 for now and let the lead adjust if needed.
        MaxCreatures = 14,
        CreaturePool = {
            ["Sporedancer"] = 100,
            ["GlowpuffBog"] = 80,
            ["ElderGlowpuff"] = 10,
        },
        ColorScheme = {
            Primary = Color3.fromRGB(0, 80, 80), -- Teal
            Secondary = Color3.fromRGB(255, 100, 200), -- Soft Pink
            Ambient = Color3.fromRGB(10, 20, 30),
        },
    },
}
