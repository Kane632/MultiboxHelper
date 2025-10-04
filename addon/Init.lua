-- MultiboxHelper Initialization
-- This file ensures proper addon namespace setup

local addonName, addon = ...

-- Addon metadata
addon.version = "2.0"
addon.author = "Kane632"

-- Centralized debug functions
function addon.DebugPrint(...)
    if MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.enabled then
        print("|cff00ff00[MBH Debug]:|r", ...)
    end
end

function addon.OptionsDebugPrint(...)
    if MultiboxHelperDB and MultiboxHelperDB.profile and MultiboxHelperDB.profile.debug and MultiboxHelperDB.profile.debug.enabled then
        print("|cff88ff88[MBH Options]:|r", ...)
    end
end

-- Legacy debug function for backward compatibility
function addon.Debug(...)
    addon.DebugPrint(...)
end

-- Global addon reference (optional, for other addons to interact)
_G[addonName] = addon