--[[
    CaravanData
    Static definitions of caravan chassis, decoration items, and upgrade tiers.

    Chassis: Base vehicle types with different stats.
    Decorations: Cosmetic items placed in category-based slots on the caravan.
    Upgrades: Permanent stat-boosting purchases.
]]

return {
    Chassis = {
        StarterWagon = {
            DisplayName = "Starter Wagon",
            Description = "A humble wooden wagon. It's a start!",
            Speed = 10,
            Capacity = 5,
            UnlockCondition = "default",
            ModelAssetId = "rbxassetid://PLACEHOLDER_STARTER_WAGON",
        },
        TravelersCoach = {
            DisplayName = "Traveler's Coach",
            Description = "A sturdy coach with room for extra supplies.",
            Speed = 12,
            Capacity = 8,
            UnlockCondition = { Type = "Level", Value = 5 },
            ModelAssetId = "rbxassetid://PLACEHOLDER_COACH",
        },
        CrystalCruiser = {
            DisplayName = "Crystal Cruiser",
            Description = "A majestic caravan reinforced with crystal plating.",
            Speed = 15,
            Capacity = 12,
            UnlockCondition = { Type = "Level", Value = 10 },
            ModelAssetId = "rbxassetid://PLACEHOLDER_CRYSTAL_CRUISER",
        },
    },
    Decorations = {
        LanternString = {
            DisplayName = "Lantern String",
            Description = "Warm glowing lanterns to light your path.",
            Category = "Lighting",
            Rarity = "Common",
            ShopPrice = 50,
        },
        BioVines = {
            DisplayName = "Bioluminescent Vines",
            Description = "Living vines that glow with a soft blue-green light.",
            Category = "Foliage",
            Rarity = "Uncommon",
            ShopPrice = 150,
        },
        CrystalLamp = {
            DisplayName = "Crystal Lamp",
            Description = "A shimmering lamp made from pure crystal shards.",
            Category = "Lighting",
            Rarity = "Rare",
            ShopPrice = 500,
        },
        CozyRug = {
            DisplayName = "Cozy Rug",
            Description = "A warm patterned rug for the caravan interior.",
            Category = "Interior",
            Rarity = "Common",
            ShopPrice = 75,
        },
        StarChart = {
            DisplayName = "Star Chart",
            Description = "An ancient map of the night sky, framed on the wall.",
            Category = "Interior",
            Rarity = "Rare",
            ShopPrice = 350,
        },
        FlowerBox = {
            DisplayName = "Flower Box",
            Description = "A window box full of glowing, fragrant flowers.",
            Category = "Exterior",
            Rarity = "Uncommon",
            ShopPrice = 200,
        },
        WindChimes = {
            DisplayName = "Wind Chimes",
            Description = "Crystal chimes that sing in the breeze.",
            Category = "Exterior",
            Rarity = "Common",
            ShopPrice = 100,
        },
    },
    Upgrades = {
        ExpandedStorage1 = {
            DisplayName = "Expanded Storage I",
            Description = "Adds extra compartments for carrying more creatures.",
            Effect = { Capacity = 5 },
            Tier = 1,
            Cost = 200,
        },
        ExpandedStorage2 = {
            DisplayName = "Expanded Storage II",
            Description = "Further optimizes storage space with custom shelving.",
            Effect = { Capacity = 10 },
            Tier = 2,
            Cost = 500,
        },
        SturdyWheels = {
            DisplayName = "Sturdy Wheels",
            Description = "Reinforced wheels for smoother, faster travel.",
            Effect = { Speed = 3 },
            Tier = 1,
            Cost = 150,
        },
        SpeedSails = {
            DisplayName = "Speed Sails",
            Description = "Lightweight sails that catch every breeze.",
            Effect = { Speed = 5 },
            Tier = 2,
            Cost = 400,
        },
        ComfortSuspension = {
            DisplayName = "Comfort Suspension",
            Description = "Smooth-riding suspension system for creature comfort.",
            Effect = { Capacity = 3, Speed = 1 },
            Tier = 1,
            Cost = 250,
        },
        -- Biome gating upgrades
        ReinforcedLantern = {
            DisplayName = "Reinforced Lantern",
            Description = "A sturdy lantern that illuminates the darkest paths.",
            Effect = { LightRadius = 25 },
            Tier = 1,
            Cost = 200,
            Materials = { Glowbulb = 5, BogAmber = 3, Wood = 15 },
            UnlocksBiome = "BioluminescentBog",
        },
    },
}