--[[
    Extension for PlayerDataService.luau
    Add these methods to handle creature discovery and resource inventory.
]]

function PlayerDataService:AddDiscovery(player, creatureType)
	local profile = self:GetProfile(player)
	if profile then
		if not profile.Data.CollectedCreatures then
			profile.Data.CollectedCreatures = {}
		end
		
		if not profile.Data.CollectedCreatures[creatureType] then
			profile.Data.CollectedCreatures[creatureType] = {
				FirstDiscovered = os.time(),
				TotalFound = 0,
				MutationsFound = {}
			}
		end
		
		local record = profile.Data.CollectedCreatures[creatureType]
		record.TotalFound += 1
		
		print("Updated discovery for " .. player.Name .. ": " .. creatureType)
	end
end

function PlayerDataService:AddInventoryItem(player, itemName, amount)
    local profile = self:GetProfile(player)
    if profile then
        if not profile.Data.Inventory then
            profile.Data.Inventory = {}
        end
        
        profile.Data.Inventory[itemName] = (profile.Data.Inventory[itemName] or 0) + amount
        print("Added " .. amount .. " " .. itemName .. " to " .. player.Name .. "'s inventory")
    end
end
