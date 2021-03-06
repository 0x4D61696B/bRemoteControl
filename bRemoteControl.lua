-- =============================================================================
--  bRC2
--    by: BurstBiscuit
--        Xsear
-- =============================================================================

require "math"
require "table"
require "unicode"

require "lib/lib_Callback2"
require "lib/lib_ChatLib"
require "lib/lib_Debug"
require "lib/lib_InterfaceOptions"
require "lib/lib_PlayerContextualMenu"
require "lib/lib_Slash"

require "./Commands"
require "./Options"
require "./UI"

Debug.EnableLogging(false)


-- =============================================================================
--  Constants
-- =============================================================================

local c_SlashList = "brc2"


-- =============================================================================
--  Functions
-- =============================================================================

function Notification(message)
    ChatLib.Notification({text = "[bRC2] " .. tostring(message)})
end

function OnClose(args)
    Debug.Event(args)
    UI.Close()
end

function OnOpen(args)
    Debug.Event(args)
    UI.Open()
end

function OnPlayerMenuShow(playerName)
    -- Don't add the menu for the local player
    if (not namecompare(playerName, Player.GetInfo())) then
        local playerName = ChatLib.StripArmyTag(playerName)
        local MENU = PlayerMenu:AddMenu({label = "bRC2", menu = "bRC2_Menu"})

        MENU:AddButton({label = (Options.IsPlayerWhitelisted(playerName) and "Remove from " or "Add to ") .. " whitelist", id = "bRC2_Toggle"}, function()
            Options.AddOrRemoveName(playerName)
        end)
    end
end

function OnSlashCommand(args)
    if (args[1] and unicode.len(args[1]) > 0) then
        Options.AddOrRemoveName(args[1])

    else
        OnOpen()
    end
end


-- =============================================================================
--  Events
-- =============================================================================

function OnComponentLoad()
    -- Register the slash command
    LIB_SLASH.BindCallback({
        slash_list          = c_SlashList,
        description         = "bRC2",
        func                = OnSlashCommand,
        autocomplete_name   = 1
    })

    -- Add a menu to the player menu (right click on characters/names)
    PlayerMenu.BindOnShow(OnPlayerMenuShow)

    -- Register the custom chat link
    ChatLib.RegisterCustomLinkType("bRC2", Commands.OnChatLink)

    -- Setup the Options
    Options.Setup()

    -- Setup the UI
    UI.Setup()
end

function OnComponentUnload()
    -- Unregister the slash command
    LIB_SLASH.UnbindCallback(c_SlashList)
end

function OnChatMessage(args)
    Commands.OnChatMessage(args)
end

function OnDuelUpdated(args)
    Commands.OnDuelUpdated(args)
end

function OnLoadingComplete(args)
    Commands.OnLoadingComplete(args)
end

function OnPlayerReady(args)
    Commands.OnPlayerReady(args)
end

function OnPreReloadUI(args)
    Commands.OnPreReloadUI(args)
end

function OnSquadInviteReceived(args)
    Commands.OnSquadInviteReceived(args)
end

function OnSquadRosterUpdate(args)
    Commands.OnSquadRosterUpdate(args)
end

function MyHudNote(args)
    Commands.MyHudNote(args)
end
