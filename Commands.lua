-- =============================================================================
--  bRC2
--    by: BurstBiscuit
--        Xsear
-- =============================================================================

if (Commands) then
    return
end

require "./Emotes"

local lf = {}


-- =============================================================================
--  Globals
-- =============================================================================

Commands = {}


-- =============================================================================
--  Variables
-- =============================================================================

local g_DuelInfo    = false
local g_GroupInfo   = false
local g_ZoningInfo  = false


-- =============================================================================
--  Functions
-- =============================================================================

function Commands.OnChatMessage(args)
    lf.OnChatMessage(args)
end

function Commands.OnDuelUpdated(args)
    lf.OnDuelUpdated(args)
end

function Commands.OnLoadingComplete(args)
    lf.OnLoadingComplete(args)
end

function Commands.OnPlayerReady(args)
    lf.OnPlayerReady(args)
end

function Commands.OnSquadRosterUpdate(args)
    lf.OnSquadRosterUpdate(args)
end


-- =============================================================================
--  Local Functions
-- =============================================================================

function lf.OnChatMessage(args)
    if (not Options.IsAddonEnabled()) then
        return

    elseif (not args or not args.channel or not args.author or not args.text) then
        Debug.Warn("OnChatMessage() - Missing data:", args)

    elseif ((namecompare(args.author, Player.GetInfo()) or Options.IsPlayerWhitelisted(args.author) and not Options.IsPlayerBlocked(args.author)) and unicode.match(args.text, "^!%w+")) then
        Debug.Event(args)
        local text = unicode.lower(args.text)

        -- Duel requests
        if (unicode.match(text, "^!d") and not namecompare(args.author, Player.GetInfo()) and Options.HasPermission(args.author, "Duel")) then
            Debug.Log("Duel requested:", args.author)

            if (g_DuelInfo) then
                Chat.SendWhisperText(args.author, "[bRC2] Unable to request duel: already duelling")

            else
                Notification("Duel requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                Game.RequestDuel(args.author)
            end

        -- Emote requests
        elseif (unicode.match(text, "^!e%w*%s+%w+") and Options.HasPermission(args.author, "Emote")) then
            Debug.Log("Emote requested:", args.author)

            local requestedEmote = unicode.match(text, "^!e%w*%s+(%w+)")

            if (c_Emotes[requestedEmote]) then
                Game.SlashCommand(requestedEmote)
            end

        -- Invite requests
        elseif (unicode.match(text, "^!i") and not namecompare(args.author, Player.GetInfo()) and Options.HasPermission(args.author, "Invite")) then
            Debug.Log("Invite requested:", args.author)

            if (g_GroupInfo and g_GroupInfo.is_mine) then
                if (Platoon.IsInPlatoon() and #g_GroupInfo.members < Platoon.GetMaxPlatoonSize()) then
                    if (Platoon.Invite(args.author)) then
                        Notification("Platoon invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                    end

                elseif (Squad.IsInSquad() and #g_GroupInfo.members == Squad.GetMaxSquadSize()) then
                    if (Platoon.Invite(args.author)) then
                        Notification("Platoon invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                    end

                elseif (Squad.IsInSquad() and #g_GroupInfo.members < Squad.GetMaxSquadSize()) then
                    if (Squad.Invite(args.author)) then
                        Notification("Squad invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                    end

                else
                    Chat.SendWhisperText(args.author, "[bRC2] Unable to invite: Group is full")
                end

            elseif (g_GroupInfo and Options.IsInviteForwardEnabled()) then
                if (Platoon.IsInPlatoon() and #g_GroupInfo.members < Platoon.GetMaxPlatoonSize()) then
                    if (Platoon.Invite(args.author)) then
                        Notification("Platoon invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                        Chat.SendWhisperText(g_GroupInfo.leader, "[bRC2] Automatically forwarded invite request by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                        Chat.SendWhisperText(args.author, "[bRC2] Invite request has been forwarded to " .. tostring(ChatLib.EncodePlayerLink(g_GroupInfo.leader)))
                    end

                -- TODO: Add option for "convert to platoon"
                elseif (Squad.IsInSquad() and #g_GroupInfo.members == Squad.GetMaxSquadSize()) then
                    if (Platoon.Invite(args.author)) then
                        Notification("Platoon invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                        Chat.SendWhisperText(g_GroupInfo.leader, "[bRC2] Automatically forwarded invite request by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                        Chat.SendWhisperText(args.author, "[bRC2] Invite request has been forwarded to " .. tostring(ChatLib.EncodePlayerLink(g_GroupInfo.leader)))
                    end

                elseif (Squad.IsInSquad() and #g_GroupInfo.members < Squad.GetMaxSquadSize()) then
                    if (Squad.Invite(args.author)) then
                        Notification("Squad invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                        Chat.SendWhisperText(g_GroupInfo.leader, "[bRC2] Automatically forwarded invite request by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                        Chat.SendWhisperText(args.author, "[bRC2] Invite request has been forwarded to " .. tostring(ChatLib.EncodePlayerLink(g_GroupInfo.leader)))
                    end

                else
                    Chat.SendWhisperText(args.author, "[bRC2] Unable to invite: Group is full")
                end

            elseif (g_GroupInfo) then
                Chat.SendWhisperText(args.author, "[bRC2] Unable to invite: Not leader of the group and invite forwarding is disabled. The leader of the group is: " .. tostring(ChatLib.EncodePlayerLink(g_GroupInfo.leader)))

            else
                if (Squad.Invite(args.author)) then
                    Notification("Squad invite sent to " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                end
            end

        -- JoinLeader requests
        elseif (unicode.match(text, "^!jl") and Options.HasPermission(args.author, "JoinLeader")) then
            Debug.Log("JoinLeader requested:", args.author)

            if (g_GroupInfo and (namecompare(args.author, g_GroupInfo.leader) or namecompare(args.author, Player.GetInfo()))) then
                if (g_ZoningInfo) then
                    Chat.SendWhisperText(args.author, "[bRC2] Unable to join leader instance: zoning was already requested by " .. tostring(ChatLib.EncodePlayerLink(g_ZoningInfo)))

                else
                    local isJoinLeaderInvalid = Squad.IsJoinLeaderInvalid()

                    if (isJoinLeaderInvalid) then
                        Chat.SendWhisperText(args.author, "[bRC2] Unable to join leader instance: " .. tostring(isJoinLeaderInvalid))

                    else
                        g_ZoningInfo = tostring(args.author)

                        Squad.JoinLeader()
                        Chat.SendWhisperText(args.author, "[bRC2] Joining leader instance, this will take a moment")
                        Notification("Joining leader instance, requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                    end
                end
            end

        -- LeaveGroup requests
        elseif (unicode.match(text, "^!lg") and Options.HasPermission(args.author, "LeaveGroup")) then
            if (g_GroupInfo) then
                Squad.Leave()

                Callback2.FireAndForget(function()
                    if (Platoon.IsInPlatoon() or Squad.IsInSquad()) then
                        Chat.SendWhisperText(args.author, "[bRC2] Leaving group was not successful")
                    else
                        Chat.SendWhisperText(args.author, "[bRC2] Left group")
                    end
                end, nil, 0.5)
            end

        -- LeaveZone requests
        elseif (unicode.match(text, "^!lz") and Options.HasPermission(args.author, "LeaveZone")) then
            Debug.Log("LeaveZone requested:", args.author)

            if (g_GroupInfo and (namecompare(args.author, g_GroupInfo.leader) or namecompare(args.author, Player.GetInfo()))) then
                if (g_ZoningInfo) then
                    Chat.SendWhisperText(args.author, "[bRC2] Unable to leave zone: zoning was already requested by " .. tostring(ChatLib.EncodePlayerLink(g_ZoningInfo)))

                else
                    g_ZoningInfo = tostring(args.author)

                    Game.ReturnToPvE()
                    Notification("Leaving zone, requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))

                    Callback2.FireAndForget(function()
                        local leaveZoneCountdown = Player.GetLeaveZoneCountdown()

                        if (type(leaveZoneCountdown) == "number" and leaveZoneCountdown > 3) then
                            Chat.SendWhisperText(args.author, "[bRC2] Leaving zone in " .. tostring(leaveZoneCountdown) .. " seconds")
                        else
                            Chat.SendWhisperText(args.author, "[bRC2] Leaving zone, this will take a moment")
                        end
                    end, nil, 0.5)
                end
            end

        -- Location requests
        elseif (unicode.match(text, "^!lo") and Options.HasPermission(args.author, "Location")) then
            Debug.Log("Location requested:", args.author)
            Chat.SendWhisperText(args.author, "[bRC2] " .. tostring(ChatLib.EncodeCoordLink()))

        -- Promote requests
        elseif (unicode.match(text, "^!p") and not namecompare(args.author, Player.GetInfo()) and Options.HasPermission(args.author, "Promote")) then
            Debug.Log("Promote requested:", args.author)

            if (g_GroupInfo and g_GroupInfo.is_mine) then
                for _, member in pairs(g_GroupInfo.members) do
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
        end
    end
end

function lf.OnDuelUpdated(args)
    Debug.Event(args)

    if (args.state) then
        if (unicode.upper(args.state) == "CONFIRMED") then
            g_DuelInfo = true
        elseif (unicode.upper(args.state) == "COMPLETED") then
            g_DuelInfo = false
        end
    end
end

function lf.OnLoadingComplete()
    if (g_ZoningInfo) then
        Chat.SendWhisperText(g_ZoningInfo, "[bRC2] Loading complete")
    end

    g_ZoningInfo = false
end

function lf.OnPlayerReady()
    OnSquadRosterUpdate()
end

function lf.OnSquadRosterUpdate()
    if (Platoon.IsInPlatoon()) then
        g_GroupInfo = Platoon.GetRoster()
    elseif (Squad.IsInSquad()) then
        g_GroupInfo = Squad.GetRoster()
    else
        g_GroupInfo = false
    end

    Debug.Table("g_GroupInfo", g_GroupInfo)
end
