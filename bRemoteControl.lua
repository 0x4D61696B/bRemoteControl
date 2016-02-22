-- =============================================================================
--  bRemoteControl
--    by: BurstBiscuit
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

require "./Emotes"
-- require "./Options"

Debug.EnableLogging(false)


-- =============================================================================
--  Variables
-- =============================================================================

local c_HelpText = "/brc <-clear|-list|player_name>" ..
        "\n\t-clear - Clears all currently whitelisted player names" ..
        "\n\t-list - Lists all currently whitelisted player names" ..
        "\n\tplayer_name - Adds or removes the specified player name to/from the whitelist"
local g_GroupInfo = false
local g_ZoningInitiator = false
local g_Names = {}
local g_Options = {
    addonEnabled = false,
    emotesEnabled = false,
    joinleaderEnabled = false,
    inviteEnabled = false,
    leavezoneEnabled = false,
    locationEnabled = false,
    promoteEnabled = false
}


-- =============================================================================
--  Interface Options
-- =============================================================================

function OnOptionChanged(id, value)
    if (id == "DEBUG_CHECKBOX") then
        Debug.EnableLogging(value)
    elseif (id == "ADDON_CHECKBOX") then
        g_Options.addonEnabled = value
    elseif (id == "EMOTES_CHECKBOX") then
        g_Options.emotesEnabled = value
    elseif (id == "JOINLEADER_CHECKBOX") then
        g_Options.joinleaderEnabled = value
    elseif (id == "INVITE_CHECKBOX") then
        g_Options.inviteEnabled = value
    elseif (id == "LEAVEZONE_CHECKBOX") then
        g_Options.leavezoneEnabled = value
    elseif (id == "LOCATION_CHECKBOX") then
        g_Options.locationEnabled = value
    elseif (id == "PROMOTE_CHECKBOX") then
        g_Options.promoteEnabled = value
    end
end

do
    InterfaceOptions.SaveVersion(1)
    
    InterfaceOptions.AddCheckBox({id = "DEBUG_CHECKBOX", label = "Enable debug mode", default = false})
    InterfaceOptions.StartGroup({id = "ADDON_CHECKBOX", label = "Enable addon", checkbox = true, default = false})
        InterfaceOptions.AddCheckBox({id = "EMOTES_CHECKBOX", label = "Enable !<emote> requests", default = false})
        InterfaceOptions.AddCheckBox({id = "INVITE_CHECKBOX", label = "Enable !invite requests", default = false})
        InterfaceOptions.AddCheckBox({id = "JOINLEADER_CHECKBOX", label = "Enable !joinleader requests", default = false})
        InterfaceOptions.AddCheckBox({id = "LEAVEZONE_CHECKBOX", label = "Enable !leavezone requests", default = false})
        InterfaceOptions.AddCheckBox({id = "LOCATION_CHECKBOX", label = "Enable !loc requests", default = false})
        InterfaceOptions.AddCheckBox({id = "PROMOTE_CHECKBOX", label = "Enable !promote requests", default = false})
    InterfaceOptions.StopGroup()
end


-- =============================================================================
--  Functions
-- =============================================================================

function Notification(message)
    ChatLib.Notification({text = "[bRemoteControl] " .. tostring(message)})
end

function AddRemovePlayerName(name)
    Debug.Log("AddRemovePlayerName()", name)
    local playerName = ChatLib.StripArmyTag(name)
    
    if (g_Names[playerName]) then
        Notification("Removing " .. ChatLib.EncodePlayerLink(playerName) .. " from the whitelist")
        g_Names[playerName] = nil
    elseif (namecompare(Player.GetInfo(), playerName)) then
        Notification("You cannot add yourself to the whitelist")
    else
        Notification("Adding " .. ChatLib.EncodePlayerLink(playerName) .. " to whitelist")
        g_Names[playerName] = true
    end
    
    Component.SaveSetting("PLAYER_NAMES", g_Names)
end

function ClearPlayerNames()
    Notification("Clearing the whitelist")
    g_Names = {}
    Component.SaveSetting("PLAYER_NAMES", g_Names)
end

function ListPlayerNames()
    local count = 0
    local names = ""
    
    for k, _ in pairs(g_Names) do
        names = names .. " " .. ChatLib.EncodePlayerLink(k)
        count = count + 1
    end
    
    if (count > 0) then
        local s = function() if (count > 1) then return "s" else return "" end end
        
        Notification("Currently whitelisted " .. count .. " name" .. s() .. ":" .. names)
    else
        Notification("There are no names on the whitelist.")
    end
end

function OnPlayerMenuShow(playerName, reason)
    if (not namecompare(Player.GetInfo(), playerName)) then
        local MENU = PlayerMenu:AddMenu({label = "bRemoteControl", menu = "bRemoteControl_menu"})
        local toggleLabel = function(pName) if (g_Names[pName]) then return "Remove from" else return "Add to" end end
        
        MENU:AddButton({label = toggleLabel(playerName) .. " whitelist", id = "bRemoteControl_toggle"}, function()
            AddRemovePlayerName(playerName)
        end)
    end
end

function OnSlashCommand(args)
    if (args[1]) then
        if (args[1] == "-clear") then
            ClearPlayerNames()
        elseif (args[1] == "-list") then
            ListPlayerNames()
        elseif (args[1] == "-zreset") then
            g_ZoningInitiator = false
        elseif (unicode.len(args[1]) > 0) then
            AddRemovePlayerName(args[1])
        end
    else
        Notification(c_HelpText)
    end
end


-- =============================================================================
--  Events
-- =============================================================================

function OnComponentLoad()
    LIB_SLASH.BindCallback({
        slash_list = "bremotecontrol, brc",
        description = "bRemoteControl",
        func = OnSlashCommand,
        autocomplete_name = 1
    })
    
    InterfaceOptions.SetCallbackFunc(OnOptionChanged)
    PlayerMenu.BindOnShow(OnPlayerMenuShow)
    
    if (Component.GetSetting("PLAYER_NAMES")) then
        g_Names = Component.GetSetting("PLAYER_NAMES")
    end
end

function OnChatMessage(args)
    if (not g_Options.addonEnabled) then
        return
    elseif (not args or not args.channel or not args.author or not args.text) then
        Debug.Log("Some args missing, return")
        return
    end
    
    if (g_Names[ChatLib.StripArmyTag(args.author)] or namecompare(Player.GetInfo(), args.author)) then
        if (g_Options.joinleaderEnabled and unicode.match(args.text, "^!joinleader")) then
            if (g_GroupInfo and g_GroupInfo.leader and namecompare(args.author, g_GroupInfo.leader)) then
                if (g_ZoningInitiator) then
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Unable to join leader instance: Zoning was already requested by " .. ChatLib.EncodePlayerLink(g_ZoningInitiator))
                elseif (Squad.IsLeaderOnSameInstance() or Platoon.IsLeaderOnSameInstance()) then
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Already in the same instance")
                elseif (Platoon.IsInSquad() and Platoon.IsLeaderOnSameZone()) then
                    Notification("Joining leader instance, requested by " .. ChatLib.EncodePlayerLink(args.author))
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Joining leader instance, this will take a moment")
                    g_ZoningInitiator = args.author
                    Platoon.JoinLeader()
                elseif (Squad.IsInSquad() and Squad.IsLeaderOnSameZone()) then
                    Notification("Joining leader instance, requested by " .. ChatLib.EncodePlayerLink(args.author))
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Joining leader instance, this will take a moment")
                    g_ZoningInitiator = args.author
                    Squad.JoinLeader()
                else
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Unable to join leader instance (same zone?)")
                end
            end
        elseif (g_Options.inviteEnabled and args.channel == "whisper" and unicode.match(args.text, "^!invite")) then
            if (g_GroupInfo and g_GroupInfo.roster and g_GroupInfo.roster.is_mine) then
                if (Platoon.IsInPlatoon() and #g_GroupInfo.roster.members < Platoon.GetMaxPlatoonSize()) then
                    Platoon.Invite(args.author)
                elseif (Squad.IsInSquad() and #g_GroupInfo.roster.members < Squad.GetMaxSquadSize()) then
                    Squad.Invite(args.author)
                else
                    SendWhisperText(args.author, "[bRemoteControl] Unable to invite: Group is full")
                end
            elseif (g_GroupInfo and g_GroupInfo.leader) then
                Chat.SendWhisperText(args.author, "[bRemoteControl] Unable to invite: Not leader of the group. The leader is: " .. ChatLib.EncodePlayerLink(g_GroupInfo.leader))
            else
                Squad.Invite(args.author)
            end
        elseif (g_Options.leavezoneEnabled and unicode.match(args.text, "^!leavezone")) then
            if (g_GroupInfo and g_GroupInfo.leader and namecompare(args.author, g_GroupInfo.leader)) then
                if (g_ZoningInitiator) then
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Unable to leave zone: Zoning was already requested by " .. ChatLib.EncodePlayerLink(g_ZoningInitiator))
                else
                    Notification("Leaving zone, requested by " .. ChatLib.EncodePlayerLink(args.author))
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Leaving zone, this will take a moment")
                    g_ZoningInitiator = args.author
                    Game.ReturnToPvE()
                end
            elseif (namecompare(args.author, Player.GetInfo())) then
                if (g_ZoningInitiator) then
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Unable to leave zone: Zoning was already requested by " .. ChatLib.EncodePlayerLink(g_ZoningInitiator))
                else
                    Notification("Leaving zone, requested by " .. ChatLib.EncodePlayerLink(args.author))
                    Chat.SendWhisperText(args.author, "[bRemoteControl] Leaving zone, this will take a moment")
                    g_ZoningInitiator = args.author
                    Game.ReturnToPvE()
                end
            end
        elseif (g_Options.locationEnabled and args.channel == "whisper" and unicode.match(args.text, "^!loc")) then
            Chat.SendWhisperText(args.author, "[bRemoteControl] " .. ChatLib.EncodeCoordLink())
        elseif (g_Options.promoteEnabled and unicode.match(args.text, "^!promote")) then
            Debug.Log(g_GroupInfo, args.author)
            
            if (g_GroupInfo and g_GroupInfo.roster and g_GroupInfo.roster.members and g_GroupInfo.roster.is_mine) then
                for _, member in pairs(g_GroupInfo.roster.members) do
                    Debug.Log(member)
                    
                    if (namecompare(args.author, member.name)) then
                        if (Platoon.IsInPlatoon()) then
                            Platoon.Promote(args.author)
                        elseif (Squad.IsInSquad()) then
                            Squad.Promote(args.author)
                        end
                        
                        break
                    end
                end
            end
        elseif (g_Options.emotesEnabled) then
            local emote = unicode.match(args.text, "^!(%w+)") or false
            
            if (emote and c_Emotes[emote]) then
                Game.SlashCommand(emote)
            end
        end
    end
end

function OnSquadRosterUpdate(args)
    if (Platoon.IsInPlatoon()) then
        g_GroupInfo = {}
        g_GroupInfo.leader = Platoon.GetLeader()
        g_GroupInfo.roster = Platoon.GetRoster()
    elseif (Squad.IsInSquad()) then
        g_GroupInfo = {}
        g_GroupInfo.leader = Squad.GetLeader()
        g_GroupInfo.roster = Squad.GetRoster()
    else
        g_GroupInfo = false
    end
end

function OnStreamProgress()
    local pct, completed, total, is_streaming = Game.GetLoadingProgress()
    Debug.Log("GetLoadingProgress()", pct, completed, total, is_streaming)
    
    if (g_ZoningInitiator and pct >= 1 and not is_streaming) then
        Chat.SendWhisperText(g_ZoningInitiator, "[bRemoteControl] Zoning was successful")
        g_ZoningInitiator = false
    end
end
