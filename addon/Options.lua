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

-- Helper functions
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end

-- Debug helper functions
local function IsDebugEnabled()
    return MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.enabled
end

local function IsOptionsDebugEnabled()
    return MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.optionsPanel
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
    addon.DebugPrint("ScrollFrame created with size: " .. scrollFrame:GetWidth() .. "x" .. scrollFrame:GetHeight())
    
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
    
    -- Note: Removed auto-save on hide to prevent UI position conflicts
    -- Settings are saved when user clicks OK or when changes are made
    
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
        addon.OptionsDebugPrint("ScrollFrame or scrollChild is nil, cannot create team panel")
        return
    end
    
    local teamCount = #teamPanels + 1
    teamName = teamName or ("Team" .. teamCount)
    characters = characters or ""
    
    addon.OptionsDebugPrint("Creating team panel for: " .. teamName)
    
    -- Create team panel with dynamic height
    local teamPanel = CreateFrame("Frame", nil, scrollChild)
    local panelWidth = math.max(400, scrollFrame:GetWidth() - 40) -- Ensure minimum width
    
    -- Calculate Y offset based on actual heights of existing panels
    local yOffset = -10
    for _, existingPanel in ipairs(teamPanels) do
        yOffset = yOffset - (existingPanel:GetHeight() + 10) -- Panel height + spacing
    end
    
    teamPanel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    teamPanel:SetWidth(panelWidth)
    teamPanel:SetHeight(180) -- Initial height, will be adjusted after content
    
    addon.OptionsDebugPrint("Team panel created at position: " .. yOffset .. " with width: " .. panelWidth)
    
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
    
    -- Function to save changes and update UI
    local function SaveTeamNameChange()
        -- Save settings immediately
        Options.SaveSettings()
        -- Update main UI to reflect team name changes
        if addon.UI then
            addon.UI.RefreshContent()
        end
        if IsDebugEnabled() then
            addon.DebugPrint("Team name changed, settings saved and UI updated")
        end
    end
    
    nameEditBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        SaveTeamNameChange()
    end)
    
    nameEditBox:SetScript("OnEditFocusLost", function(self)
        SaveTeamNameChange()
    end)
    
    nameEditBox:SetScript("OnTextChanged", function(self, userInput)
        -- Only save if the change was made by the user (not programmatically)
        if userInput then
            -- Use a timer to debounce rapid changes while typing
            if nameEditBox.saveTimer then
                nameEditBox.saveTimer:Cancel()
            end
            nameEditBox.saveTimer = C_Timer.NewTimer(2.0, function()
                SaveTeamNameChange()
            end)
        end
    end)
    
    -- Characters label with Edit button on the same line
    local charactersLabel = teamPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    charactersLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -15)
    charactersLabel:SetText("Characters (one per line, format: Name-Server):")
    
    -- Edit button next to the label
    local editButton = CreateFrame("Button", nil, teamPanel, "UIPanelButtonTemplate")
    editButton:SetSize(70, 20)
    editButton:SetPoint("LEFT", charactersLabel, "RIGHT", 10, 0)
    editButton:SetText("Edit")
    
    -- Characters display area - Auto-sizing read-only list
    local charactersFrame = CreateFrame("Frame", nil, teamPanel, "InsetFrameTemplate")
    charactersFrame:SetPoint("TOPLEFT", charactersLabel, "BOTTOMLEFT", 0, -5)
    charactersFrame:SetPoint("TOPRIGHT", teamPanel, "TOPRIGHT", -10, -35) -- Dynamic width
    
    -- Create auto-sizing display text
    local charactersDisplay = charactersFrame:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    charactersDisplay:SetPoint("TOPLEFT", charactersFrame, "TOPLEFT", 10, -10)
    charactersDisplay:SetPoint("TOPRIGHT", charactersFrame, "TOPRIGHT", -10, -10)
    charactersDisplay:SetJustifyH("LEFT")
    charactersDisplay:SetJustifyV("TOP")
    charactersDisplay:SetTextColor(0.9, 0.9, 0.9, 1)
    
    -- Function to update the display and auto-resize the frame
    local function UpdateCharactersDisplay()
        local currentData = teamPanel.charactersData or characters or ""
        if currentData and currentData ~= "" then
            local lines = {}
            for line in currentData:gmatch("[^\r\n]+") do
                local trimmedLine = trim(line)
                if trimmedLine ~= "" then
                    table.insert(lines, trimmedLine)
                end
            end
            if #lines > 0 then
                local displayText = table.concat(lines, "\n")
                charactersDisplay:SetText(displayText)
                
                -- Calculate required height based on number of lines
                local lineHeight = 14 -- Approximate pixels per line
                local requiredHeight = math.max(30, (#lines * lineHeight) + 20) -- +20 for padding
                charactersFrame:SetHeight(requiredHeight)
            else
                charactersDisplay:SetText("(No characters configured)")
                charactersFrame:SetHeight(30)
            end
        else
            charactersDisplay:SetText("(No characters configured)")
            charactersDisplay:SetTextColor(0.6, 0.6, 0.6, 1)
            charactersFrame:SetHeight(30)
        end
        
        -- Reset text color to normal after setting text
        charactersDisplay:SetTextColor(0.9, 0.9, 0.9, 1)
        
        -- Update team panel height to accommodate the characters frame
        local totalPanelHeight = 90 + charactersFrame:GetHeight() -- Base height + characters frame height
        teamPanel:SetHeight(totalPanelHeight)
        
        -- Reposition all panels and update scroll frame
        C_Timer.After(0.01, function()
            Options.RepositionPanels()
            Options.UpdateScrollFrameSize()
        end)
    end
    
    -- Initial display update
    UpdateCharactersDisplay()
    
    -- Set up the edit button click handler (button was created earlier)
    editButton:SetScript("OnClick", function()
        local currentData = teamPanel.charactersData or characters or ""
        Options.OpenCharacterEditor(teamPanel, currentData, UpdateCharactersDisplay)
    end)
    
    -- Store the current characters data and update function
    teamPanel.charactersData = characters
    teamPanel.UpdateCharactersDisplay = UpdateCharactersDisplay
    
    -- Create a hidden EditBox for saving compatibility
    local charactersEditBox = CreateFrame("EditBox", nil, charactersFrame)
    charactersEditBox:Hide()
    charactersEditBox:SetText(characters)
    charactersEditBox.GetText = function()
        return teamPanel.charactersData or ""
    end
    
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
    
    -- Store references for saving
    teamPanel.nameEditBox = nameEditBox
    teamPanel.charactersEditBox = charactersEditBox
    teamPanel.deleteButton = deleteButton
    
    table.insert(teamPanels, teamPanel)
    Options.UpdateScrollFrameSize()
    
    addon.OptionsDebugPrint("Team panel created and added to teamPanels. Total panels: " .. #teamPanels)
    
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

-- Reposition all team panels based on their actual heights
function Options.RepositionPanels()
    local yOffset = -10
    for _, panel in ipairs(teamPanels) do
        panel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        yOffset = yOffset - (panel:GetHeight() + 10) -- Panel height + spacing
    end
end

-- Update scroll frame content size
function Options.UpdateScrollFrameSize()
    if not scrollChild then
        addon.OptionsDebugPrint("scrollChild is nil in UpdateScrollFrameSize")
        return
    end
    
    -- Calculate total height based on actual panel heights
    local totalHeight = 20 -- Base padding
    for _, panel in ipairs(teamPanels) do
        totalHeight = totalHeight + panel:GetHeight() + 10 -- Panel height + spacing
    end
    
    local height = math.max(100, totalHeight)
    local width = scrollFrame and scrollFrame:GetWidth() or 400
    
    scrollChild:SetSize(width, height)
    
    addon.OptionsDebugPrint("Updated scroll child size to: " .. width .. "x" .. height .. " for " .. #teamPanels .. " panels")
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
        addon.DebugPrint("MultiboxHelperDB is nil")
        return
    end
    
    if not MultiboxHelperDB.profile then
        addon.DebugPrint("MultiboxHelperDB.profile is nil")
        return
    end
    
    if not MultiboxHelperDB.profile.teams then
        addon.DebugPrint("MultiboxHelperDB.profile.teams is nil")
        return
    end
    
    -- Create panels from saved teams
    local teamCount = 0
    for teamName, characters in pairs(MultiboxHelperDB.profile.teams) do
        teamCount = teamCount + 1
        local characterString = table.concat(characters, "\n")
        Options.AddNewTeam(teamName, characterString)
    end
    
    addon.OptionsDebugPrint("Loaded " .. teamCount .. " teams, created " .. #teamPanels .. " panels")
    
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
    addon.DebugPrint("SaveSettings() called")
    
    if not MultiboxHelperDB.profile then
        MultiboxHelperDB.profile = {}
    end
    
    MultiboxHelperDB.profile.teams = {}
    local savedTeamCount = 0
    
    addon.DebugPrint("Processing " .. #teamPanels .. " team panels for saving")
    
    for i, panel in ipairs(teamPanels) do
        if panel.nameEditBox and panel.charactersData then
            local teamName = trim(panel.nameEditBox:GetText())
            local charactersText = trim(panel.charactersData or "")
            
            addon.DebugPrint("Panel " .. i .. ": Name='" .. (teamName or "nil") .. "', Characters length=" .. (charactersText and #charactersText or 0))
            
            if teamName and teamName ~= "" and charactersText and charactersText ~= "" then
                local characters = {}
                for line in charactersText:gmatch("[^\r\n]+") do
                    local character = trim(line)
                    if character ~= "" then
                        table.insert(characters, character)
                    end
                end
                
                if #characters > 0 then
                    MultiboxHelperDB.profile.teams[teamName] = characters
                    savedTeamCount = savedTeamCount + 1
                    addon.DebugPrint("Saved team '" .. teamName .. "' with " .. #characters .. " characters")
                end
            else
                addon.DebugPrint("Skipping panel " .. i .. " - missing name or characters")
            end
        else
            addon.DebugPrint("Panel " .. i .. " missing nameEditBox or charactersEditBox references")
        end
    end
    
    -- Rebuild team lookup and refresh UI content without position changes
    addon.Core.BuildTeamLookup()
    if addon.UI then
        addon.UI.RefreshContent()
    end
    
    print("|cff00ff00MultiboxHelper:|r Settings saved! (" .. savedTeamCount .. " teams)")
end

-- Cancel changes (reload from saved data)
function Options.CancelChanges()
    Options.RefreshTeamPanels()
end

-- Create popup character editor (similar to TomTom's /ttpaste)
function Options.OpenCharacterEditor(teamPanel, currentText, updateCallback)
    -- Create popup frame
    local popup = CreateFrame("Frame", "MultiboxHelperCharacterEditor", UIParent, "BasicFrameTemplateWithInset")
    popup:SetSize(500, 600)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    
    -- Set title using the template's title
    popup.title = popup:CreateFontString(nil, "OVERLAY")
    popup.title:SetFontObject("GameFontHighlight")
    popup.title:SetPoint("CENTER", popup.TitleBg, "CENTER", 0, 0)
    popup.title:SetText("Edit Team Characters")
    
    -- Create the text editor
    local editFrame = CreateFrame("Frame", nil, popup, "InsetFrameTemplate")
    editFrame:SetSize(460, 480)
    editFrame:SetPoint("TOP", popup, "TOP", 0, -40)
    
    -- Multi-line EditBox (much larger)
    local editBox = CreateFrame("EditBox", nil, editFrame)
    editBox:SetMultiLine(true)
    editBox:SetSize(440, 460)
    editBox:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 10, -10)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetText(currentText or "")
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(0)
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    
    -- Instructions
    local instructions = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    instructions:SetPoint("TOPLEFT", editFrame, "BOTTOMLEFT", 10, -10)
    instructions:SetText("Enter character names, one per line (format: Name-Server)")
    instructions:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Save button
    local saveButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 25)
    saveButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -20, 20)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        local newText = editBox:GetText()
        teamPanel.charactersData = newText
        -- Update the display immediately
        if updateCallback then
            updateCallback()
        end
        popup:Hide()
        if IsDebugEnabled() then
            print("|cff00ff00[MBH Debug]:|r Character editor saved changes")
        end
    end)
    
    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 25)
    cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    -- Close button (X) functionality
    popup.CloseButton:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    -- Handle escape key
    editBox:SetScript("OnEscapePressed", function()
        popup:Hide()
    end)
    
    -- Handle enter key (allow new lines, not close)
    editBox:SetScript("OnEnterPressed", function(self)
        local cursorPos = self:GetCursorPosition()
        local text = self:GetText()
        local newText = text:sub(1, cursorPos) .. "\n" .. text:sub(cursorPos + 1)
        self:SetText(newText)
        self:SetCursorPosition(cursorPos + 1)
    end)
    
    popup:Show()
    editBox:SetFocus()
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
    if scrollChild then
        local helpText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        helpText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -20)
        helpText:SetText("All teams cleared. Click 'Add New Team' to configure your teams.")
    end
    
    Options.UpdateScrollFrameSize()
end

-- Initialize options panel
function Options.Initialize()
    addon.DebugPrint("Options.Initialize() called")
    Options.CreatePanel()
    
    -- Initial refresh to load saved data
    if MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.teams then
        addon.DebugPrint("Performing initial refresh with saved data")
        Options.RefreshTeamPanels()
    else
        addon.DebugPrint("No saved data found during initialization")
    end
end

-- Event handling for initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        addon.DebugPrint("ADDON_LOADED event for " .. loadedAddon)
        -- Delay initialization slightly to ensure saved variables are fully loaded
        C_Timer.After(0.1, function()
            Options.Initialize()
        end)
    end
end)