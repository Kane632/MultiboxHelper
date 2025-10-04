-- MultiboxHelper Initialization
-- This file ensures proper addon namespace setup

local addonName, addon = ...

-- Addon metadata
addon.version = "2.0"
addon.author = "Kane632"

-- Debug function for development
function addon.Debug(...)
    if addon.debugMode then
        print("|cff00ff00[MBH Debug]:|r", ...)
    end
end

-- Global addon reference (optional, for other addons to interact)
_G[addonName] = addon