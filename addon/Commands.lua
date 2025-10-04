-- MultiboxHelper Slash Commands Module
-- Handles all slash command functionality

local addonName, addon = ...

local Commands = {}
addon.Commands = Commands

-- Slash command handler
local function SlashCommandHandler(msg)
    local command = string.lower(string.trim(msg or ""))
    
    if command == "" or command == "toggle" then
        -- Toggle UI visibility
        addon.UI.ToggleFrame()
        if addon.UI.frame and addon.UI.frame:IsVisible() then
            print("|cff00ff00MultiboxHelper:|r UI shown")
        else
            print("|cff00ff00MultiboxHelper:|r UI hidden")
        end
        
    elseif command == "show" then
        -- Show UI
        addon.UI.ShowFrame()
        print("|cff00ff00MultiboxHelper:|r UI shown")
        
    elseif command == "hide" then
        -- Hide UI
        addon.UI.HideFrame()
        print("|cff00ff00MultiboxHelper:|r UI hidden")
        
    elseif command == "config" or command == "options" then
        -- Open options panel
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("MultiboxHelper")
            InterfaceOptionsFrame_OpenToCategory("MultiboxHelper") -- Call twice for proper focus
        elseif Settings and Settings.OpenToCategory then
            Settings.OpenToCategory("MultiboxHelper")
        else
            print("|cffff0000MultiboxHelper:|r Unable to open options panel.")
        end
        
    elseif command == "debug" then
        -- Debug information
        Commands.ShowDebugInfo()
        
    elseif command == "refresh" then
        -- Manually refresh options panel
        if addon.Options then
            print("|cff00ff00MultiboxHelper:|r Refreshing options panel...")
            addon.Options.RefreshTeamPanels()
        else
            print("|cffff0000MultiboxHelper:|r Options module not loaded")
        end
        
    elseif command == "resetpos" or command == "resetposition" then
        -- Reset UI position to center
        if addon.Core then
            addon.Core.SaveWindowPosition("CENTER", 0, 0)
            if addon.UI.frame then
                addon.UI.frame:ClearAllPoints()
                addon.UI.frame:SetPoint("CENTER", 0, 0)
            end
            print("|cff00ff00MultiboxHelper:|r UI position reset to center")
        else
            print("|cffff0000MultiboxHelper:|r Core module not loaded")
        end
        
    elseif command == "pos" or command == "position" then
        -- Show current UI position information
        Commands.ShowPositionInfo()
        
    elseif command == "help" then
        -- Show help
        Commands.ShowHelp()
        
    else
        print("|cffff0000MultiboxHelper:|r Unknown command. Type '/mbh help' for available commands.")
    end
end

-- Show current UI position information
function Commands.ShowPositionInfo()
    print("|cff00ff00MultiboxHelper Position Info:|r")
    
    -- Show saved position from database
    if MultiboxHelperDB and MultiboxHelperDB.char and MultiboxHelperDB.char.windowPosition then
        local savedPos = MultiboxHelperDB.char.windowPosition
        print("  |cff00ff00Saved Position:|r " .. (savedPos.point or "nil") .. " (" .. (savedPos.x or 0) .. ", " .. (savedPos.y or 0) .. ")")
    else
        print("  |cffff0000Saved Position:|r not found in database")
    end
    
    -- Show current UI frame position
    if addon.UI and addon.UI.frame then
        local frame = addon.UI.frame
        if frame:IsVisible() then
            local point, relativeTo, relativePoint, x, y = frame:GetPoint()
            print("  |cff00ff00Current Position:|r " .. (point or "nil") .. " (" .. (x or 0) .. ", " .. (y or 0) .. ")")
            print("  |cff00ff00Frame Size:|r " .. frame:GetWidth() .. "x" .. frame:GetHeight())
            print("  |cff00ff00Frame Visible:|r true")
        else
            print("  |cffff0000Current Position:|r UI frame is hidden")
        end
    else
        print("  |cffff0000Current Position:|r UI frame not created")
    end
    
    -- Show screen dimensions for reference
    print("  |cff00ff00Screen Size:|r " .. GetScreenWidth() .. "x" .. GetScreenHeight())
end

-- Show debug information
function Commands.ShowDebugInfo()
    print("|cff00ff00MultiboxHelper Debug Info:|r")
    
    if not MultiboxHelperDB then
        print("  |cffff0000MultiboxHelperDB:|r nil")
        return
    end
    
    print("  |cff00ff00MultiboxHelperDB:|r exists")
    
    if MultiboxHelperDB.char then
        print("  |cff00ff00char.uiVisible:|r " .. tostring(MultiboxHelperDB.char.uiVisible))
    else
        print("  |cffff0000char:|r nil")
    end
    
    if MultiboxHelperDB.profile then
        if MultiboxHelperDB.profile.teams then
            local teamCount = 0
            for teamName, members in pairs(MultiboxHelperDB.profile.teams) do
                teamCount = teamCount + 1
                print("  |cff00ff00Team:|r " .. teamName .. " (" .. #members .. " members)")
            end
            print("  |cff00ff00Total teams:|r " .. teamCount)
        else
            print("  |cffff0000profile.teams:|r nil")
        end
    else
        print("  |cffff0000profile:|r nil")
    end
end

-- Show help information
function Commands.ShowHelp()
    print("|cff00ff00MultiboxHelper Commands:|r")
    print("  |cffff0000/mbh|r or |cffff0000/mbh toggle|r - Toggle UI visibility")
    print("  |cffff0000/mbh show|r - Show the UI")
    print("  |cffff0000/mbh hide|r - Hide the UI")
    print("  |cffff0000/mbh config|r or |cffff0000/mbh options|r - Open configuration panel")
    print("  |cffff0000/mbh debug|r - Show debug information")
    print("  |cffff0000/mbh refresh|r - Manually refresh options panel")
    print("  |cffff0000/mbh pos|r - Show current UI position coordinates")
    print("  |cffff0000/mbh resetpos|r - Reset UI position to center")
    print("  |cffff0000/mbh help|r - Show this help message")
end

-- Register slash commands
function Commands.Initialize()
    SLASH_MULTIBOXHELPER1 = "/mbh"
    SLASH_MULTIBOXHELPER2 = "/multiboxhelper"
    SlashCmdList["MULTIBOXHELPER"] = SlashCommandHandler
    
    print("|cff00ff00MultiboxHelper|r loaded. Type |cffff0000/mbh|r to toggle UI or |cffff0000/mbh help|r for commands.")
end

-- Initialize when addon loads
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        Commands.Initialize()
    end
end)