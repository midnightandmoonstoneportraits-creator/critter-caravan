local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Knit)
local ResourceData = require(ReplicatedStorage.Knit.Data.ResourceData)

local ResourceService = Knit.CreateService {
    Name = "ResourceService",
    Client = {
        Harvest = Knit.CreateMethod(),
    },
}

function ResourceService:KnitStart()
    print("ResourceService started")
end

function ResourceService:Harvest(player, nodeInstance)
    if not nodeInstance or not CollectionService:HasTag(nodeInstance, "ResourceNode") then
        return false, "Invalid node"
    end

    local resourceType = nodeInstance:GetAttribute("ResourceType")
    local data = ResourceData[resourceType]
    if not data then return false, "No data for resource" end

    -- check distance
    local character = player.Character
    if not character or not character.PrimaryPart then return false, "No character" end
    if (character.PrimaryPart.Position - nodeInstance.Position).Magnitude > 15 then
        return false, "Too far away"
    end

    -- Calculate yield
    local yield = math.random(data.MinYield, data.MaxYield)
    
    -- Update Player Data
    local PlayerDataService = Knit.GetService("PlayerDataService")
    PlayerDataService:AddInventoryItem(player, resourceType, yield)

    local FieldJournalService = Knit.GetService("FieldJournalService")
    FieldJournalService:RecordDiscovery(player, "Resource", resourceType)

    -- Handle Respawn
    self:HandleRespawn(nodeInstance, data.RespawnTime)

    return true, yield
end

function ResourceService:HandleRespawn(nodeInstance, respawnTime)
    -- Hide node
    nodeInstance.Transparency = 1
    nodeInstance.CanCollide = false
    -- Disable ProximityPrompt (handled by client listening to transparency/attributes or we can just destroy/re-create)
    -- For MVP, let's just toggle attributes
    nodeInstance:SetAttribute("Depleted", true)

    task.delay(respawnTime, function()
        nodeInstance.Transparency = 0
        nodeInstance.CanCollide = true
        nodeInstance:SetAttribute("Depleted", false)
    end)
end

function ResourceService.Client:Harvest(player, nodeInstance)
    return self.Server:Harvest(player, nodeInstance)
end

return ResourceService
