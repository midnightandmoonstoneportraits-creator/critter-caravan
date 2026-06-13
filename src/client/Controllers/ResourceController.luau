local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Knit)

local ResourceController = Knit.CreateController {
	Name = "ResourceController",
}

function ResourceController:KnitStart()
	self.ResourceService = Knit.GetService("ResourceService")
	
	-- Listen for new nodes
	CollectionService:GetInstanceAddedSignal("ResourceNode"):Connect(function(node)
		self:SetupNode(node)
	end)
	
	-- Setup existing nodes
	for _, node in ipairs(CollectionService:GetTagged("ResourceNode")) do
		self:SetupNode(node)
	end
end

function ResourceController:SetupNode(node)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Harvest"
	prompt.ObjectText = node:GetAttribute("ResourceType") or "Resource"
	prompt.HoldDuration = 2.0 -- Default, will update from data
	prompt.Parent = node
	
	-- Update hold duration from shared data
	local ResourceData = require(ReplicatedStorage.Knit.Data.ResourceData)
	local data = ResourceData[node:GetAttribute("ResourceType")]
	if data then
		prompt.HoldDuration = data.HarvestTime
	end

	prompt.Triggered:Connect(function()
		local success, yield = self.ResourceService:Harvest(node)
		if success then
			print("Harvested " .. yield .. " " .. prompt.ObjectText)
			-- VFX would be triggered here via VFXController
		end
	end)

	-- Handle visibility based on "Depleted" attribute
	node:GetAttributeChangedSignal("Depleted"):Connect(function()
		prompt.Enabled = not node:GetAttribute("Depleted")
	end)
	prompt.Enabled = not node:GetAttribute("Depleted")
end

return ResourceController
