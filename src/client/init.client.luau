--[[
	Critter Caravan — Client Entry Point
	Initializes Knit and all client-side controllers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:FindFirstChild("Knit", true).Knit)

-- Register all controllers
local controllers = script.Parent.Controllers:GetChildren()
for _, controllerModule in ipairs(controllers) do
	if controllerModule:IsA("ModuleScript") then
		require(controllerModule)
	end
end

Knit.Start():andThen(function()
	print("[CritterCaravan] Knit client started successfully")
end):catch(function(err)
	warn("[CritterCaravan] Knit client failed to start:", err)
end)
