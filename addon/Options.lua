-- MultiboxHelper Options Panel Module
-- Handles addon configuration interface

local addonName, addon = ...

local Options = {}
addon.Options = Options

-- Options panel variables
local optionsPanel = nil
local teamPanels = {}
local scrollFrame = nil
local scrollChild = nil

-- Debug helper functions
local function IsDebugEnabled()
    return MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.enabled
end

local function IsOptionsDebugEnabled()
    return MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.optionsPanel
end

local function DebugPrint(...)
    if IsDebugEnabled() then
        print("|cff00ff00[MBH Debug]:|r", ...)
    end
end

local function OptionsDebugPrint(...)
    if IsDebugEnabled() then
        print("|cff88ff88[MBH Options]:|r", ...)
    end
end

-- Create the main options panel
function Options.CreatePanel()
    if optionsPanel then return optionsPanel end
    
    -- Create main panel
    optionsPanel = CreateFrame("Frame", "MultiboxHelperOptionsPanel", UIParent)
    optionsPanel.name = "MultiboxHelper"
    
    -- Title
    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MultiboxHelper Configuration")
    
    -- Subtitle
    local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Manage your multiboxing teams and accounts")
    
    -- Debug Settings Section
    local debugTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    debugTitle:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    debugTitle:SetText("Debug Settings:")
    
    -- General Debug Checkbox
    local debugCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", debugTitle, "BOTTOMLEFT", 0, -5)
    debugCheckbox.Text:SetText("Enable debug logging")
    debugCheckbox:SetScript("OnClick", function(self)
        if not MultiboxHelperDB.profile.debug then
            MultiboxHelperDB.profile.debug = {}
        end
        MultiboxHelperDB.profile.debug.enabled = self:GetChecked()
        print("|cff00ff00MultiboxHelper:|r Debug logging " .. (self:GetChecked() and "enabled" or "disabled"))
    end)
    
    -- Options Panel Debug Checkbox
    local optionsDebugCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    optionsDebugCheckbox:SetPoint("TOPLEFT", debugCheckbox, "BOTTOMLEFT", 0, -5)
    optionsDebugCheckbox.Text:SetText("Show options panel debug visuals")
    optionsDebugCheckbox:SetScript("OnClick", function(self)
        if not MultiboxHelperDB.profile.debug then
            MultiboxHelperDB.profile.debug = {}
        end
        MultiboxHelperDB.profile.debug.optionsPanel = self:GetChecked()
        print("|cff00ff00MultiboxHelper:|r Options panel debug visuals " .. (self:GetChecked() and "enabled" or "disabled"))
        -- Refresh panels to apply visual changes
        Options.RefreshTeamPanels()
    end)
    
    -- Store checkbox references for refresh
    optionsPanel.debugCheckbox = debugCheckbox
    optionsPanel.optionsDebugCheckbox = optionsDebugCheckbox
    
    -- Add New Team Button
    local addButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    addButton:SetSize(150, 25)
    addButton:SetPoint("TOPLEFT", optionsDebugCheckbox, "BOTTOMLEFT", 0, -15)
    addButton:SetText("Add New Team")
    addButton:SetScript("OnClick", function()
        Options.AddNewTeam()
    end)
    
    -- Create scroll frame for teams
    scrollFrame = CreateFrame("ScrollFrame", nil, optionsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -30, 20)
    
    -- Create scroll child
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)  -- Will be resized dynamically
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Debug: Ensure scroll frame is visible
    DebugPrint("ScrollFrame created with size: " .. scrollFrame:GetWidth() .. "x" .. scrollFrame:GetHeight())
    
    -- Panel callbacks
    optionsPanel.refresh = function()
        Options.RefreshTeamPanels()
        Options.RefreshCheckboxes()
    end
    
    -- Show handler to ensure refresh when panel becomes visible
    optionsPanel:SetScript("OnShow", function()
        Options.RefreshTeamPanels()
        Options.RefreshCheckboxes()
    end)
    
    optionsPanel.okay = function()
        Options.SaveSettings()
    end
    
    optionsPanel.cancel = function()
        Options.CancelChanges()
    end
    
    optionsPanel.default = function()
        Options.RestoreDefaults()
    end
    
    -- Register with Interface Options
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(optionsPanel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        -- Modern WoW (10.0+) settings system
        local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
        category.ID = optionsPanel.name
        Settings.RegisterAddOnCategory(category)
    end
    
    return optionsPanel
end

-- Add a new team configuration section
function Options.AddNewTeam(teamName, characters)
    if not scrollFrame or not scrollChild then
        OptionsDebugPrint("ScrollFrame or scrollChild is nil, cannot create team panel")
        return
    end
    
    local teamCount = #teamPanels + 1
    teamName = teamName or ("Team" .. teamCount)
    characters = characters or ""
    
    OptionsDebugPrint("Creating team panel for: " .. teamName)
    
    -- Create team panel
    local teamPanel = CreateFrame("Frame", nil, scrollChild)
    local panelWidth = math.max(400, scrollFrame:GetWidth() - 40) -- Ensure minimum width
    teamPanel:SetSize(panelWidth, 180)
    local yOffset = -10 - (#teamPanels * 190)
    teamPanel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    
    OptionsDebugPrint("Team panel created at position: " .. yOffset .. " with width: " .. panelWidth)
    
    -- Background - conditional based on debug settings
    if IsOptionsDebugEnabled() then
        -- Debug mode: Strong visible background
        local bg = teamPanel:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        -- Border for better visibility
        local border = teamPanel:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(0.5, 0.5, 0.5, 1.0)
        
        local borderInset = CreateFrame("Frame", nil, teamPanel)
        borderInset:SetPoint("TOPLEFT", teamPanel, "TOPLEFT", 1, -1)
        borderInset:SetPoint("BOTTOMRIGHT", teamPanel, "BOTTOMRIGHT", -1, 1)
        
        local innerBg = borderInset:CreateTexture(nil, "BACKGROUND")
        innerBg:SetAllPoints()
        innerBg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    else
        -- Normal mode: Subtle background
        local bg = teamPanel:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.05, 0.2)  -- Very subtle
        
        -- Subtle border
        local border = teamPanel:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        
        local borderInset = CreateFrame("Frame", nil, teamPanel)
        borderInset:SetPoint("TOPLEFT", teamPanel, "TOPLEFT", 1, -1)
        borderInset:SetPoint("BOTTOMRIGHT", teamPanel, "BOTTOMRIGHT", -1, 1)
        
        local innerBg = borderInset:CreateTexture(nil, "BACKGROUND")
        innerBg:SetAllPoints()
        innerBg:SetColorTexture(0.0, 0.0, 0.0, 0.0)  -- Transparent
    end
    
    -- Team name label
    local nameLabel = teamPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", teamPanel, "TOPLEFT", 10, -10)
    nameLabel:SetText("Team Name:")
    
    -- Team name edit box
    local nameEditBox = CreateFrame("EditBox", nil, teamPanel, "InputBoxTemplate")
    nameEditBox:SetSize(200, 20)
    nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameEditBox:SetText(teamName)
    nameEditBox:SetAutoFocus(false)
    nameEditBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    -- Characters label
    local charactersLabel = teamPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    charactersLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -15)
    charactersLabel:SetText("Characters (one per line, format: Name-Server):")
    
    -- Characters text area
    local charactersFrame = CreateFrame("Frame", nil, teamPanel, "InsetFrameTemplate")
    charactersFrame:SetSize(400, 100)
    charactersFrame:SetPoint("TOPLEFT", charactersLabel, "BOTTOMLEFT", 0, -5)
    
    local charactersEditBox = CreateFrame("EditBox", nil, charactersFrame)
    charactersEditBox:SetMultiLine(true)
    charactersEditBox:SetSize(380, 80)
    charactersEditBox:SetPoint("TOPLEFT", charactersFrame, "TOPLEFT", 10, -10)
    charactersEditBox:SetFontObject("ChatFontNormal")
    charactersEditBox:SetText(characters)
    charactersEditBox:SetAutoFocus(false)
    charactersEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    -- Delete button (trash icon)
    local deleteButton = CreateFrame("Button", nil, teamPanel, "UIPanelButtonTemplate")
    deleteButton:SetSize(25, 25)
    deleteButton:SetPoint("TOPRIGHT", teamPanel, "TOPRIGHT", -10, -5)
    deleteButton:SetText("X")
    deleteButton:SetScript("OnClick", function()
        Options.DeleteTeam(teamPanel)
    end)
    
    -- Tooltip for delete button
    deleteButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Delete this team", 1, 1, 1)
        GameTooltip:Show()
    end)
    deleteButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Store references
    teamPanel.nameEditBox = nameEditBox
    teamPanel.charactersEditBox = charactersEditBox
    teamPanel.deleteButton = deleteButton
    
    table.insert(teamPanels, teamPanel)
    Options.UpdateScrollFrameSize()
    
    return teamPanel
end

-- Delete a team panel
function Options.DeleteTeam(teamPanel)
    -- Find and remove from teamPanels table
    for i, panel in ipairs(teamPanels) do
        if panel == teamPanel then
            table.remove(teamPanels, i)
            break
        end
    end
    
    -- Hide and clean up the panel
    teamPanel:Hide()
    teamPanel:SetParent(nil)
    
    -- Reposition remaining panels
    for i, panel in ipairs(teamPanels) do
        panel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10 - ((i-1) * 190))
    end
    
    Options.UpdateScrollFrameSize()
end

-- Update scroll frame content size
function Options.UpdateScrollFrameSize()
    if not scrollChild then
        OptionsDebugPrint("scrollChild is nil in UpdateScrollFrameSize")
        return
    end
    
    local height = math.max(100, #teamPanels * 190 + 20)
    local width = scrollFrame and scrollFrame:GetWidth() or 400
    
    scrollChild:SetSize(width, height)
    
    OptionsDebugPrint("Updated scroll child size to: " .. width .. "x" .. height .. " for " .. #teamPanels .. " panels")
end

-- Refresh checkbox states from saved data
function Options.RefreshCheckboxes()
    if not optionsPanel then return end
    
    if optionsPanel.debugCheckbox then
        local debugEnabled = MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.enabled
        optionsPanel.debugCheckbox:SetChecked(debugEnabled or false)
    end
    
    if optionsPanel.optionsDebugCheckbox then
        local optionsDebugEnabled = MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.optionsPanel
        optionsPanel.optionsDebugCheckbox:SetChecked(optionsDebugEnabled or false)
    end
end

-- Refresh team panels from saved data
function Options.RefreshTeamPanels()
    -- Clear existing panels
    for _, panel in ipairs(teamPanels) do
        panel:Hide()
        panel:SetParent(nil)
    end
    teamPanels = {}
    
    -- Debug: Check if data exists (only if debug enabled)
    if not MultiboxHelperDB then
        DebugPrint("MultiboxHelperDB is nil")
        return
    end
    
    if not MultiboxHelperDB.profile then
        DebugPrint("MultiboxHelperDB.profile is nil")
        return
    end
    
    if not MultiboxHelperDB.profile.teams then
        DebugPrint("MultiboxHelperDB.profile.teams is nil")
        return
    end
    
    -- Create panels from saved teams
    local teamCount = 0
    for teamName, characters in pairs(MultiboxHelperDB.profile.teams) do
        teamCount = teamCount + 1
        local characterString = table.concat(characters, "\n")
        Options.AddNewTeam(teamName, characterString)
    end
    
    OptionsDebugPrint("Loaded " .. teamCount .. " teams, created " .. #teamPanels .. " panels")
    
    -- If no teams exist, show a helpful message
    if #teamPanels == 0 then
        if scrollChild then
            local helpText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            helpText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -20)
            helpText:SetText("No teams configured yet. Click 'Add New Team' to get started!")
        end
    end
end

-- Save settings from UI to saved variables
function Options.SaveSettings()
    if not MultiboxHelperDB.profile then
        MultiboxHelperDB.profile = {}
    end
    
    MultiboxHelperDB.profile.teams = {}
    
    for _, panel in ipairs(teamPanels) do
        local teamName = panel.nameEditBox:GetText():trim()
        local charactersText = panel.charactersEditBox:GetText():trim()
        
        if teamName ~= "" and charactersText ~= "" then
            local characters = {}
            for line in charactersText:gmatch("[^\r\n]+") do
                local character = line:trim()
                if character ~= "" then
                    table.insert(characters, character)
                end
            end
            
            if #characters > 0 then
                MultiboxHelperDB.profile.teams[teamName] = characters
            end
        end
    end
    
    -- Rebuild team lookup and refresh UI
    addon.Core.BuildTeamLookup()
    if addon.UI.frame and addon.UI.frame:IsVisible() then
        addon.UI.RecreateMainFrame()
    end
    
    print("|cff00ff00MultiboxHelper:|r Settings saved!")
end

-- Cancel changes (reload from saved data)
function Options.CancelChanges()
    Options.RefreshTeamPanels()
end

-- Restore default settings
function Options.RestoreDefaults()
    -- Clear all teams
    for _, panel in ipairs(teamPanels) do
        panel:Hide()
        panel:SetParent(nil)
    end
    teamPanels = {}
    
    -- Show helpful message
    local helpText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    helpText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -20)
    helpText:SetText("All teams cleared. Click 'Add New Team' to configure your teams.")
    
    Options.UpdateScrollFrameSize()
end

-- Initialize options panel
function Options.Initialize()
    DebugPrint("Options.Initialize() called")
    Options.CreatePanel()
    
    -- Initial refresh to load saved data
    if MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.teams then
        DebugPrint("Performing initial refresh with saved data")
        Options.RefreshTeamPanels()
    else
        DebugPrint("No saved data found during initialization")
    end
end

-- Event handling for initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        DebugPrint("ADDON_LOADED event for " .. loadedAddon)
        -- Delay initialization slightly to ensure saved variables are fully loaded
        C_Timer.After(0.1, function()
            Options.Initialize()
        end)
    end
end)