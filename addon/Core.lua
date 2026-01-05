-- MultiboxHelper Core Module
-- Handles addon initialization, saved variables, and core functionality

local addonName, addon = ...

-- Create addon namespace
MultiboxHelper = LibStub and LibStub("AceAddon-3.0"):NewAddon(addonName) or {}
addon.MultiboxHelper = MultiboxHelper

-- Saved Variables (will be loaded from SavedVariables)
MultiboxHelperDB = MultiboxHelperDB or {}

-- Default settings
local defaults = {
    char = {
        uiVisible = false,  -- UI hidden by default
        windowPosition = { point = "CENTER", x = 0, y = 0 }
    },
    profile = {
        teams = {},  -- No default teams - configured through options panel
        debug = {
            enabled = false,        -- General debug logging
            optionsPanel = false    -- Options panel visual debugging
        }
    }
}

-- Initialize saved variables with defaults
local function InitializeDB()
    print("|cff00ff00[MBH Debug]:|r InitializeDB() called")
    
    if not MultiboxHelperDB then
        print("|cffff0000[MBH Debug]:|r MultiboxHelperDB is nil, this should not happen!")
        MultiboxHelperDB = {}
    end
    
    if not MultiboxHelperDB.char then
        print("|cff00ff00[MBH Debug]:|r Creating MultiboxHelperDB.char")
        MultiboxHelperDB.char = {}
    end
    if not MultiboxHelperDB.profile then
        print("|cff00ff00[MBH Debug]:|r Creating MultiboxHelperDB.profile")
        MultiboxHelperDB.profile = {}
    end
    
    -- Merge defaults for char settings
    for key, value in pairs(defaults.char) do
        if MultiboxHelperDB.char[key] == nil then
            if type(value) == "table" then
                -- Shallow copy for tables (like windowPosition)
                MultiboxHelperDB.char[key] = CopyTable(value)
            else
                MultiboxHelperDB.char[key] = value
            end
        end
    end
    
    -- Merge defaults for profile settings
    for key, value in pairs(defaults.profile) do
        if MultiboxHelperDB.profile[key] == nil then
            addon.DebugPrint("Setting default for profile." .. key)
            if type(value) == "table" then
                -- Shallow copy for tables (like teams, debug)
                -- Note: CopyTable is a WoW API function that performs a recursive copy
                MultiboxHelperDB.profile[key] = CopyTable(value)
            else
                MultiboxHelperDB.profile[key] = value
            end
        end
    end
    
    -- Debug: Show what we have after initialization
    if MultiboxHelperDB.profile.teams then
        local teamCount = 0
        for teamName, _ in pairs(MultiboxHelperDB.profile.teams) do
            teamCount = teamCount + 1
        end
        addon.DebugPrint("After initialization, we have " .. teamCount .. " teams")
    else
        addon.DebugPrint("After initialization, teams table is still nil")
    end
end

-- Core Functions
addon.Core = {}
local Core = addon.Core

-- Expose Core to global context
_G.MultiboxHelper.Core = Core

-- Get current player's full name (name-server)
function Core.GetCurrentPlayerName()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    return playerName .. "-" .. realmName
end

-- Create a flat lookup table for all team members
local allTeamMembers = {}
function Core.BuildTeamLookup()
    allTeamMembers = {}
    if MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.teams then
        local memberCount = 0
        for teamName, members in pairs(MultiboxHelperDB.profile.teams) do
            addon.DebugPrint("Building lookup for team: " .. teamName .. " with " .. #members .. " members")
            for _, member in ipairs(members) do
                allTeamMembers[member] = teamName
                memberCount = memberCount + 1
            end
        end
        addon.DebugPrint("Built team lookup with " .. memberCount .. " total members")
    else
        addon.DebugPrint("No teams data available for building lookup")
    end
end

-- Check if current player is in a specific team
function Core.IsPlayerInTeam(teamName)
    local currentPlayer = Core.GetCurrentPlayerName()
    return allTeamMembers[currentPlayer] == teamName
end

-- Check if a name-server combination is in our teams
function Core.IsTeamMember(fullName)
    return allTeamMembers[fullName] ~= nil
end

-- Get team members currently in the group/raid
function Core.GetTeamMembersInGroup()
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
            if Core.IsTeamMember(fullName) then
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

-- Team actions
function Core.InviteTeam(team)
    for _, name in ipairs(team) do
        C_PartyInfo.InviteUnit(name)
    end
end

function Core.InviteOtherTeams()
    addon.DebugPrint("InviteOtherTeams() called")
    
    -- Get current player's full name
    local currentPlayer = Core.GetCurrentPlayerName()
    addon.DebugPrint("Current player: " .. currentPlayer)
    
    -- Find which team the current player is in
    local currentTeam = allTeamMembers[currentPlayer]
    if not currentTeam then
        print("|cffff8800MultiboxHelper:|r You are not in any configured team")
        return
    end
    
    addon.DebugPrint("Current player is in team: " .. currentTeam)
    
    -- Get all teams from the database
    if not MultiboxHelperDB or not MultiboxHelperDB.profile or not MultiboxHelperDB.profile.teams then
        print("|cffff0000MultiboxHelper:|r No team data available")
        return
    end
    
    -- Count invites sent and track which teams we invite from
    local invitesSent = 0
    local teamsInvited = {}
    
    addon.DebugPrint("|cff00ff00MultiboxHelper:|r Inviting members from OTHER teams (excluding '" .. currentTeam .. "')...")
    
    -- Loop through all teams and invite members from teams that are NOT the current team
    for teamName, teamMembers in pairs(MultiboxHelperDB.profile.teams) do
        if teamName ~= currentTeam then -- Skip current player's team
            addon.DebugPrint("Processing team: " .. teamName .. " with " .. #teamMembers .. " members")
            
            for _, member in ipairs(teamMembers) do
                addon.DebugPrint("Inviting: " .. member .. " (from team '" .. teamName .. "')")
                C_PartyInfo.InviteUnit(member)
                invitesSent = invitesSent + 1
                
                -- Track which team this invite came from
                if not teamsInvited[teamName] then
                    teamsInvited[teamName] = 0
                end
                teamsInvited[teamName] = teamsInvited[teamName] + 1
            end
        else
            addon.DebugPrint("Skipping current team: " .. teamName)
        end
    end
    
    -- Report results
    if invitesSent > 0 then
        addon.DebugPrint("|cff00ff00MultiboxHelper:|r Sent " .. invitesSent .. " invites to other teams:")
        for teamName, count in pairs(teamsInvited) do
            addon.DebugPrint("  |cff88ff88" .. teamName .. ":|r " .. count .. " invites")
        end
    else
        addon.DebugPrint("|cffff8800MultiboxHelper:|r No invites sent (no other teams configured or all members already in group)")
    end
end

function Core.LeaveParty()
    C_PartyInfo.LeaveParty()
end

-- UI State Management
function Core.SetUIVisible(visible)
    MultiboxHelperDB.char.uiVisible = visible
end

function Core.IsUIVisible()
    return MultiboxHelperDB.char.uiVisible
end

function Core.SaveWindowPosition(point, x, y)
    MultiboxHelperDB.char.windowPosition = { point = point, x = x, y = y }
end

function Core.GetWindowPosition()
    return MultiboxHelperDB.char.windowPosition
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeDB()
            Core.BuildTeamLookup()
            
            -- Initialize UI if it should be visible
            if MultiboxHelperDB.char.uiVisible then
                addon.UI.CreateMainFrame()
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save any pending data
        if addon.UI and addon.UI.frame then
            local point, _, _, x, y = addon.UI.frame:GetPoint()
            Core.SaveWindowPosition(point, x, y)
        end
    end
end)