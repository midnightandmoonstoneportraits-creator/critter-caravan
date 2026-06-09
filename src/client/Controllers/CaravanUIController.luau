--[[
	CaravanUIController
	Client-side controller for the Caravan Customization interface.
	Provides the Garage screen with:
	- Decoration browser (Exterior, Interior categories)
	- Upgrade purchase panel
	- Chassis selection
	- Biome navigation map

	Hooks into CaravanService for all backend operations.
	Styling follows the UI_DESIGN.md spec (rounded corners, Warm Cream palette).
]]

local Knit = require(script.Parent.Parent.Knit)

local CaravanUIController = Knit.CreateController {
	Name = "CaravanUIController",
}

local Players = game:GetService("Players")

-- UI state
local garageOpen = false
local screenGui
local garageFrame
local currentTab = "Exterior"

function CaravanUIController:KnitStart()
	print("[CaravanUIController] Initialized")

	self.CaravanService = Knit.GetService("CaravanService")

	-- Pre-create the GUI (hidden until opened)
	local player = Players.LocalPlayer
	if player then
		local playerGui = player:WaitForChild("PlayerGui")
		self:CreateGarageUI(playerGui)
	end
end

--=============================================================================
-- GARAGE UI (Main Customization Screen)
--=============================================================================

--[[
	Creates the full Garage UI structure (hidden by default).
]]
function CaravanUIController:CreateGarageUI(playerGui: Instance)
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CritterCaravan_Garage"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false -- Hidden until opened
	screenGui.Parent = playerGui

	-- Main backdrop (semi-transparent)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	-- Garage panel (centered, 80% of screen)
	garageFrame = Instance.new("Frame")
	garageFrame.Name = "GaragePanel"
	garageFrame.Size = UDim2.new(0, 800, 0, 600)
	garageFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
	garageFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 238) -- Warm Cream
	garageFrame.BorderSizePixel = 0
	garageFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = garageFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(245, 214, 168) -- Soft Amber
	titleBar.BorderSizePixel = 0
	titleBar.Parent = garageFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	-- Title text
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 16, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Caravan Garage"
	title.TextColor3 = Color3.fromRGB(92, 58, 41) -- Deep Cocoa
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -48, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(232, 145, 90) -- Ember Orange
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 20
	closeBtn.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		self:CloseGarage()
	end)

	-- Tab bar (left sidebar)
	self:CreateTabBar()

	-- Content panel (right side)
	self:CreateContentPanel()

	-- Actions bar (bottom)
	self:CreateActionsBar()
end

--[[
	Creates the category tab bar on the left side.
]]
function CaravanUIController:CreateTabBar()
	local tabs = {
		{ name = "Exterior", icon = "🎨", key = "Exterior" },
		{ name = "Interior", icon = "🛋️", key = "Interior" },
		{ name = "Upgrades", icon = "⚡", key = "Upgrades" },
		{ name = "Biomes", icon = "🌍", key = "Biomes" },
	}

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(0, 140, 1, -50)
	tabBar.Position = UDim2.new(0, 0, 0, 50)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = garageFrame

	for i, tabData in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = tabData.key
		tab.Size = UDim2.new(1, -10, 0, 50)
		tab.Position = UDim2.new(0, 5, 0, (i - 1) * 55 + 5)
		tab.BackgroundColor3 = Color3.fromRGB(245, 214, 168) -- Soft Amber
		tab.BackgroundTransparency = tabData.key == currentTab and 0 or 0.5
		tab.BorderSizePixel = 0
		tab.Text = tabData.icon .. "  " .. tabData.name
		tab.TextColor3 = Color3.fromRGB(92, 58, 41)
		tab.Font = Enum.Font.FredokaOne
		tab.TextSize = 16
		tab.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 10)
		tabCorner.Parent = tab

		tab.MouseButton1Click:Connect(function()
			self:SwitchTab(tabData.key)
		end)
	end
end

--[[
	Creates the main content panel that displays tab-specific data.
]]
function CaravanUIController:CreateContentPanel()
	local contentPanel = Instance.new("Frame")
	contentPanel.Name = "ContentPanel"
	contentPanel.Size = UDim2.new(1, -150, 1, -110)
	contentPanel.Position = UDim2.new(0, 145, 0, 55)
	contentPanel.BackgroundTransparency = 1
	contentPanel.BorderSizePixel = 0
	contentPanel.Parent = garageFrame
end

--[[
	Creates the bottom action bar.
]]
function CaravanUIController:CreateActionsBar()
	local actionsBar = Instance.new("Frame")
	actionsBar.Name = "ActionsBar"
	actionsBar.Size = UDim2.new(1, -10, 0, 50)
	actionsBar.Position = UDim2.new(0, 5, 1, -55)
	actionsBar.BackgroundTransparency = 1
	actionsBar.Parent = garageFrame

	-- Save & Exit button
	local saveBtn = Instance.new("TextButton")
	saveBtn.Name = "SaveExit"
	saveBtn.Size = UDim2.new(0, 140, 0, 40)
	saveBtn.Position = UDim2.new(0.5, -220, 0.5, -20)
	saveBtn.BackgroundColor3 = Color3.fromRGB(232, 145, 90) -- Ember Orange
	saveBtn.BorderSizePixel = 0
	saveBtn.Text = "Save & Exit"
	saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveBtn.Font = Enum.Font.FredokaOne
	saveBtn.TextSize = 18
	saveBtn.Parent = actionsBar

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 12)
	saveCorner.Parent = saveBtn

	saveBtn.MouseButton1Click:Connect(function()
		self:CloseGarage()
	end)

	-- Reset button
	local resetBtn = Instance.new("TextButton")
	resetBtn.Name = "Reset"
	resetBtn.Size = UDim2.new(0, 140, 0, 40)
	resetBtn.Position = UDim2.new(0.5, 80, 0.5, -20)
	resetBtn.BackgroundColor3 = Color3.fromRGB(92, 58, 41)
	resetBtn.BackgroundTransparency = 0.8
	resetBtn.BorderSizePixel = 0
	resetBtn.Text = "Reset to Default"
	resetBtn.TextColor3 = Color3.fromRGB(92, 58, 41)
	resetBtn.Font = Enum.Font.FredokaOne
	resetBtn.TextSize = 14
	resetBtn.Parent = actionsBar

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 12)
	resetCorner.Parent = resetBtn

	resetBtn.MouseButton1Click:Connect(function()
		print("[CaravanUIController] Reset to default requested")
	end)
end

--=============================================================================
-- NAVIGATION
--=============================================================================

--[[
	Switches the active tab and refreshes content.
]]
function CaravanUIController:SwitchTab(tabKey: string)
	currentTab = tabKey
	print("[CaravanUIController] Switching to tab:", tabKey)

	-- Refresh tab button visuals
	local tabBar = garageFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, child in ipairs(tabBar:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundTransparency = child.Name == tabKey and 0 or 0.5
			end
		end
	end

	-- Refresh content based on tab
	if tabKey == "Exterior" then
		self:LoadDecorationsTab()
	elseif tabKey == "Interior" then
		self:LoadDecorationsTab()
	elseif tabKey == "Upgrades" then
		self:LoadUpgradesTab()
	elseif tabKey == "Biomes" then
		self:LoadBiomesTab()
	end
end

--=============================================================================
-- TAB CONTENT LOADERS
--=============================================================================

--[[
	Loads the decorations browser (Exterior/Interior).
	Fetches available decorations from CaravanService.
]]
function CaravanUIController:LoadDecorationsTab()
	local player = Players.LocalPlayer
	if not player then return end

	local result = self.CaravanService:GetAvailableDecorations(player)
	if result then
		print("[CaravanUIController] Loaded", #result, "decorations")
	end
end

--[[
	Loads the upgrades tab.
	Fetches available upgrades from CaravanService.
]]
function CaravanUIController:LoadUpgradesTab()
	local player = Players.LocalPlayer
	if not player then return end

	local result = self.CaravanService:GetAvailableUpgrades(player)
	if result then
		print("[CaravanUIController] Loaded", #result, "upgrades")
	end
end

--[[
	Loads the biomes tab.
	Fetches available biomes from CaravanService.
]]
function CaravanUIController:LoadBiomesTab()
	local player = Players.LocalPlayer
	if not player then return end

	local result = self.CaravanService:GetAvailableBiomes(player)
	if result then
		print("[CaravanUIController] Loaded", #result, "biomes")
	end
end

--=============================================================================
-- OPEN / CLOSE
--=============================================================================

--[[
	Opens the Garage UI. Called from HUDController bottom bar.
]]
function CaravanUIController:OpenGarage()
	if screenGui then
		screenGui.Enabled = true
		garageOpen = true

		-- Load default tab content
		self:SwitchTab(currentTab)
		print("[CaravanUIController] Garage opened")
	end
end

--[[
	Closes the Garage UI.
]]
function CaravanUIController:CloseGarage()
	if screenGui then
		screenGui.Enabled = false
		garageOpen = false
		print("[CaravanUIController] Garage closed")
	end
end

return CaravanUIController