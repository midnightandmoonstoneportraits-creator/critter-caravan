--[[
	Critter Caravan — Server Entry Point
	Initializes Knit and all server-side services.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:FindFirstChild("Knit", true).Knit)

-- Register all services
local services = script.Parent.Services:GetChildren()
for _, serviceModule in ipairs(services) do
	if serviceModule:IsA("ModuleScript") then
		require(serviceModule)
	end
end

Knit.Start():andThen(function()
	print("[CritterCaravan] Knit server started successfully")
end):catch(function(err)
	warn("[CritterCaravan] Knit server failed to start:", err)
end)
