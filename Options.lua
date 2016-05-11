-- =============================================================================
--  bRC2
--    by: BurstBiscuit
--        Xsear
-- =============================================================================

if (Options) then
    return
end

require "lib/lib_InterfaceOptions"

local lf = {}


-- =============================================================================
--  Globals
-- =============================================================================

Options = {}

-- =============================================================================
--  Constants
-- =============================================================================

c_DefaultPermissions = {
    Duel                = false,
    Emote               = false,
    Invite              = false,
    JoinLeader          = false,
    LeaveGroup          = false,
    LeaveZone           = false,
    Location            = false,
    Promote             = false,
    ReloadUI            = false,
    RequestCancelArc    = false
}


-- =============================================================================
--  Variables
-- =============================================================================

local g_BlockedPlayers = {}

local g_GlobalPermissions = c_DefaultPermissions

local g_PlayerPermissions = {}

local io_Settings   = {
    Debug           = false,
    Enabled         = false,
    ForwardInvite   = false,
    Permissions     = c_DefaultPermissions
}

local c_OptionsMap = {
    DEBUG_MODE = function(value)
        Debug.EnableLogging(value)
    end,

    ADDON_ENABLED = function(value)
        io_Settings.Enabled = value
    end,

    GROUP_FORWARD_INVITE = function(value)
        io_Settings.ForwardInvite = value
    end,

    PERMISSION_DUEL = function(value)
        io_Settings.Permissions.Duel = value
    end,

    PERMISSION_EMOTE = function(value)
        io_Settings.Permissions.Emote = value
    end,

    PERMISSION_INVITE = function(value)
        io_Settings.Permissions.Invite = value
    end,

    PERMISSION_JOINLEADER = function(value)
        io_Settings.Permissions.JoinLeader = value
    end,

    PERMISSION_LEAVEGROUP = function(value)
        io_Settings.Permissions.LeaveGroup = value
    end,

    PERMISSION_LEAVEZONE = function(value)
        io_Settings.Permissions.LeaveZone = value
    end,

    PERMISSION_LOCATION = function(value)
        io_Settings.Permissions.Location = value
    end,

    PERMISSION_PROMOTE = function(value)
        io_Settings.Permissions.Promote = value
    end,

    PERMISSION_RELOADUI = function(value)
        io_Settings.Permissions.ReloadUI = value
    end,

    PERMISSION_REQUESTCANCELARC = function(value)
        io_Settings.Permissions.RequestCancelArc = value
    end
}

do
    InterfaceOptions.SaveVersion(1)

    InterfaceOptions.AddCheckBox({id = "ADDON_ENABLED", label = "Addon enabled", default = io_Settings.Enabled})

    InterfaceOptions.StartGroup({label = "Miscellanous"})
        InterfaceOptions.AddCheckBox({id = "DEBUG_MODE",            label = "Debug mode",               default = io_Settings.Debug})
        InterfaceOptions.AddCheckBox({id = "GROUP_FORWARD_INVITE",  label = "Forward invite requests",  default = io_Settings.ForwardInvite})
    InterfaceOptions.StopGroup()

    InterfaceOptions.StartGroup({label = "Default permissions for new entries"})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_DUEL",               label = "Duel",             default = io_Settings.Permissions.Duel})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_EMOTE",              label = "Emote",            default = io_Settings.Permissions.Emote})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_INVITE",             label = "Invite",           default = io_Settings.Permissions.Invite})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_JOINLEADER",         label = "JoinLeader",       default = io_Settings.Permissions.JoinLeader})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_LEAVEGROUP",         label = "LeaveGroup",       default = io_Settings.Permissions.LeaveGroup})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_LEAVEZONE",          label = "LeaveZone",        default = io_Settings.Permissions.LeaveZone})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_LOCATION",           label = "Location",         default = io_Settings.Permissions.Location})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_PROMOTE",            label = "Promote",          default = io_Settings.Permissions.Promote})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_RELOADUI",           label = "ReloadUI",         default = io_Settings.Permissions.ReloadUI})
        InterfaceOptions.AddCheckBox({id = "PERMISSION_REQUESTCANCELARC",   label = "RequestCancelArc", default = io_Settings.Permissions.RequestCancelArc})
    InterfaceOptions.StopGroup()
end


-- =============================================================================
--  Functions
-- =============================================================================

function Options.Setup()
    -- Set the callback function for the interface options
    InterfaceOptions.SetCallbackFunc(lf.OnOptionChanged)

    -- Get the saved options
    if (Component.GetSetting("g_BlockedPlayers")) then
        g_GlobalPermissions = Component.GetSetting("g_BlockedPlayers")
    end

    if (Component.GetSetting("g_GlobalPermissions")) then
        g_GlobalPermissions = Component.GetSetting("g_GlobalPermissions")
    end

    if (Component.GetSetting("g_PlayerPermissions")) then
        g_PlayerPermissions = Component.GetSetting("g_PlayerPermissions")
    end
end

function Options.IsAddonEnabled()
    return io_Settings.Enabled
end

function Options.SaveSettings()
    Component.SaveSetting("g_BlockedPlayers", g_BlockedPlayers)
    Component.SaveSetting("g_GlobalPermissions", g_GlobalPermissions)
    Component.SaveSetting("g_PlayerPermissions", g_PlayerPermissions)
end

function Options.AddOrRemoveName(args)
    Debug.Table("Options.AddOrRemoveName()", args)

    if (namecompare(args, Player.GetInfo())) then
        Notification("You can't add yourself to the whitelist")
    else
        lf.AddOrRemoveName(args)
    end
end

function Options.HasPermission(playerName, permissionName)
    Debug.Table("Options.HasPermission()", {playerName = playerName, permissionName = permissionName})
    return g_GlobalPermissions[permissionName] and (namecompare(playerName, Player.GetInfo()) or (Options.IsPlayerWhitelisted(playerName) and g_PlayerPermissions[ChatLib.StripArmyTag(playerName)][permissionName]))
end

function Options.IsPlayerWhitelisted(playerName)
    return type(g_PlayerPermissions[ChatLib.StripArmyTag(playerName)]) == "table"
end

function Options.GetGlobalPermissions()
    return g_GlobalPermissions
end

function Options.GetGlobalPermission(permissionName)
    return g_GlobalPermissions[permissionName]
end

function Options.SetGlobalPermission(permissionName, value)
    Debug.Table("Options.SetGlobalPermission()", {permissionName = permissionName, value = value})
    g_GlobalPermissions[permissionName] = value
    Debug.Table("g_GlobalPermissions", g_GlobalPermissions)
    Options.SaveSettings()
end

function Options.GetPlayerPermissions()
    return g_PlayerPermissions
end

function Options.GetPlayerPermission(playerName, permissionName)
    return g_PlayerPermissions[playerName][permissionName]
end

function Options.SetPlayerPermission(playerName, permissionName, value)
    Debug.Table("Options.SetPlayerPermission()", {playerName = playerName, permissionName = permissionName, value = value})
    assert(type(g_PlayerPermissions[playerName]) == "table", "There must be a permissions table for the selected player")

    g_PlayerPermissions[playerName][permissionName] = value
    Debug.Table("g_PlayerPermissions", g_PlayerPermissions[playerName])
    Options.SaveSettings()
end

function Options.IsPlayerBlocked(playerName)
    return g_BlockedPlayers[ChatLib.StripArmyTag(playerName)] or false
end

function Options.SetPlayerBlocked(playerName, value)
    if (value) then
        g_BlockedPlayers[playerName] = true
    else
        g_BlockedPlayers[playerName] = nil
    end

    Options.SaveSettings()
end

function Options.IsInviteForwardEnabled()
    return io_Settings.ForwardInvite
end


-- =============================================================================
--  Local Functions
-- =============================================================================

function lf.AddOrRemoveName(playerName)
    local playerName = ChatLib.StripArmyTag(playerName)

    if (g_PlayerPermissions[playerName]) then
        g_PlayerPermissions[playerName] = nil

        if (namecompare(playerName, UI.GetSelectedPlayer())) then
            UI.SelectPlayer()
        end

        Notification("Removed " .. tostring(ChatLib.EncodePlayerLink(playerName)) .. " from whitelist")
    else
        g_PlayerPermissions[playerName] = {
            Duel        = io_Settings.Permissions.Duel,
            Emote       = io_Settings.Permissions.Emote,
            Invite      = io_Settings.Permissions.Invite,
            JoinLeader  = io_Settings.Permissions.JoinLeader,
            LeaveZone   = io_Settings.Permissions.LeaveZone,
            Location    = io_Settings.Permissions.Location,
            Promote     = io_Settings.Permissions.Promote
        }

        Notification("Added " .. tostring(ChatLib.EncodePlayerLink(playerName)) .. " to whitelist")
    end

    Debug.Table("g_PlayerPermissions", g_PlayerPermissions)
    Options.SaveSettings()

    -- UI needs to be updated since we've added/removed a player
    UI.UpdateUIState()
end

function lf.OnOptionChanged(id, value)
    if (c_OptionsMap[id]) then
        c_OptionsMap[id](value)
    else
        Debug.Warn("Unhandled message:", id)
    end
end
