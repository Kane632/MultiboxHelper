-- Multibox Helper Addon

-- Team configuration using a map structure
local teams = {
    team3 = {
        "Alfredabo-Zul'jin",
        "Aboalfred-Zul'jin",
        "Alfredabos-Zul'jin",
        "Alfrred-Zul'jin",
        "Alfredd-Zul'jin",
        "Alfsac-Zul'jin",
        "Elemeny-Zul'jin",
        "Venjo-Zul'jin",
        "Naluk-Zul'jin",
        "Alfari-Zul'jin",
        "Hotperro-Zul'jin",
        "Duranin-Zul'jin",
        "Naosis-Zul'jin",
    },
    team6 = {
        "Nalut-Dragonmaw",
        "Ignath-Zul'jin",
        "Naosus-Zul'jin",
        "Nalok-Zul'jin",
    }
}

-- Create a flat lookup table for all team members
local allTeamMembers = {}
for teamName, members in pairs(teams) do
    for _, member in ipairs(members) do
        allTeamMembers[member] = teamName
    end
end

-- === Core functions ===

-- Get current player's full name (name-server)
local function GetCurrentPlayerName()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    return playerName .. "-" .. realmName
end

-- Check if current player is in a specific team
local function IsPlayerInTeam(teamName)
    local currentPlayer = GetCurrentPlayerName()
    return allTeamMembers[currentPlayer] == teamName
end

local function InviteTeam(team)
    for _, name in ipairs(team) do
        C_PartyInfo.InviteUnit(name)
    end
end

local function LeaveParty()
    C_PartyInfo.LeaveParty()
end

-- Check if a name-server combination is in our teams
local function IsTeamMember(fullName)
    return allTeamMembers[fullName] ~= nil
end

-- Get team members currently in the group/raid
local function GetTeamMembersInGroup()
    local teamMembersInGroup = {}
    local numGroupMembers = GetNumGroupMembers()
    
    for i = 1, numGroupMembers do
        local unit = "raid" .. i
        if not IsInRaid() then
            if i == 1 then
                unit = "player"
            else
                unit = "party" .. (i - 1)
            end
        end
        
        local name, server = UnitName(unit)
        if name then
            -- If server is nil (same-server case), use current realm
            if not server then
                server = GetRealmName()
            end
            
            local fullName = name .. "-" .. server
            if IsTeamMember(fullName) then
                table.insert(teamMembersInGroup, {
                    fullName = fullName,
                    shortName = name,
                    unit = unit
                })
            end
        end
    end
    
    return teamMembersInGroup
end

-- === UI Panel ===

-- Check which teams the current player is in
local playerInTeam3 = IsPlayerInTeam("team3")
local playerInTeam6 = IsPlayerInTeam("team6")

-- Calculate frame height based on which buttons will be shown
local baseHeight = 120  -- Base height for frame with focus buttons
local buttonHeight = 30 -- Height for each team button
local frameHeight = baseHeight
if not playerInTeam3 then
    frameHeight = frameHeight + buttonHeight
end
if not playerInTeam6 then
    frameHeight = frameHeight + buttonHeight
end

local f = CreateFrame("Frame", "MultiboxHelperFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(180, frameHeight)
f:SetPoint("CENTER")
f.title = f:CreateFontString(nil, "OVERLAY")
f.title:SetFontObject("GameFontHighlight")
f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
f.title:SetText("Multibox Helper")

f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)

-- Button factory
local function CreateButton(name, parent, label, x, y, onclick)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetSize(140, 25)
    b:SetPoint("TOP", parent, "TOP", x, y)
    b:SetText(label)
    b:SetScript("OnClick", onclick)
    return b
end

-- Create team buttons conditionally
local currentY = -30
if not playerInTeam3 then
    CreateButton("InviteTeam3Btn", f, "Invite Team 3", 0, currentY, function() InviteTeam(teams.team3) end)
    currentY = currentY - 30
end

if not playerInTeam6 then
    CreateButton("InviteTeam6Btn", f, "Invite Team 6", 0, currentY, function() InviteTeam(teams.team6) end)
    currentY = currentY - 30
end

CreateButton("LeavePartyBtn", f, "Leave Party", 0, currentY, function() LeaveParty() end)

-- Dynamic Focus buttons system
local focusButtons = {}
local buttonSize = 40
local buttonSpacing = 5
local startY = currentY - 30  -- Position focus buttons below the Leave Party button

-- Function to clear all focus buttons
local function ClearFocusButtons()
    for _, button in pairs(focusButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    focusButtons = {}
end

-- Function to create focus buttons for team members in group
local function CreateFocusButtons()
    ClearFocusButtons()
    
    local teamMembers = GetTeamMembersInGroup()
    local currentPlayer = GetCurrentPlayerName()
    
    -- Always add "Me" and "Clear" buttons
    local allButtons = {}
    
    -- Add team members (excluding current player)
    for _, member in ipairs(teamMembers) do
        if member.fullName ~= currentPlayer then
            table.insert(allButtons, {
                text = member.shortName,
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
        local button = CreateFrame("Button", "DynamicFocusBtn" .. i, f, "SecureActionButtonTemplate,UIPanelButtonTemplate")
        button:SetSize(buttonSize, 20)
        
        -- Calculate position
        local x = (currentCol - 1) * (buttonSize + buttonSpacing)  -- -1, 0, 1 for columns
        local y = startY - (currentRow * 25)
        
        button:SetPoint("TOP", f, "TOP", x, y)
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

-- Event handler for group changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MultiboxHelper" then
        CreateFocusButtons()
    elseif event == "GROUP_ROSTER_UPDATE" then
        CreateFocusButtons()
    end
end)

-- Initial creation of focus buttons
CreateFocusButtons()

