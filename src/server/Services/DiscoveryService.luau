local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit)

local DiscoveryService = Knit.CreateService {
	Name = "DiscoveryService",
	Client = {},
}

function DiscoveryService:KnitStart()
	print("DiscoveryService started")
end

-- Called when a player enters a new biome
function DiscoveryService:OnBiomeEntered(player, biomeName)
	local FieldJournalService = Knit.GetService("FieldJournalService")
	FieldJournalService:RecordDiscovery(player, "Biome", biomeName)
end

-- Called when a player interacts with a PoI
function DiscoveryService:OnPOIDiscovered(player, poiName)
	local FieldJournalService = Knit.GetService("FieldJournalService")
	FieldJournalService:RecordDiscovery(player, "POI", poiName)
end

return DiscoveryService
