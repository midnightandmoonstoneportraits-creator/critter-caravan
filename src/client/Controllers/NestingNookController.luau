--[[
    NestingNookController
    Client-side controller for the Creature Breeding & Mutation interface.
    Provides the Nesting Nook UI for:
    - Selecting two parent creatures
    - Viewing compatibility
    - Starting breeding with optional catalysts
    - Viewing breeding progress timer
    - Mutation reveal animation sequence

    Based on GDD Section 3 — Creature Mutation System.
]]

local Knit = require(script.Parent.Parent.Knit)

local NestingNookController = Knit.CreateController {
    Name = "NestingNookController",
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- UI state
local screenGui
local nookFrame
local currentState = "idle" -- idle | selecting | breeding | complete

function NestingNookController:KnitStart()
    print("[NestingNookController] Initialized")

    self.NestingNookService = Knit.GetService("NestingNookService")

    local player = Players.LocalPlayer
    if player then
        local playerGui = player:WaitForChild("PlayerGui")
        self:CreateNestingNookUI(playerGui)
    end
end

--=============================================================================
-- UI CREATION
--=============================================================================

function NestingNookController:CreateNestingNookUI(playerGui: Instance)
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CritterCaravan_NestingNook"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.6
    backdrop.BorderSizePixel = 0
    backdrop.Parent = screenGui

    -- Main nesting nook panel
    nookFrame = Instance.new("Frame")
    nookFrame.Name = "NookPanel"
    nookFrame.Size = UDim2.new(0, 700, 0, 500)
    nookFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    nookFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 238) -- Warm Cream
    nookFrame.BorderSizePixel = 0
    nookFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = nookFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Color3.fromRGB(245, 214, 168) -- Soft Amber
    titleBar.BorderSizePixel = 0
    titleBar.Parent = nookFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 20)
    titleCorner.Parent = titleBar

    -- Decorative spine line (storybook two-page feel)
    local spine = Instance.new("Frame")
    spine.Name = "Spine"
    spine.Size = UDim2.new(0, 4, 1, 0)
    spine.Position = UDim2.new(0.5, -2, 0, 0)
    spine.BackgroundColor3 = Color3.fromRGB(92, 58, 41)
    spine.BackgroundTransparency = 0.7
    spine.BorderSizePixel = 0
    spine.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐾 Nesting Nook"
    title.TextColor3 = Color3.fromRGB(92, 58, 41)
    title.Font = Enum.Font.FredokaOne
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -48, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(232, 145, 90)
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
        self:CloseNook()
    end)

    -- Content sections (built by state)
    self:BuildIdleState()
end

--=============================================================================
-- STATE: IDLE — Two empty parent slots
--=============================================================================

function NestingNookController:BuildIdleState()
    self:ClearContent()

    local container = Instance.new("Frame")
    container.Name = "Content"
    container.Size = UDim2.new(1, -40, 1, -110)
    container.Position = UDim2.new(0, 20, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = nookFrame

    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, 0, 0, 40)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Select two compatible creatures to begin breeding!"
    instructions.TextColor3 = Color3.fromRGB(92, 58, 41)
    instructions.Font = Enum.Font.FredokaOne
    instructions.TextSize = 18
    instructions.Parent = container

    -- Parent slots
    local slotWidth = 200
    local slotHeight = 200

    for i = 1, 2 do
        local slot = Instance.new("TextButton")
        slot.Name = "Slot" .. i
        slot.Size = UDim2.new(0, slotWidth, 0, slotHeight)
        slot.Position = UDim2.new(0, (i - 1) * (slotWidth + 30) + 100, 0, 60)
        slot.BackgroundColor3 = Color3.fromRGB(245, 214, 168)
        slot.BackgroundTransparency = 0.5
        slot.BorderSizePixel = 0
        slot.Text = "+"
        slot.TextColor3 = Color3.fromRGB(92, 58, 41)
        slot.Font = Enum.Font.FredokaOne
        slot.TextSize = 40
        slot.Parent = container

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 12)
        slotCorner.Parent = slot

        slot.MouseButton1Click:Connect(function()
            print("[NestingNookController] Select parent slot", i)
        end)
    end

    -- Parent selection label
    local label = Instance.new("TextLabel")
    label.Name = "ParentLabel"
    label.Size = UDim2.new(0, 400, 0, 30)
    label.Position = UDim2.new(0, 150, 0, 270)
    label.BackgroundTransparency = 1
    label.Text = "Parent A (70% inheritance)              Parent B (30% inheritance)"
    label.TextColor3 = Color3.fromRGB(140, 100, 80)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 12
    label.Parent = container

    -- Start Breeding button (disabled until both parents selected)
    self.startBreedingBtn = Instance.new("TextButton")
    self.startBreedingBtn.Name = "StartBreeding"
    self.startBreedingBtn.Size = UDim2.new(0, 200, 0, 45)
    self.startBreedingBtn.Position = UDim2.new(0.5, -100, 1, -60)
    self.startBreedingBtn.BackgroundColor3 = Color3.fromRGB(232, 145, 90)
    self.startBreedingBtn.BackgroundTransparency = 0.6
    self.startBreedingBtn.BorderSizePixel = 0
    self.startBreedingBtn.Text = "Start Breeding"
    self.startBreedingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.startBreedingBtn.Font = Enum.Font.FredokaOne
    self.startBreedingBtn.TextSize = 18
    self.startBreedingBtn.Active = false -- disabled
    self.startBreedingBtn.Parent = container

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 12)
    sbCorner.Parent = self.startBreedingBtn
end

--=============================================================================
-- STATE: BREEDING — Timer progress
--=============================================================================

function NestingNookController:BuildBreedingState(duration: number)
    self:ClearContent()

    local container = Instance.new("Frame")
    container.Name = "Content"
    container.Size = UDim2.new(1, -40, 1, -110)
    container.Position = UDim2.new(0, 20, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = nookFrame

    -- Incubation animation header
    local header = Instance.new("TextLabel")
    header.Name = "BreedingHeader"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Text = "🥚 Incubating... (check back soon!)"
    header.TextColor3 = Color3.fromRGB(92, 58, 41)
    header.Font = Enum.Font.FredokaOne
    header.TextSize = 22
    header.Parent = container

    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(0.8, 0, 0, 20)
    progressBg.Position = UDim2.new(0.1, 0, 0, 70)
    progressBg.BackgroundColor3 = Color3.fromRGB(200, 180, 160)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10)
    bgCorner.Parent = progressBg

    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(126, 217, 169) -- Glow Mint
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 10)
    fillCorner.Parent = progressFill

    -- Time remaining label
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, 0, 0, 30)
    timeLabel.Position = UDim2.new(0, 0, 0, 100)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "Time remaining: calculating..."
    timeLabel.TextColor3 = Color3.fromRGB(140, 100, 80)
    timeLabel.Font = Enum.Font.FredokaOne
    timeLabel.TextSize = 16
    timeLabel.Parent = container

    -- Start the timer update loop
    self:StartTimerLoop(duration, progressFill, timeLabel)

    -- Cancel button
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Name = "Cancel"
    cancelBtn.Size = UDim2.new(0, 160, 0, 40)
    cancelBtn.Position = UDim2.new(0.5, -80, 1, -60)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(92, 58, 41)
    cancelBtn.BackgroundTransparency = 0.6
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "Cancel Breeding"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.Font = Enum.Font.FredokaOne
    cancelBtn.TextSize = 14
    cancelBtn.Parent = container

    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 12)
    cancelCorner.Parent = cancelBtn

    cancelBtn.MouseButton1Click:Connect(function()
        local result = self.NestingNookService:CancelBreeding(Players.LocalPlayer)
        if result.success then
            print("[NestingNookController] Breeding cancelled")
            self:BuildIdleState()
        end
    end)
end

--[[
    Starts a timer loop that updates the progress bar and time label.
]]
function NestingNookController:StartTimerLoop(totalDuration: number, progressFill: Frame, timeLabel: TextLabel)
    local startTime = os.time()

    task.spawn(function()
        while screenGui and screenGui.Enabled do
            local elapsed = os.time() - startTime
            local remaining = math.max(0, totalDuration - elapsed)
            local progress = math.min(1, elapsed / totalDuration)

            -- Update UI
            if progressFill then
                progressFill.Size = UDim2.new(progress, 0, 1, 0)
            end
            if timeLabel then
                local minutes = math.floor(remaining / 60)
                local seconds = remaining % 60
                if remaining > 0 then
                    timeLabel.Text = string.format("Time remaining: %d:%02d", minutes, seconds)
                else
                    timeLabel.Text = "✨ Breeding complete! Claim your offspring!"
                    -- Button should change to "Claim"
                end
            end

            if remaining <= 0 then
                -- Breeding complete
                self:BuildCompleteState()
                break
            end

            task.wait(1)
        end
    end)
end

--=============================================================================
-- STATE: COMPLETE — Mutation reveal
--=============================================================================

function NestingNookController:BuildCompleteState()
    self:ClearContent()

    local container = Instance.new("Frame")
    container.Name = "Content"
    container.Size = UDim2.new(1, -40, 1, -110)
    container.Position = UDim2.new(0, 20, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = nookFrame

    -- Sparkle/Reveal header
    local header = Instance.new("TextLabel")
    header.Name = "RevealHeader"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.Text = "🎉 A New Creature Has Hatched!"
    header.TextColor3 = Color3.fromRGB(232, 145, 90)
    header.Font = Enum.Font.FredokaOne
    header.TextSize = 26
    header.Parent = container

    -- Creature reveal placeholder
    local revealBox = Instance.new("Frame")
    revealBox.Name = "RevealBox"
    revealBox.Size = UDim2.new(0, 200, 0, 200)
    revealBox.Position = UDim2.new(0.5, -100, 0, 80)
    revealBox.BackgroundColor3 = Color3.fromRGB(245, 214, 168)
    revealBox.BorderSizePixel = 0
    revealBox.Parent = container

    local revealCorner = Instance.new("UICorner")
    revealCorner.CornerRadius = UDim.new(0, 12)
    revealCorner.Parent = revealBox

    local questionMark = Instance.new("TextLabel")
    questionMark.Name = "QuestionMark"
    questionMark.Size = UDim2.new(1, 0, 1, 0)
    questionMark.BackgroundTransparency = 1
    questionMark.Text = "?"
    questionMark.TextColor3 = Color3.fromRGB(92, 58, 41)
    questionMark.Font = Enum.Font.FredokaOne
    questionMark.TextSize = 60
    questionMark.Parent = revealBox

    -- Claim button
    local claimBtn = Instance.new("TextButton")
    claimBtn.Name = "Claim"
    claimBtn.Size = UDim2.new(0, 240, 0, 50)
    claimBtn.Position = UDim2.new(0.5, -120, 1, -70)
    claimBtn.BackgroundColor3 = Color3.fromRGB(126, 217, 169) -- Glow Mint
    claimBtn.BorderSizePixel = 0
    claimBtn.Text = "✨ Claim Offspring!"
    claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    claimBtn.Font = Enum.Font.FredokaOne
    claimBtn.TextSize = 20
    claimBtn.Parent = container

    local claimCorner = Instance.new("UICorner")
    claimCorner.CornerRadius = UDim.new(0, 16)
    claimCorner.Parent = claimBtn

    claimBtn.MouseButton1Click:Connect(function()
        local result = self.NestingNookService:ClaimOffspring(Players.LocalPlayer)
        if result.success then
            self:ShowRevealAnimation(result.offspring)
        end
    end)
end

--[[
    Plays the mutation reveal animation with the offspring data.
]]
function NestingNookController:ShowRevealAnimation(offspring: table)
    self:ClearContent()

    local container = Instance.new("Frame")
    container.Name = "Content"
    container.Size = UDim2.new(1, -40, 1, -110)
    container.Position = UDim2.new(0, 20, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = nookFrame

    -- Creature name and rarity
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0, 50)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "★ " .. offspring.DisplayName .. " ★"
    nameLabel.TextColor3 = Color3.fromRGB(232, 145, 90)
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextSize = 28
    nameLabel.Parent = container

    -- Rarity badge
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(0, 160, 0, 30)
    rarityLabel.Position = UDim2.new(0.5, -80, 0, 55)
    rarityLabel.BackgroundColor3 = Color3.fromRGB(200, 120, 255) -- Mythic purple
    rarityLabel.BackgroundTransparency = offspring.RarityTier == "Mythic" and 0 or (offspring.RarityTier == "Rare" and 0.2 or 0.5)
    rarityLabel.BorderSizePixel = 0
    rarityLabel.Text = offspring.RarityTier .. " Creature"
    rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rarityLabel.Font = Enum.Font.FredokaOne
    rarityLabel.TextSize = 16
    rarityLabel.Parent = container

    local rarityCorner = Instance.new("UICorner")
    rarityCorner.CornerRadius = UDim.new(0, 12)
    rarityCorner.Parent = rarityLabel

    -- Description
    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Size = UDim2.new(1, -40, 0, 60)
    desc.Position = UDim2.new(0, 20, 0, 100)
    desc.BackgroundTransparency = 1
    desc.Text = offspring.Description or "A unique bred creature!"
    desc.TextColor3 = Color3.fromRGB(92, 58, 41)
    desc.Font = Enum.Font.FredokaOne
    desc.TextSize = 16
    desc.TextWrapped = true
    desc.Parent = container

    -- Mutation tags
    if offspring.Mutations and #offspring.Mutations > 0 then
        local mutHeader = Instance.new("TextLabel")
        mutHeader.Name = "MutationsHeader"
        mutHeader.Size = UDim2.new(1, 0, 0, 30)
        mutHeader.Position = UDim2.new(0, 0, 0, 170)
        mutHeader.BackgroundTransparency = 1
        mutHeader.Text = "Mutations:"
        mutHeader.TextColor3 = Color3.fromRGB(140, 100, 80)
        mutHeader.Font = Enum.Font.FredokaOne
        mutHeader.TextSize = 16
        mutHeader.TextXAlignment = Enum.TextXAlignment.Left
        mutHeader.Parent = container

        for i, mutation in ipairs(offspring.Mutations) do
            local tag = Instance.new("Frame")
            tag.Name = "Mutation_" .. mutation
            tag.Size = UDim2.new(0, 120, 0, 30)
            tag.Position = UDim2.new(0, (i - 1) * 130, 0, 205)
            tag.BackgroundColor3 = Color3.fromRGB(232, 145, 90)
            tag.BorderSizePixel = 0
            tag.Parent = container

            local tagCorner = Instance.new("UICorner")
            tagCorner.CornerRadius = UDim.new(0, 8)
            tagCorner.Parent = tag

            local tagText = Instance.new("TextLabel")
            tagText.Size = UDim2.new(1, 0, 1, 0)
            tagText.BackgroundTransparency = 1
            tagText.Text = "✨ " .. mutation
            tagText.TextColor3 = Color3.fromRGB(255, 255, 255)
            tagText.Font = Enum.Font.FredokaOne
            tagText.TextSize = 14
            tagText.Parent = tag
        end
    end

    -- Parent info
    local parentInfo = Instance.new("TextLabel")
    parentInfo.Name = "ParentInfo"
    parentInfo.Size = UDim2.new(1, 0, 0, 30)
    parentInfo.Position = UDim2.new(0, 0, 0, 250)
    parentInfo.BackgroundTransparency = 1
    parentInfo.Text = string.format("Parents: %s + %s", offspring.ParentA, offspring.ParentB)
    parentInfo.TextColor3 = Color3.fromRGB(140, 100, 80)
    parentInfo.Font = Enum.Font.FredokaOne
    parentInfo.TextSize = 14
    parentInfo.Parent = container

    -- Close button
    local doneBtn = Instance.new("TextButton")
    doneBtn.Name = "Done"
    doneBtn.Size = UDim2.new(0, 200, 0, 45)
    doneBtn.Position = UDim2.new(0.5, -100, 1, -60)
    doneBtn.BackgroundColor3 = Color3.fromRGB(126, 217, 169)
    doneBtn.BorderSizePixel = 0
    doneBtn.Text = "Done!"
    doneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    doneBtn.Font = Enum.Font.FredokaOne
    doneBtn.TextSize = 18
    doneBtn.Parent = container

    local doneCorner = Instance.new("UICorner")
    doneCorner.CornerRadius = UDim.new(0, 12)
    doneCorner.Parent = doneBtn

    doneBtn.MouseButton1Click:Connect(function()
        self:BuildIdleState()
    end)
end

--=============================================================================
-- HELPERS
--=============================================================================

--[[
    Clears all content elements from the nook panel.
]]
function NestingNookController:ClearContent()
    if nookFrame then
        for _, child in ipairs(nookFrame:GetChildren()) do
            if child.Name ~= "TitleBar" then
                child:Destroy()
            end
        end
    end
end

--[[
    Opens the Nesting Nook UI.
]]
function NestingNookController:OpenNook()
    if screenGui then
        screenGui.Enabled = true
        currentState = "idle"

        -- Check for existing breeding process
        local player = Players.LocalPlayer
        local status = self.NestingNookService:GetBreedingStatus(player)
        if status.active and not status.claimed then
            if status.completed then
                self:BuildCompleteState()
                currentState = "complete"
            else
                self:BuildBreedingState(status.remainingSeconds)
                currentState = "breeding"
            end
        end

        print("[NestingNookController] Nook opened")
    end
end

--[[
    Closes the Nesting Nook UI.
]]
function NestingNookController:CloseNook()
    if screenGui then
        screenGui.Enabled = false
        currentState = "idle"
        print("[NestingNookController] Nook closed")
    end
end

return NestingNookController