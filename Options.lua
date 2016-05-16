-- =============================================================================
--  bRC2
--    by: BurstBiscuit
--        Xsear
-- =============================================================================

if (Options) then
    return
end

require "lib/lib_InterfaceOptions"
require "lib/lib_table"

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
    RequestCancelArc    = false,
    RequestRestartArc   = false,
    RequestTransfer     = false,
    Stuck               = false
}

-- Permission descriptions
c_PermissionDescriptions = {}

c_PermissionDescriptions.Duel = [[Allows the usage of the !duel command.

Usage: !d]]

c_PermissionDescriptions.Emote = [[Allows the usage of the !emote <emote> command.

Usage: !e dance]]

c_PermissionDescriptions.Invite = [[Allows the usage of the !invite command.

Usage: !i]]

c_PermissionDescriptions.JoinLeader = [[Allows the usage of the !jl command.

Usage: !jl]]

c_PermissionDescriptions.LeaveGroup = [[Allows the usage of the !lg command.

Usage: !lg]]

c_PermissionDescriptions.LeaveZone = [[Allows the usage of the !lz command.

Usage: !lz]]

c_PermissionDescriptions.Location = [[Allows the usage of the !loc command.

Usage: !loc]]

c_PermissionDescriptions.Promote = [[Allows the usage of the !promote command.

Usage: !p]]

c_PermissionDescriptions.ReloadUI = [[Allows the usage of the !rui command.

Usage: !rui]]

c_PermissionDescriptions.RequestCancelArc = [[Allows the usage of the !rca command.

Usage: !rca]]

c_PermissionDescriptions.RequestRestartArc = [[Allows the usage of the !rra command.

Usage: !rra]]

c_PermissionDescriptions.RequestTransfer = [[Allows the usage of the !rt command.

Usage: !rt DevilsTusk]]

c_PermissionDescriptions.Stuck = [[Allows the usage of the !stuck command.

Usage: !stuck]]


-- =============================================================================
--  Variables
-- =============================================================================

local g_GlobalPermissions = _table.copy(c_DefaultPermissions)

local g_PlayerPermissions = {}

local io_Settings   = {
    Debug           = false,
    Enabled         = false,
    ForwardInvite   = false,
    OpenOnAdd       = false,
    Permissions     = _table.copy(c_DefaultPermissions)
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

    UI_OPEN_ON_ADD = function(value)
        io_Settings.OpenOnAdd = value
    end
}

do
    InterfaceOptions.SaveVersion(1)

    InterfaceOptions.AddCheckBox({
        id      = "ADDON_ENABLED",
        label   = "Addon enabled",
        default = io_Settings.Enabled
    })

    InterfaceOptions.AddCheckBox({
        id      = "DEBUG_MODE",
        label   = "Debug mode",
        default = io_Settings.Debug
    })

    InterfaceOptions.AddCheckBox({
        id      = "GROUP_FORWARD_INVITE",
        label   = "Forward invite requests",
        default = io_Settings.ForwardInvite
    })

    InterfaceOptions.AddCheckBox({
        id      = "UI_OPEN_ON_ADD",
        label   = "Open GUI after adding",
        default = io_Settings.OpenOnAdd
    })

    InterfaceOptions.StartGroup({label = "Default permissions for new whitelist entries", subtab = {"Permissions"}})
        local permissionList = {}

        for permissionName in pairs(c_DefaultPermissions) do
            table.insert(permissionList, permissionName)
        end

        table.sort(permissionList, function(a, b)
            return unicode.lower(a) < unicode.lower(b)
        end)

        for i = 1, #permissionList do
            -- Add permission to c_OptionsMap
            c_OptionsMap["PERMISSION_" .. unicode.upper(permissionList[i])] = function(value)
                io_Settings.Permissions[permissionList[i]] = value
                Debug.Table(permissionList[i], io_Settings.Permissions[permissionList[i]])
            end

            -- Generate Interface Options entry
            InterfaceOptions.AddCheckBox({
                id      = "PERMISSION_" .. unicode.upper(permissionList[i]),
                label   = permissionList[i],
                tooltip = (c_PermissionDescriptions[permissionList[i]] or nil),
                default = c_DefaultPermissions[permissionList[i]],
                subtab  = {"Permissions"}
            })
        end
    InterfaceOptions.StopGroup({subtab = {"Permissions"}})
end


-- =============================================================================
--  Functions
-- =============================================================================

function Options.Setup()
    Debug.Log("Options.Setup()")

    -- Set the callback function for the interface options
    InterfaceOptions.SetCallbackFunc(lf.OnOptionChanged)

    -- Get the saved options
    if (Component.GetSetting("g_GlobalPermissions")) then
        g_GlobalPermissions = Component.GetSetting("g_GlobalPermissions")
    end

    if (Component.GetSetting("g_PlayerPermissions")) then
        g_PlayerPermissions = Component.GetSetting("g_PlayerPermissions")
    end
end

function Options.SaveSettings()
    Debug.Log("Options.SaveSettings()")

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

function Options.RemoveAllPlayers()
    Debug.Log("Options.RemoveAllPlayers()")

    g_PlayerPermissions = {}
    Debug.Table("g_PlayerPermissions", g_PlayerPermissions)
    Notification("Removed ALL whitelisted names")

    Options.SaveSettings()
    UI.UpdateUIState()
    UI.SelectPlayer()
end

function Options.GetGlobalPermissions()
    Debug.Log("Options.GetGlobalPermissions()")

    return g_GlobalPermissions
end

function Options.GetGlobalPermission(permissionName)
    local value = g_GlobalPermissions[permissionName] or false
    Debug.Log("Options.GetGlobalPermission()", permissionName, value)
    return value
end

function Options.SetGlobalPermission(permissionName, value)
    Debug.Table("Options.SetGlobalPermission()", {permissionName = permissionName, value = value})

    g_GlobalPermissions[permissionName] = value
    Debug.Table("g_GlobalPermissions", g_GlobalPermissions)

    Options.SaveSettings()
end

function Options.IsPlayerWhitelisted(playerName)
    local value = type(g_PlayerPermissions[ChatLib.StripArmyTag(playerName)]) == "table"
    Debug.Log("Options.IsPlayerWhitelisted()", playerName, value)
    return value
end

function Options.IsPlayerBlocked(playerName)
    local value = type(g_PlayerPermissions[ChatLib.StripArmyTag(playerName)]) == "table" and g_PlayerPermissions[ChatLib.StripArmyTag(playerName)].IsBlocked or false
    Debug.Log("Options.IsPlayerBlocked()", playerName, value)
    return value
end

function Options.SetPlayerBlocked(playerName, value)
    Debug.Table("Options.SetPlayerBlocked()", {playerName = playerName, value = value})

    if (value) then
        g_PlayerPermissions[playerName].IsBlocked = true

    else
        g_PlayerPermissions[playerName].IsBlocked = nil
    end

    Options.SaveSettings()
end

function Options.HasPermission(playerName, permissionName)
    local value = g_GlobalPermissions[permissionName] and (namecompare(playerName, Player.GetInfo()) or (Options.IsPlayerWhitelisted(playerName) and g_PlayerPermissions[ChatLib.StripArmyTag(playerName)][permissionName]))
    Debug.Table("Options.HasPermission()", {playerName = playerName, permissionName = permissionName, value = value})
    return value
end

function Options.GetPlayerPermissions(playerName)
    local values

    if (playerName) then
        if (type(g_PlayerPermissions[playerName]) == "table") then
            values = g_PlayerPermissions[playerName]

        else
            values = _table.copy(c_DefaultPermissions)
        end

    else
        values = g_PlayerPermissions
    end

    Debug.Log("Options.GetPlayerPermissions()", playerName, values)
    return values
end

function Options.GetPlayerPermission(playerName, permissionName)
    local value = g_PlayerPermissions[playerName][permissionName]
    Debug.Table("Options.GetPlayerPermission()", {playerName = playerName, permissionName = permissionName, value = value})
    return value
end

function Options.SetPlayerPermission(playerName, permissionName, value)
    Debug.Table("Options.SetPlayerPermission()", {playerName = playerName, permissionName = permissionName, value = value})
    assert(type(g_PlayerPermissions[playerName]) == "table", "There must be a permissions table for the selected player")

    g_PlayerPermissions[playerName][permissionName] = value
    Debug.Table("g_PlayerPermissions", g_PlayerPermissions[playerName])
    Options.SaveSettings()
end

function Options.IsAddonEnabled()
    return io_Settings.Enabled
end

function Options.IsInviteForwardEnabled()
    return io_Settings.ForwardInvite
end

function Options.IsOpenOnAddEnabled()
    return io_Settings.OpenOnAdd
end


-- =============================================================================
--  Local Functions
-- =============================================================================

function lf.AddOrRemoveName(playerName)
    local playerName = ChatLib.StripArmyTag(playerName)

    if (g_PlayerPermissions[playerName]) then
        g_PlayerPermissions[playerName] = nil

        Notification("Removed " .. tostring(ChatLib.EncodePlayerLink(playerName)) .. " from whitelist")

        -- UI needs to be updated since we've removed a player
        UI.UpdateUIState()

        if (namecompare(playerName, UI.GetSelectedPlayer())) then
            UI.SelectPlayer()
        end

    else
        Debug.Table("io_Settings.Permissions", io_Settings.Permissions)
        g_PlayerPermissions[playerName] = _table.copy(io_Settings.Permissions)

        Notification("Added " .. tostring(ChatLib.EncodePlayerLink(playerName)) .. " to whitelist")

        -- UI needs to be updated since we've added a player
        UI.UpdateUIState()
        UI.SelectPlayer(playerName)
    end

    Debug.Table(playerName, g_PlayerPermissions[playerName])
    Options.SaveSettings()
end

function lf.OnOptionChanged(id, value)
    if (c_OptionsMap[id]) then
        c_OptionsMap[id](value)

    else
        Debug.Warn("Unhandled message:", id)
    end
end
