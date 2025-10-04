-- MultiboxHelper UI Module
-- Handles all user interface creation and management

local addonName, addon = ...

local UI = {}
addon.UI = UI

-- UI Variables
UI.frame = nil
local focusButtons = {}

-- Button configuration
local buttonSize = 40
local buttonSpacing = 5

-- Create the main addon frame
function UI.CreateMainFrame()
    if UI.frame then
        UI.frame:Show()
        return UI.frame
    end
    
    -- Get current player and available teams
    local currentPlayer = addon.Core.GetCurrentPlayerName()
    local currentPlayerTeam = nil
    local availableTeams = {}
    
    -- Check which teams exist and which team the current player belongs to
    if MultiboxHelperDB.profile.teams then
        for teamName, members in pairs(MultiboxHelperDB.profile.teams) do
            for _, member in ipairs(members) do
                if member == currentPlayer then
                    currentPlayerTeam = teamName
                    break
                end
            end
            if currentPlayerTeam ~= teamName then
                table.insert(availableTeams, {name = teamName, members = members})
            end
        end
    end
    
    -- Calculate frame height based on available teams
    local baseHeight = 120  -- Base height for frame with focus buttons
    local buttonHeight = 30 -- Height for each team button
    local frameHeight = baseHeight + (#availableTeams * buttonHeight)
    
    -- Create main frame
    local f = CreateFrame("Frame", "MultiboxHelperFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(180, frameHeight)
    
    -- Restore saved position or use default with validation
    local pos = addon.Core.GetWindowPosition()
    if pos and pos.point and pos.x and pos.y then
        -- Validate position is on screen
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()
        local frameWidth, frameHeight = f:GetSize()
        
        -- Clamp position to keep frame on screen
        local clampedX = math.max(-frameWidth/2, math.min(screenWidth - frameWidth/2, pos.x))
        local clampedY = math.max(-frameHeight/2, math.min(screenHeight - frameHeight/2, pos.y))
        
        f:SetPoint(pos.point, clampedX, clampedY)
    else
        -- Default center position
        f:SetPoint("CENTER", 0, 0)
    end
    
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
    f.title:SetText("Multibox Helper")
    
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position when moved
        local point, _, _, x, y = self:GetPoint()
        addon.Core.SaveWindowPosition(point, x, y)
    end)
    
    -- Close button functionality
    f.CloseButton:SetScript("OnClick", function()
        UI.HideFrame()
    end)
    
    -- Create team invitation buttons
    UI.CreateTeamButtons(f, availableTeams)
    
    -- Create dynamic focus buttons
    UI.CreateFocusButtons(f)
    
    -- Register for group changes
    UI.RegisterEvents(f)
    
    UI.frame = f
    addon.Core.SetUIVisible(true)
    
    return f
end

-- Create team invitation buttons
function UI.CreateTeamButtons(parent, availableTeams)
    local currentY = -30
    
    -- Create invitation buttons for teams the player is not in
    for i, team in ipairs(availableTeams) do
        local buttonName = "Invite" .. team.name:gsub("%s+", "") .. "Btn"
        local buttonLabel = "Invite " .. team.name
        
        UI.CreateButton(buttonName, parent, buttonLabel, 0, currentY, function() 
            addon.Core.InviteTeam(team.members) 
        end)
        currentY = currentY - 30
    end
    
    -- Always add Leave Party button
    UI.CreateButton("LeavePartyBtn", parent, "Leave Party", 0, currentY, function() 
        addon.Core.LeaveParty() 
    end)
    
    -- Store the Y position for focus buttons
    parent.focusButtonStartY = currentY - 30
end

-- Button factory
function UI.CreateButton(name, parent, label, x, y, onclick)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetSize(140, 25)
    b:SetPoint("TOP", parent, "TOP", x, y)
    b:SetText(label)
    b:SetScript("OnClick", onclick)
    return b
end

-- Function to clear all focus buttons
function UI.ClearFocusButtons()
    for _, button in pairs(focusButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    focusButtons = {}
end

-- Function to create focus buttons for team members in group
function UI.CreateFocusButtons(parent)
    if not parent then parent = UI.frame end
    if not parent then return end
    
    UI.ClearFocusButtons()
    
    local teamMembers = addon.Core.GetTeamMembersInGroup()
    local currentPlayer = addon.Core.GetCurrentPlayerName()
    local startY = parent.focusButtonStartY or -120
    
    -- Always add "Me" and "Clear" buttons
    local allButtons = {}
    
    -- Add team members (excluding current player)
    for _, member in ipairs(teamMembers) do
        if member.fullName ~= currentPlayer then
            -- Get team name from core lookup
            local teamName = nil
            for tName, members in pairs(MultiboxHelperDB.profile.teams) do
                for _, m in ipairs(members) do
                    if m == member.fullName then
                        teamName = tName
                        break
                    end
                end
                if teamName then break end
            end
            
            -- Extract account number from team name (e.g., "acc3" -> "3")
            local accountNumber = teamName and teamName:match("acc(%d+)") or member.shortName
            
            table.insert(allButtons, {
                text = accountNumber,
                macrotext = "/target " .. member.fullName .. "\n/focus target"
            })
        end
    end
    
    -- Add "Me" button
    table.insert(allButtons, {text = "Me", macrotext = "/focus player"})
    
    -- Add "Clear" button
    table.insert(allButtons, {text = "Clear", macrotext = "/clearfocus"})
    
    -- Calculate button positions (3 per row)
    local buttonsPerRow = 3
    local currentRow = 0
    local currentCol = 0
    
    for i, buttonData in ipairs(allButtons) do
        local button = CreateFrame("Button", "DynamicFocusBtn" .. i, parent, "SecureActionButtonTemplate,UIPanelButtonTemplate")
        button:SetSize(buttonSize, 20)
        
        -- Calculate position
        local x = (currentCol - 1) * (buttonSize + buttonSpacing)  -- -1, 0, 1 for columns
        local y = startY - (currentRow * 25)
        
        button:SetPoint("TOP", parent, "TOP", x, y)
        button:SetText(buttonData.text)
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", buttonData.macrotext)
        button:RegisterForClicks("AnyUp", "AnyDown")
        
        table.insert(focusButtons, button)
        
        -- Move to next position
        currentCol = currentCol + 1
        if currentCol >= buttonsPerRow then
            currentCol = 0
            currentRow = currentRow + 1
        end
    end
end

-- Register events for dynamic updates
function UI.RegisterEvents(frame)
    if UI.eventFrame then return end
    
    UI.eventFrame = CreateFrame("Frame")
    UI.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    
    UI.eventFrame:SetScript("OnEvent", function(self, event)
        if event == "GROUP_ROSTER_UPDATE" and UI.frame and UI.frame:IsVisible() then
            UI.CreateFocusButtons()
        end
    end)
end

-- Show the main frame
function UI.ShowFrame()
    if not UI.frame then
        UI.CreateMainFrame()
    else
        UI.frame:Show()
        addon.Core.SetUIVisible(true)
        UI.CreateFocusButtons()  -- Refresh focus buttons when showing
    end
end

-- Hide the main frame
function UI.HideFrame()
    if UI.frame then
        UI.frame:Hide()
        addon.Core.SetUIVisible(false)
    end
end

-- Toggle frame visibility
function UI.ToggleFrame()
    if UI.frame and UI.frame:IsVisible() then
        UI.HideFrame()
    else
        UI.ShowFrame()
    end
end

-- Recreate the main frame (used when settings change)
function UI.RecreateMainFrame()
    local wasVisible = UI.frame and UI.frame:IsVisible()
    
    if UI.frame then
        -- Save position before destroying
        local point, _, _, x, y = UI.frame:GetPoint()
        addon.Core.SaveWindowPosition(point, x, y)
        
        -- Destroy old frame
        UI.frame:Hide()
        UI.frame:SetParent(nil)
        UI.frame = nil
        
        -- Clear focus buttons
        UI.ClearFocusButtons()
        
        -- Unregister events
        if UI.eventFrame then
            UI.eventFrame:UnregisterAllEvents()
            UI.eventFrame = nil
        end
    end
    
    -- Recreate if it was visible
    if wasVisible then
        UI.CreateMainFrame()
    end
end