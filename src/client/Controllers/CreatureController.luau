--[[
	CreatureController
	Client-side controller that handles creature proximity detection,
	interaction prompts (Befriend), and visual mutation effects.

	Merged from the gameplay scripter's draft with the base architecture.
]]

local Knit = require(script.Parent.Parent.Knit)

local CreatureController = Knit.CreateController {
	Name = "CreatureController",
}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

function CreatureController:KnitStart()
	print("[CreatureController] Initialized")

	-- Get reference to the CreatureService for befriend calls
	self.CreatureService = Knit.GetService("CreatureService")

	-- Listen for new creatures being added to the world
	CollectionService:GetInstanceAddedSignal("Creature"):Connect(function(creature)
		self:SetupCreature(creature)
	end)

	-- Setup existing creatures
	for _, creature in ipairs(CollectionService:GetTagged("Creature")) do
		self:SetupCreature(creature)
	end
end

--[[
	Sets up a creature instance with visual mutations and interaction prompt.
]]
function CreatureController:SetupCreature(creature: Instance)
	-- Apply client-side visual mutations
	self:ApplyVisualMutations(creature)

	-- Create a proximity prompt for befriending
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Befriend"
	prompt.ObjectText = creature:GetAttribute("CreatureType") or "Creature"
	prompt.HoldDuration = 1.0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = creature

	-- Wire up the befriend action
	prompt.Triggered:Connect(function(player)
		local result = self.CreatureService:Befriend(player, creature)
		if result.success then
			print(("[CreatureController] %s successfully befriended %s"):format(player.Name, result.displayName))
		end
	end)
end

--[[
	Applies visual mutation effects to a creature based on attributes.
	These are client-side only — the server just sets attributes.
]]
function CreatureController:ApplyVisualMutations(creature: Instance)
	-- Giant mutation: Scale up the creature
	if creature:GetAttribute("Mutation_Giant") then
		if creature:IsA("BasePart") then
			creature.Size = creature.Size * 2
		elseif creature:IsA("Model") then
			creature:ScaleTo(2)
		end
	end

	-- Neon mutation: Glowing material + bright color
	if creature:GetAttribute("Mutation_Neon") then
		if creature:IsA("BasePart") then
			creature.Material = Enum.Material.Neon
			creature.Color = Color3.new(0, 1, 1) -- Cyan neon
		end
		-- For models, iterate through descendants
		for _, part in ipairs(creature:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.Neon
			end
		end
	end

	-- Prismatic mutation: Rainbow shimmer via colored lighting
	if creature:GetAttribute("Mutation_Prismatic") then
		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Range = 15
		light.Color = Color3.fromHSV(os.clock() * 0.1 % 1, 1, 1)
		light.Parent = creature

		-- Animate the color
		task.spawn(function()
			while creature and creature.Parent do
				light.Color = Color3.fromHSV(os.clock() * 0.1 % 1, 1, 1)
				task.wait(0.1)
			end
		end)
	end

	-- Luminous mutation: Attach a soft point light
	if creature:GetAttribute("Mutation_Luminous") then
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 10
		light.Color = Color3.fromRGB(0, 200, 255)
		light.Parent = creature
	end
end

return CreatureController