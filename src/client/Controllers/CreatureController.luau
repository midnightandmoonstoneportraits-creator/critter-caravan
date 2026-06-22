--[[
	CreatureController
	Client-side controller that handles creature proximity detection,
	interaction prompts (Befriend), and visual mutation effects.

	Uses a custom cozy-themed ScreenGui instead of the default ProximityPrompt
	to match the "storybook" aesthetic from the UI design spec.
]]

local Knit = require(script.Parent.Parent.Knit)

local CreatureController = Knit.CreateController {
	Name = "CreatureController",
}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Custom prompt UI
local promptGui
local promptFrame
local promptIcon
local promptText
local promptProgress
local currentCreature = nil
local promptActive = false
local holdProgress = 0
local holdConnection

-- Palette (UI_DESIGN.md)
local DEEP_COCOA = Color3.fromRGB(92, 58, 41)
local WARM_CREAM = Color3.fromRGB(255, 248, 238)
local EMBER_ORANGE = Color3.fromRGB(232, 145, 90)
local GLOW_MINT = Color3.fromRGB(126, 217, 169)

function CreatureController:KnitStart()
	print("[CreatureController] Initialized")

	self.CreatureService = Knit.GetService("CreatureService")

	-- Create the custom prompt GUI (hidden initially)
	self:CreateCustomPromptUI()

	-- Listen for new creatures
	CollectionService:GetInstanceAddedSignal("Creature"):Connect(function(creature)
		self:SetupCreature(creature)
	end)

	-- Setup existing creatures
	for _, creature in ipairs(CollectionService:GetTagged("Creature")) do
		self:SetupCreature(creature)
	end

	-- Track player proximity via heartbeat
	local player = Players.LocalPlayer
	if player then
		local character
		player.CharacterAdded:Connect(function(char)
			character = char
		end)
		if player.Character then
			character = player.Character
		end

		game:GetService("RunService").Heartbeat:Connect(function()
			if not character or not character:FindFirstChild("HumanoidRootPart") then
				if promptActive then self:HidePrompt() end
				return
			end

			local root = character.HumanoidRootPart
			local closestCreature = nil
			local closestDist = 20 -- max detection range

			for _, creature in ipairs(CollectionService:GetTagged("Creature")) do
				if creature and creature.Parent then
					local dist = (root.Position - creature.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestCreature = creature
					end
				end
			end

			if closestCreature then
				self:ShowPrompt(closestCreature, closestDist)
			else
				if promptActive then
					self:HidePrompt()
				end
			end
		end)
	end
end

--=============================================================================
-- CUSTOM PROXIMITY PROMPT UI (Cozy theme)
--=============================================================================

function CreatureController:CreateCustomPromptUI()
	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:WaitForChild("PlayerGui")

	promptGui = Instance.new("ScreenGui")
	promptGui.Name = "CritterCaravan_Prompt"
	promptGui.ResetOnSpawn = false
	promptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	promptGui.Enabled = true
	promptGui.Parent = playerGui

	-- Main prompt frame (floating pill badge)
	promptFrame = Instance.new("Frame")
	promptFrame.Name = "PromptFrame"
	promptFrame.Size = UDim2.new(0, 240, 0, 56)
	promptFrame.Position = UDim2.new(0.5, -120, 0.7, -28) -- above center
	promptFrame.BackgroundColor3 = DEEP_COCOA
	promptFrame.BackgroundTransparency = 0.15
	promptFrame.BorderSizePixel = 0
	promptFrame.Visible = false
	promptFrame.Parent = promptGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 16)
	frameCorner.Parent = promptFrame

	-- Soft shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0, -5, 0, -5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014264566" -- soft shadow
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Parent = promptFrame

	-- Icon
	promptIcon = Instance.new("TextLabel")
	promptIcon.Name = "Icon"
	promptIcon.Size = UDim2.new(0, 36, 0, 36)
	promptIcon.Position = UDim2.new(0, 10, 0.5, -18)
	promptIcon.BackgroundTransparency = 1
	promptIcon.Text = "🫐" -- default icon
	promptIcon.TextSize = 24
	promptIcon.Parent = promptFrame

	-- Action text
	promptText = Instance.new("TextLabel")
	promptText.Name = "ActionText"
	promptText.Size = UDim2.new(1, -56, 1, 0)
	promptText.Position = UDim2.new(0, 52, 0, 0)
	promptText.BackgroundTransparency = 1
	promptText.Text = "[E] Befriend — Creature"
	promptText.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptText.Font = Enum.Font.FredokaOne
	promptText.TextSize = 18
	promptText.TextXAlignment = Enum.TextXAlignment.Left
	promptText.Parent = promptFrame

	-- Progress bar (hold indicator)
	promptProgress = Instance.new("Frame")
	promptProgress.Name = "Progress"
	promptProgress.Size = UDim2.new(0, 0, 0, 4)
	promptProgress.Position = UDim2.new(0, 0, 1, -4)
	promptProgress.BackgroundColor3 = EMBER_ORANGE
	promptProgress.BorderSizePixel = 0
	promptProgress.Parent = promptFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 2)
	progressCorner.Parent = promptProgress

	-- Bind E key for instant interaction
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.E and promptActive and currentCreature then
			self:InteractWithCreature(currentCreature)
		end
	end)
end

--[[
	Shows the custom prompt for a nearby creature.
]]
function CreatureController:ShowPrompt(creature: Instance, distance: number)
	if not promptFrame then return end

	local creatureType = creature:GetAttribute("CreatureType") or "Creature"
	promptText.Text = "[E] Befriend — " .. creatureType
	promptFrame.Visible = true
	promptActive = true
	currentCreature = creature

	-- Update progress bar based on distance (closer = fuller)
	local progress = math.clamp(1 - (distance / 20), 0.2, 1)
	promptProgress:TweenSize(
		UDim2.new(progress, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.2,
		true
	)

	-- Bounce animation on appearance
	if not promptFrame:FindFirstChild("BounceTween") then
		promptFrame:TweenSize(
			UDim2.new(0, 240, 0, 56),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Bounce,
			0.4,
			true
		)
	end
end

--[[
	Hides the custom prompt.
]]
function CreatureController:HidePrompt()
	if promptFrame then
		promptFrame.Visible = false
	end
	promptActive = false
	currentCreature = nil
end

--[[
	Triggers the befriend interaction with a creature.
]]
function CreatureController:InteractWithCreature(creature: Instance)
	if not creature or not creature.Parent then return end

	local result = self.CreatureService:Befriend(Players.LocalPlayer, creature)
	if result.success then
		print(("[CreatureController] Befriended %s"):format(result.displayName))
		self:HidePrompt()
	end
end

--=============================================================================
-- CREATURE SETUP
--=============================================================================

--[[
	Sets up a creature instance with visual mutations.
	Default ProximityPrompt removed — using custom prompt system instead.
]]
function CreatureController:SetupCreature(creature: Instance)
	-- Apply client-side visual mutations
	self:ApplyVisualMutations(creature)
end

--[[
	Applies visual mutation effects to a creature based on attributes.
]]
function CreatureController:ApplyVisualMutations(creature: Instance)
	-- Giant mutation
	if creature:GetAttribute("Mutation_Giant") then
		if creature:IsA("BasePart") then
			creature.Size = creature.Size * 2
		elseif creature:IsA("Model") then
			creature:ScaleTo(2)
		end
	end

	-- Neon mutation
	if creature:GetAttribute("Mutation_Neon") then
		if creature:IsA("BasePart") then
			creature.Material = Enum.Material.Neon
			creature.Color = Color3.new(0, 1, 1)
		end
		for _, part in ipairs(creature:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.Neon
			end
		end
	end

	-- Prismatic mutation
	if creature:GetAttribute("Mutation_Prismatic") then
		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Range = 15
		light.Color = Color3.fromHSV(os.clock() * 0.1 % 1, 1, 1)
		light.Parent = creature
		task.spawn(function()
			while creature and creature.Parent do
				light.Color = Color3.fromHSV(os.clock() * 0.1 % 1, 1, 1)
				task.wait(0.1)
			end
		end)
	end

	-- Luminous mutation
	if creature:GetAttribute("Mutation_Luminous") then
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 10
		light.Color = Color3.fromRGB(0, 200, 255)
		light.Parent = creature
	end
end

return CreatureController