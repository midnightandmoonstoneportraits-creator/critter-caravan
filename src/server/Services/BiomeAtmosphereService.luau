--[[
	BiomeAtmosphereService
	Server-side service that applies biome-specific lighting and post-processing
	effects when players enter a new biome.

	Uses the atmosphere config from BiomeData.AtmosphereRef to match
	the atmosphere_setup.lua presets designed by the Technical Artist.
]]

local Knit = require(script.Parent.Parent.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnitShared = ReplicatedStorage:FindFirstChild("Knit")
local BiomeData = require(KnitShared.Data.BiomeData)

local BiomeAtmosphereService = Knit.CreateService {
	Name = "BiomeAtmosphereService",
	Client = {
		ApplyAtmosphere = Knit.CreateMethod(),
	},
}

-- Interpolated from atmosphere_setup.lua by the Technical Artist
local ATMOSPHERE_PRESETS = {
	SunnyMeadows = {
		Brightness = 2.5,
		Ambient = { R = 130, G = 130, B = 135 },
		OutdoorAmbient = { R = 110, G = 110, B = 110 },
		ColorCorrection = {
			Brightness = 0.05,
			Contrast = 0.1,
			Saturation = 0.15,
			TintColor = { R = 255, G = 252, B = 240 },
		},
		Atmosphere = {
			Density = 0.3,
			Offset = 0.25,
			Color = { R = 190, G = 210, B = 230 },
			Glare = 0.5,
			Haze = 1,
		},
		Bloom = {
			Intensity = 0.4,
			Size = 24,
			Threshold = 0.95,
		},
	},
	BioluminescentBog = {
		Brightness = 1.0,
		Ambient = { R = 40, G = 60, B = 60 },
		OutdoorAmbient = { R = 30, G = 45, B = 45 },
		ColorCorrection = {
			Brightness = -0.05,
			Contrast = 0.2,
			Saturation = 0.1,
			TintColor = { R = 150, G = 220, B = 210 },
		},
		Atmosphere = {
			Density = 0.7,
			Offset = 0.1,
			Color = { R = 30, G = 50, B = 50 },
			Glare = 0.2,
			Haze = 2.5,
		},
		Bloom = {
			Intensity = 0.6,
			Size = 32,
			Threshold = 0.8,
		},
	},
	CrystalCaverns = {
		Brightness = 1.5,
		Ambient = { R = 60, G = 40, B = 80 },
		OutdoorAmbient = { R = 50, G = 30, B = 70 },
		ColorCorrection = {
			Brightness = 0.0,
			Contrast = 0.15,
			Saturation = 0.2,
			TintColor = { R = 220, G = 200, B = 255 },
		},
		Atmosphere = {
			Density = 0.2,
			Offset = 0.3,
			Color = { R = 60, G = 40, B = 80 },
			Glare = 0.4,
			Haze = 0.8,
		},
		Bloom = {
			Intensity = 0.5,
			Size = 28,
			Threshold = 0.85,
		},
	},
	DeepSeaTrench = {
		Brightness = 0.5,
		Ambient = { R = 10, G = 10, B = 30 },
		OutdoorAmbient = { R = 5, G = 5, B = 20 },
		ColorCorrection = {
			Brightness = -0.1,
			Contrast = 0.3,
			Saturation = 0.05,
			TintColor = { R = 100, G = 150, B = 255 },
		},
		Atmosphere = {
			Density = 0.9,
			Offset = 0.05,
			Color = { R = 10, G = 10, B = 30 },
			Glare = 0.1,
			Haze = 3,
		},
		Bloom = {
			Intensity = 0.3,
			Size = 16,
			Threshold = 0.6,
		},
	},
}

--[[
	Applies the atmosphere for a given biome to a specific player's client.
	Fires a remote signal that the client uses to set up Lighting.
]]
function BiomeAtmosphereService:ApplyAtmosphereForPlayer(player: Player, biomeId: string)
	local biomeDef = BiomeData[biomeId]
	if not biomeDef then
		return { success = false, error = "Unknown biome" }
	end

	local presetKey = biomeDef.AtmosphereRef or biomeId
	local preset = ATMOSPHERE_PRESETS[presetKey]
	if not preset then
		warn(("[BiomeAtmosphereService] No atmosphere preset for %s"):format(biomeId))
		return { success = false, error = "No atmosphere config" }
	end

	print(("[BiomeAtmosphereService] Applying %s atmosphere for %s"):format(presetKey, player.Name))
	return { success = true, biomeId = biomeId, preset = preset }
end

--[[
	Fired by CaravanService when a player moves to a new biome.
	Returns the atmosphere preset to apply on the client.
]]
function BiomeAtmosphereService.Client:ApplyAtmosphere(player: Player, biomeId: string)
	return self.Server:ApplyAtmosphereForPlayer(player, biomeId)
end

return BiomeAtmosphereService