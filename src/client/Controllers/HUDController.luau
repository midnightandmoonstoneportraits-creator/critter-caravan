--[[
	HUDController
	Client-side controller managing the in-game HUD:
	- Bottom navigation bar (Caravan, Explore, Friends, Tasks, Settings)
	- Interaction zone proximity prompts
	- Resource bar (top right)
	- Compass indicator (top center)

	Styles follow the UI_DESIGN.md spec: Warm Cream palette, rounded corners.
]]

local Knit = require(script.Parent.Parent.Knit)

local HUDController = Knit.CreateController {
	Name = "HUDController",
}

local Players = game:GetService("Players")
local PlayerGui
local screenGui
local bottomBar
local interactionLabel

function HUDController:KnitStart()
	print("[HUDController] Initialized")

	local player = Players.LocalPlayer
	if not player then
		Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
			self:KnitStart()
		end)
		return
	end

	-- Wait for PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")

	self:CreateHUD(playerGui)
end

--[[
	Creates all HUD elements inside a ScreenGui.
]]
function HUDController:CreateHUD(playerGui: Instance)
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CritterCaravan_HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	self:CreateBottomBar()
	self:CreateInteractionZone()
	self:CreateResourceBar()

	print("[HUDController] HUD created")
end

--[[
	Bottom action bar — fixed at screen bottom.
	[Caravan] [Explore] [Friends] [Tasks] [Settings]
]]
function HUDController:CreateBottomBar()
	bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0, 64)
	bottomBar.Position = UDim2.new(0, 0, 1, -64)
	bottomBar.BackgroundColor3 = Color3.fromRGB(255, 248, 238) -- Warm Cream
	bottomBar.BackgroundTransparency = 0.15
	bottomBar.BorderSizePixel = 0
	bottomBar.Parent = screenGui

	-- Top border line
	local border = Instance.new("Frame")
	border.Name = "Border"
	border.Size = UDim2.new(1, 0, 0, 1)
	border.Position = UDim2.new(0, 0, 0, 0)
	border.BackgroundColor3 = Color3.fromRGB(245, 214, 168) -- Soft Amber
	border.BorderSizePixel = 0
	border.Parent = bottomBar

	-- Navigation buttons
	local buttons = {
		{ name = "Caravan", icon = "🏠", key = "caravan" },
		{ name = "Explore", icon = "🧭", key = "explore" },
		{ name = "Friends", icon = "👥", key = "friends" },
		{ name = "Tasks", icon = "📋", key = "tasks" },
		{ name = "Settings", icon = "⚙️", key = "settings" },
	}

	local buttonWidth = 1 / #buttons

	for i, btnData in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.Name = btnData.name
		btn.Size = UDim2.new(buttonWidth, 0, 1, 0)
		btn.Position = UDim2.new(buttonWidth * (i - 1), 0, 0, 0)
		btn.BackgroundTransparency = 1
		btn.Text = btnData.icon .. "\n" .. btnData.name
		btn.TextColor3 = Color3.fromRGB(92, 58, 41) -- Deep Cocoa
		btn.TextScaled = true
		btn.Font = Enum.Font.FredokaOne
		btn.BorderSizePixel = 0
		btn.Parent = bottomBar

		btn.MouseButton1Click:Connect(function()
			self:OnNavButtonClicked(btnData.key)
		end)
	end
end

--[[
	Interaction zone — centered floating label for prompts.
]]
function HUDController:CreateInteractionZone()
	interactionLabel = Instance.new("TextLabel")
	interactionLabel.Name = "InteractionLabel"
	interactionLabel.Size = UDim2.new(0, 200, 0, 40)
	interactionLabel.Position = UDim2.new(0.5, -100, 0.5, -20)
	interactionLabel.BackgroundColor3 = Color3.fromRGB(92, 58, 41) -- Deep Cocoa
	interactionLabel.BackgroundTransparency = 0.3
	interactionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	interactionLabel.Text = ""
	interactionLabel.TextScaled = true
	interactionLabel.Font = Enum.Font.FredokaOne
	interactionLabel.BorderSizePixel = 0
	interactionLabel.Visible = false
	interactionLabel.Parent = screenGui

	-- Add UICorner for rounded pill shape
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = interactionLabel
end

--[[
	Shows an interaction prompt in the center of the screen.
]]
function HUDController:ShowInteraction(text: string)
	if interactionLabel then
		interactionLabel.Text = text
		interactionLabel.Visible = true
	end
end

--[[
	Hides the interaction prompt.
]]
function HUDController:HideInteraction()
	if interactionLabel then
		interactionLabel.Visible = false
	end
end

--[[
	Resource bar — top right resource display.
]]
function HUDController:CreateResourceBar()
	local resourceBar = Instance.new("Frame")
	resourceBar.Name = "ResourceBar"
	resourceBar.Size = UDim2.new(0, 160, 0, 100)
	resourceBar.Position = UDim2.new(1, -170, 0, 10)
	resourceBar.BackgroundColor3 = Color3.fromRGB(255, 248, 238) -- Warm Cream
	resourceBar.BackgroundTransparency = 0.15
	resourceBar.BorderSizePixel = 0
	resourceBar.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = resourceBar

	-- Placeholder resource entries
	local resources = {
		{ name = "Wild Berries", icon = "🫐", count = 0 },
		{ name = "Wood", icon = "🪵", count = 0 },
		{ name = "Gears", icon = "⚙️", count = 0 },
	}

	-- Fetch real data from PlayerDataService on update
	self:RefreshResourceBar(resourceBar, resources)
end

--[[
	Updates the resource display. Called periodically or on inventory change.
]]
function HUDController:RefreshResourceBar(container: Frame?, resources: { { name: string, icon: string, count: number } })
	if not container then return end

	for i, res in ipairs(resources) do
		local label = Instance.new("TextLabel")
		label.Name = res.name
		label.Size = UDim2.new(1, -10, 0, 24)
		label.Position = UDim2.new(0, 5, 0, (i - 1) * 26)
		label.BackgroundTransparency = 1
		label.Text = res.icon .. " " .. res.name .. "  x" .. res.count
		label.TextColor3 = Color3.fromRGB(92, 58, 41) -- Deep Cocoa
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 14
		label.BorderSizePixel = 0
		label.Parent = container
	end
end

--[[
	Handles bottom navigation bar clicks.
]]
function HUDController:OnNavButtonClicked(key: string)
	print("[HUDController] Nav button clicked:", key)

	if key == "caravan" then
		-- Signal to CaravanUIController to open
		local CaravanUI = Knit.GetController("CaravanUIController")
		if CaravanUI then
			CaravanUI:OpenGarage()
		end
	elseif key == "explore" then
		print("[HUDController] Open map/explore view")
	elseif key == "friends" then
		print("[HUDController] Open friends list")
	elseif key == "tasks" then
		print("[HUDController] Open tasks journal")
	elseif key == "settings" then
		print("[HUDController] Open settings")
	end
end

return HUDController