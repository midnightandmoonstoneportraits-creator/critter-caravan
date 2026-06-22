--[[
	FieldJournalController
	Client-side controller for the Field Journal — a diegetic "storybook"
	interface that shows real-time discovery counts, creature collection,
	and mutation history.

	Styled per UI_DESIGN.md: hand-illustrated storybook aesthetic,
	Warm Cream palette, Fredoka One typography.
]]

local Knit = require(script.Parent.Parent.Knit)

local FieldJournalController = Knit.CreateController {
	Name = "FieldJournalController",
}

local Players = game:GetService("Players")

-- Palette
local WARM_CREAM = Color3.fromRGB(255, 248, 238)
local SOFT_AMBER = Color3.fromRGB(245, 214, 168)
local EMBER_ORANGE = Color3.fromRGB(232, 145, 90)
local DEEP_COCOA = Color3.fromRGB(92, 58, 41)
local GLOW_MINT = Color3.fromRGB(126, 217, 169)

-- UI state
local screenGui
local journalFrame
local journalOpen = false
local refreshConnection

function FieldJournalController:KnitStart()
	print("[FieldJournalController] Initialized")

	self.CreatureService = Knit.GetService("CreatureService")
	self.PlayerDataService = Knit.GetService("PlayerDataService")
	self.NestingNookService = Knit.GetService("NestingNookService")

	local player = Players.LocalPlayer
	if player then
		local playerGui = player:WaitForChild("PlayerGui")
		self:CreateJournalUI(playerGui)
	end
end

--[[
	Opens the Field Journal. Called from HUDController.
]]
function FieldJournalController:OpenJournal()
	if screenGui then
		screenGui.Enabled = true
		journalOpen = true
		self:RefreshJournal()
		print("[FieldJournalController] Journal opened")
	end
end

--[[
	Closes the Field Journal.
]]
function FieldJournalController:CloseJournal()
	if screenGui then
		screenGui.Enabled = false
		journalOpen = false
	end
end

--=============================================================================
-- UI CREATION
--=============================================================================

function FieldJournalController:CreateJournalUI(playerGui: Instance)
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CritterCaravan_FieldJournal"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Backdrop
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	-- Journal panel — styled as an open book
	journalFrame = Instance.new("Frame")
	journalFrame.Name = "JournalPanel"
	journalFrame.Size = UDim2.new(0, 800, 0, 560)
	journalFrame.Position = UDim2.new(0.5, -400, 0.5, -280)
	journalFrame.BackgroundColor3 = WARM_CREAM
	journalFrame.BorderSizePixel = 0
	journalFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = journalFrame

	-- Shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014264566"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.65
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Parent = journalFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 60)
	titleBar.BackgroundColor3 = SOFT_AMBER
	titleBar.BorderSizePixel = 0
	titleBar.Parent = journalFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 20)
	titleCorner.Parent = titleBar

	-- Decorative spine line
	local spine = Instance.new("Frame")
	spine.Name = "Spine"
	spine.Size = UDim2.new(0, 4, 1, 0)
	spine.Position = UDim2.new(0.5, -2, 0, 0)
	spine.BackgroundColor3 = DEEP_COCOA
	spine.BackgroundTransparency = 0.7
	spine.BorderSizePixel = 0
	spine.Parent = titleBar

	-- Title text (left page)
	local titleLeft = Instance.new("TextLabel")
	titleLeft.Name = "TitleLeft"
	titleLeft.Size = UDim2.new(0.5, -20, 1, 0)
	titleLeft.Position = UDim2.new(0, 16, 0, 0)
	titleLeft.BackgroundTransparency = 1
	titleLeft.Text = "📖 Field Journal"
	titleLeft.TextColor3 = DEEP_COCOA
	titleLeft.Font = Enum.Font.FredokaOne
	titleLeft.TextSize = 26
	titleLeft.TextXAlignment = Enum.TextXAlignment.Left
	titleLeft.Parent = titleBar

	-- Statistics (right page)
	local titleRight = Instance.new("TextLabel")
	titleRight.Name = "TitleRight"
	titleRight.Size = UDim2.new(0.5, -20, 1, 0)
	titleRight.Position = UDim2.new(0.5, 8, 0, 0)
	titleRight.BackgroundTransparency = 1
	titleRight.Text = "Discoveries"
	titleRight.TextColor3 = DEEP_COCOA
	titleRight.Font = Enum.Font.FredokaOne
	titleRight.TextSize = 26
	titleRight.TextXAlignment = Enum.TextXAlignment.Left
	titleRight.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.BackgroundColor3 = EMBER_ORANGE
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 22
	closeBtn.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		self:CloseJournal()
	end)

	-- Content area (two columns)
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -32, 1, -80)
	contentArea.Position = UDim2.new(0, 16, 0, 68)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = journalFrame

	-- Left column — creature collection
	self:CreateLeftColumn(contentArea)

	-- Right column — stats + history
	self:CreateRightColumn(contentArea)

	-- Auto-refresh every 5 seconds while open
	refreshConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if journalOpen then
			self:RefreshJournal()
		end
	end)
end

function FieldJournalController:CreateLeftColumn(parent: Frame)
	local leftCol = Instance.new("Frame")
	leftCol.Name = "LeftColumn"
	leftCol.Size = UDim2.new(0.5, -8, 1, 0)
	leftCol.BackgroundTransparency = 1
	leftCol.Parent = parent

	-- Section header
	local header = Instance.new("TextLabel")
	header.Name = "CollectionHeader"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = "Creature Collection"
	header.TextColor3 = DEEP_COCOA
	header.Font = Enum.Font.FredokaOne
	header.TextSize = 20
	header.Parent = leftCol

	-- Scrolling collection list
	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "CreatureList"
	listContainer.Size = UDim2.new(1, 0, 1, -40)
	listContainer.Position = UDim2.new(0, 0, 0, 40)
	listContainer.BackgroundColor3 = Color3.fromRGB(245, 245, 235)
	listContainer.BackgroundTransparency = 0.5
	listContainer.BorderSizePixel = 0
	listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	listContainer.ScrollBarThickness = 4
	listContainer.Parent = leftCol

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 8)
	listCorner.Parent = listContainer

	-- Store reference for refresh
	self._leftColParent = parent
	self._creatureList = listContainer
end

function FieldJournalController:CreateRightColumn(parent: Frame)
	local rightCol = Instance.new("Frame")
	rightCol.Name = "RightColumn"
	rightCol.Size = UDim2.new(0.5, -8, 1, 0)
	rightCol.Position = UDim2.new(0.5, 8, 0, 0)
	rightCol.BackgroundTransparency = 1
	rightCol.Parent = parent

	-- Stats header
	local header = Instance.new("TextLabel")
	header.Name = "StatsHeader"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = "Explorer Stats"
	header.TextColor3 = DEEP_COCOA
	header.Font = Enum.Font.FredokaOne
	header.TextSize = 20
	header.Parent = rightCol

	-- Stats area
	self._statsArea = Instance.new("Frame")
	self._statsArea.Name = "StatsArea"
	self._statsArea.Size = UDim2.new(1, 0, 0, 120)
	self._statsArea.Position = UDim2.new(0, 0, 0, 35)
	self._statsArea.BackgroundColor3 = Color3.fromRGB(245, 245, 235)
	self._statsArea.BackgroundTransparency = 0.5
	self._statsArea.BorderSizePixel = 0
	self._statsArea.Parent = rightCol

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = self._statsArea

	-- Breeding history header
	local breedHeader = Instance.new("TextLabel")
	breedHeader.Name = "BreedingHeader"
	breedHeader.Size = UDim2.new(1, 0, 0, 30)
	breedHeader.Position = UDim2.new(0, 0, 0, 165)
	breedHeader.BackgroundTransparency = 1
	breedHeader.Text = "Breeding History"
	breedHeader.TextColor3 = DEEP_COCOA
	breedHeader.Font = Enum.Font.FredokaOne
	breedHeader.TextSize = 20
	breedHeader.Parent = rightCol

	-- Breeding history list
	self._breedHistoryList = Instance.new("ScrollingFrame")
	self._breedHistoryList.Name = "BreedingHistory"
	self._breedHistoryList.Size = UDim2.new(1, 0, 1, -205)
	self._breedHistoryList.Position = UDim2.new(0, 0, 0, 200)
	self._breedHistoryList.BackgroundColor3 = Color3.fromRGB(245, 245, 235)
	self._breedHistoryList.BackgroundTransparency = 0.5
	self._breedHistoryList.BorderSizePixel = 0
	self._breedHistoryList.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._breedHistoryList.ScrollBarThickness = 4
	self._breedHistoryList.Parent = rightCol

	local breedListCorner = Instance.new("UICorner")
	breedListCorner.CornerRadius = UDim.new(0, 8)
	breedListCorner.Parent = self._breedHistoryList
end

--=============================================================================
-- DATA REFRESH
--=============================================================================

--[[
	Refreshes all journal data from the backend services.
	Called periodically while the journal is open.
]]
function FieldJournalController:RefreshJournal()
	local player = Players.LocalPlayer
	if not player then return end

	-- Get collection data
	local collectionResult = self.CreatureService:GetPlayerCollection(player)
	self:UpdateCreatureList(collectionResult.collected or {})

	-- Get breeding history
	local history = self.NestingNookService:GetBreedingHistory(player)
	self:UpdateBreedingHistory(history or {})

	-- Update stats
	self:UpdateStats(collectionResult.collected or {}, history or {})
end

--[[
	Updates the creature collection list.
]]
function FieldJournalController:UpdateCreatureList(collection: table)
	if not self._creatureList then return end

	-- Clear existing entries
	for _, child in ipairs(self._creatureList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local yOffset = 5
	local entryCount = 0

	for creatureType, record in pairs(collection) do
		entryCount += 1

		local entry = Instance.new("Frame")
		entry.Name = creatureType
		entry.Size = UDim2.new(1, -10, 0, 36)
		entry.Position = UDim2.new(0, 5, 0, yOffset)
		entry.BackgroundColor3 = WARM_CREAM
		entry.BorderSizePixel = 0
		entry.Parent = self._creatureList

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 8)
		entryCorner.Parent = entry

		-- Creature name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.6, -5, 1, 0)
		nameLabel.Position = UDim2.new(0, 8, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "★ " .. creatureType
		nameLabel.TextColor3 = DEEP_COCOA
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entry

		-- Count badge
		local countBadge = Instance.new("Frame")
		countBadge.Name = "Count"
		countBadge.Size = UDim2.new(0, 40, 0, 24)
		countBadge.Position = UDim2.new(1, -48, 0.5, -12)
		countBadge.BackgroundColor3 = SOFT_AMBER
		countBadge.BorderSizePixel = 0
		countBadge.Parent = entry

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 6)
		badgeCorner.Parent = countBadge

		local countText = Instance.new("TextLabel")
		countText.Size = UDim2.new(1, 0, 1, 0)
		countText.BackgroundTransparency = 1
		countText.Text = "x" .. tostring(record.TotalFound or 0)
		countText.TextColor3 = DEEP_COCOA
		countText.Font = Enum.Font.FredokaOne
		countText.TextSize = 14
		countText.Parent = countBadge

		-- Mutation tags
		local mutCount = 0
		for _ in pairs(record.MutationsFound or {}) do
			mutCount += 1
		end
		if mutCount > 0 then
			local mutIcon = Instance.new("TextLabel")
			mutIcon.Name = "Mutations"
			mutIcon.Size = UDim2.new(0, 30, 0, 20)
			mutIcon.Position = UDim2.new(0.6, 0, 0.5, -10)
			mutIcon.BackgroundTransparency = 1
			mutIcon.Text = "✨" .. tostring(mutCount)
			mutIcon.TextColor3 = Color3.fromRGB(200, 120, 255)
			mutIcon.Font = Enum.Font.FredokaOne
			mutIcon.TextSize = 12
			mutIcon.Parent = entry
		end

		yOffset += 40
	end

	-- Update canvas size
	self._creatureList.CanvasSize = UDim2.new(0, 0, 0, math.max(yOffset + 5, 50))

	-- Empty state
	if entryCount == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "EmptyState"
		empty.Size = UDim2.new(1, -10, 0, 40)
		empty.Position = UDim2.new(0, 5, 0, 10)
		empty.BackgroundTransparency = 1
		empty.Text = "No creatures discovered yet!\nExplore to find your first friend."
		empty.TextColor3 = Color3.fromRGB(180, 160, 140)
		empty.Font = Enum.Font.FredokaOne
		empty.TextSize = 14
		empty.TextWrapped = true
		empty.Parent = self._creatureList
		self._creatureList.CanvasSize = UDim2.new(0, 0, 0, 60)
	end
end

--[[
	Updates the explorer stats section.
]]
function FieldJournalController:UpdateStats(collection: table, history: table)
	if not self._statsArea then return end

	-- Clear
	for _, child in ipairs(self._statsArea:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local totalDiscovered = 0
	local totalMutations = 0
	for _, record in pairs(collection) do
		totalDiscovered += record.TotalFound or 0
		for _ in pairs(record.MutationsFound or {}) do
			totalMutations += 1
		end
	end

	local uniqueTypes = 0
	for _ in pairs(collection) do
		uniqueTypes += 1
	end

	local stats = {
		{ "Unique Species", tostring(uniqueTypes) },
		{ "Total Discovered", tostring(totalDiscovered) },
		{ "Mutations Found", tostring(totalMutations) },
		{ "Breeding Attempts", tostring(#(history or {})) },
	}

	for i, stat in ipairs(stats) do
		local label = Instance.new("TextLabel")
		label.Name = stat[1]
		label.Size = UDim2.new(1, -10, 0, 24)
		label.Position = UDim2.new(0, 5, 0, (i - 1) * 26 + 5)
		label.BackgroundTransparency = 1
		label.Text = stat[1] .. ":  " .. stat[2]
		label.TextColor3 = DEEP_COCOA
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = self._statsArea
	end
end

--[[
	Updates the breeding history list.
]]
function FieldJournalController:UpdateBreedingHistory(history: table)
	if not self._breedHistoryList then return end

	for _, child in ipairs(self._breedHistoryList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local yOffset = 5
	local entryCount = 0

	-- Show most recent first (iterate backwards)
	for i = #history, math.max(1, #history - 20), -1 do
		local entry = history[i]
		entryCount += 1

		local frame = Instance.new("Frame")
		frame.Name = "Breed" .. i
		frame.Size = UDim2.new(1, -10, 0, 28)
		frame.Position = UDim2.new(0, 5, 0, yOffset)
		frame.BackgroundColor3 = WARM_CREAM
		frame.BorderSizePixel = 0
		frame.Parent = self._breedHistoryList

		local frameCorner = Instance.new("UICorner")
		frameCorner.CornerRadius = UDim.new(0, 6)
		frameCorner.Parent = frame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -5, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = string.format("%s → %s (%s)",
			entry.parentA or "?",
			entry.offspringType or "?",
			entry.offspringRarity or "?")
		label.TextColor3 = DEEP_COCOA
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = frame

		yOffset += 32
	end

	self._breedHistoryList.CanvasSize = UDim2.new(0, 0, 0, math.max(yOffset + 5, 50))

	if entryCount == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "EmptyState"
		empty.Size = UDim2.new(1, -10, 0, 40)
		empty.Position = UDim2.new(0, 5, 0, 10)
		empty.BackgroundTransparency = 1
		empty.Text = "No breeding history yet.\nCombine creatures in the Nesting Nook!"
		empty.TextColor3 = Color3.fromRGB(180, 160, 140)
		empty.Font = Enum.Font.FredokaOne
		empty.TextSize = 14
		empty.TextWrapped = true
		empty.Parent = self._breedHistoryList
		self._breedHistoryList.CanvasSize = UDim2.new(0, 0, 0, 60)
	end
end

return FieldJournalController