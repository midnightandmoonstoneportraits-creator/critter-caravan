--[[
	Critter Caravan — Knit Shared Module
	Re-export of the Knit framework from ReplicatedStorage.
	Both server and client require this module to access Knit APIs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knitPackage = ReplicatedStorage:FindFirstChild("Packages")
if knitPackage then
	local knit = knitPackage:FindFirstChild("Knit")
	if knit then
		return require(knit)
	end
end

-- Fallback: Knit is bundled in ReplicatedStorage directly
local knit = ReplicatedStorage:FindFirstChild("Knit", true)
if knit then
	return require(knit)
end

error("[CritterCaravan] Knit framework not found in ReplicatedStorage")
