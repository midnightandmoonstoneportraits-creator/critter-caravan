local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit)

local FieldJournalController = Knit.CreateController {
	Name = "FieldJournalController",
}

function FieldJournalController:KnitStart()
	local FieldJournalService = Knit.GetService("FieldJournalService")
	local HUDController = Knit.GetController("HUDController")

	FieldJournalService.DiscoveryMade:Connect(function(discoveryType, discoveryId)
		print("New discovery: " .. discoveryType .. " - " .. discoveryId)
		
		-- Use HUDController to show notification if available
		if HUDController and HUDController.ShowNotification then
			HUDController:ShowNotification("New " .. discoveryType .. " Discovered: " .. discoveryId)
		end
		
		-- Trigger discovery sound/VFX if needed
	end)
end

return FieldJournalController
