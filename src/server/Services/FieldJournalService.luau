local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit)

local FieldJournalService = Knit.CreateService {
	Name = "FieldJournalService",
	Client = {
		DiscoveryMade = Knit.CreateSignal(), -- Fired to notify client of new discovery
	},
}

function FieldJournalService:KnitStart()
	print("FieldJournalService started")
end

function FieldJournalService:RecordDiscovery(player, discoveryType, discoveryId)
	-- discoveryType: "Creature", "Biome", "Recipe", "Resource"
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local profile = PlayerDataService:GetProfile(player)
	
	if not profile then return end

	local journal = profile.Data.FieldJournal or {
		Creatures = {},
		Biomes = {},
		Recipes = {},
		Resources = {}
	}
	profile.Data.FieldJournal = journal

	local category = journal[discoveryType .. "s"]
	if not category then return end

	if not category[discoveryId] then
		category[discoveryId] = {
			DiscoveredAt = os.time(),
		}
		
		-- Notify client
		self.Client.DiscoveryMade:Fire(player, discoveryType, discoveryId)
		print("New discovery recorded for " .. player.Name .. ": " .. discoveryType .. " - " .. discoveryId)
		
		-- Also update specialized discovery logs if needed
		if discoveryType == "Creature" then
			PlayerDataService:AddDiscovery(player, discoveryId)
		end
	end
end

function FieldJournalService.Client:GetJournal(player)
	local PlayerDataService = Knit.GetService("PlayerDataService")
	local profile = PlayerDataService:GetProfile(player)
	return profile and profile.Data.FieldJournal or {}
end

return FieldJournalService
