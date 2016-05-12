-- =============================================================================
--  bRC2
--    by: BurstBiscuit
--        Xsear
-- =============================================================================

if (Commands) then
    return
end

require "./Emotes"
require "./Zones"

local lf = {}


-- =============================================================================
--  Globals
-- =============================================================================

Commands = {}


-- =============================================================================
--  Variables
-- =============================================================================

local c_DataBreak   = ":"

local g_DuelInfo    = false
local g_GroupInfo   = false
local g_InviteQueue = {}
local g_HudNotes    = {}
local g_ReloadUI    = false
local g_ZoningInfo  = false


-- =============================================================================
--  Functions
-- =============================================================================

function Commands.OnChatLink(args)
    lf.OnChatLink(args)
end

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

function Commands.OnPreReloadUI(args)
    lf.OnPreReloadUI(args)
end

function Commands.OnSquadRosterUpdate(args)
    lf.OnSquadRosterUpdate(args)
end

function Commands.MyHudNote(args)
    lf.MyHudNote(args)
end


-- =============================================================================
--  Local Functions
-- =============================================================================

function lf.OnChatLink(args)
    if (not Options.IsAddonEnabled()) then
        return

    elseif (not args or not args.link_data or not args.author) then
        Debug.Warn("OnChatLink() - Missing data:", args)

    elseif (namecompare(args.author, Player.GetInfo()) or Options.IsPlayerWhitelisted(args.author) and not Options.IsPlayerBlocked(args.author)) then
        Debug.Table("OnChatLink()", args)

        if (unicode.match(args.link_data, "^Invite%" .. c_DataBreak .. "%w+$") and Options.HasPermission(args.author, "Invite")) then
            Debug.Log("Got an invite request via chat link")

            if (g_GroupInfo and g_GroupInfo.is_mine) then
                Debug.Log("In a group and group leader, checking for permissions")
                local invitee = unicode.match(args.link_data, "^Invite%" .. c_DataBreak .. "(%w+)$")

                if (Options.IsPlayerWhitelisted(invitee) and not Options.IsPlayerBlocked(invitee) and Options.HasPermission(invitee, "Invite")) then
                    if (g_InviteQueue[invitee]) then
                        Debug.Log("Already processing an invite forward for this invitee, return")
                        return

                    else
                        Debug.Log("Creating callback for invite forward to prevent multiple invites")
                        g_InviteQueue[invitee] = Callback2.Create()
                        g_InviteQueue[invitee]:Bind(function()
                            g_InviteQueue[invitee]:Release()
                            g_InviteQueue[invitee] = nil
                        end)
                        g_InviteQueue[invitee]:Schedule(10)
                    end

                    Debug.Log("Invite requested:", invitee)

                    if (Platoon.IsInPlatoon() and #g_GroupInfo.members < Platoon.GetMaxPlatoonSize()) then
                        if (Platoon.Invite(invitee)) then
                            Notification("Platoon invite sent to " .. tostring(ChatLib.EncodePlayerLink(invitee)))
                        end

                    elseif (Squad.IsInSquad() and #g_GroupInfo.members == Squad.GetMaxSquadSize()) then
                        if (Platoon.Invite(invitee)) then
                            Notification("Platoon invite sent to " .. tostring(ChatLib.EncodePlayerLink(invitee)))
                        end

                    elseif (Squad.IsInSquad() and #g_GroupInfo.members < Squad.GetMaxSquadSize()) then
                        if (Squad.Invite(invitee)) then
                            Notification("Squad invite sent to " .. tostring(ChatLib.EncodePlayerLink(invitee)))
                        end
                    end

                    if (g_HudNotes[invitee]) then
                        Debug.Log("Found a HUD note for the invite forward, removing")

                        Callback2.FireAndForget(function()
                            Component.GenerateEvent("MY_HUD_NOTE", {
                                command = "remove",
                                id      = g_HudNotes[invitee]
                            })
                        end, nil, 1)

                    else
                        Debug.Log("No HUD note for invite forward found")
                    end

                else
                    Debug.Log("Invitee is not whitelisted, is blocked, or does not have the invite permission")
                end

            else
                Debug.Log("Not in a group or not the group leader")
            end

        else
            Debug.Log("Chat link command not recognized")
        end

    else
        Debug.Log("args.author is not whitelisted, is blocked, or does not have the invite permission")
    end
end

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
                        Chat.SendWhisperText(g_GroupInfo.leader, ChatLib.GetEndcapString() .. "bRC2" .. ChatLib.GetLinkTypeIdBreak() .. "Invite" .. c_DataBreak .. ChatLib.StripArmyTag(args.author) .. ChatLib.GetEndcapString())
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
                end, nil, 1)
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
                    end, nil, 1)
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

        -- ReloadUI requests
        elseif (unicode.match(text, "^!rui") and Options.HasPermission(args.author, "ReloadUI")) then
            Debug.Log("ReloadUI requested:", args.author)

            if (g_ReloadUI) then
                Chat.SendWhisperText(args.author, "[bRC2] Unable to reload UI: already requested by " .. tostring(ChatLib.EncodePlayerLink(g_ReloadUI)))

            else
                g_ReloadUI = tostring(args.author)

                Notification("Reloading UI, requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                Chat.SendWhisperText(args.author, "[bRC2] Reloading UI, this will take a moment")
                Callback2.FireAndForget(System.ReloadUI, nil, 3)
            end

        -- RequestCancelArc requests
        elseif (unicode.match(text, "^!rca") and Options.HasPermission(args.author, "RequestCancelArc")) then
            Debug.Log("RequestCancelArc requested:", args.author)

            local jobStatus = Player.GetJobStatus()
            Debug.Table("jobStatus", jobStatus)

            if (jobStatus and jobStatus.job) then
                Game.RequestCancelArc(jobStatus.job.arc_id)
                Notification("Canceling arc, requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))

                Callback2.FireAndForget(function()
                    local canceledStatus = Player.GetJobStatus()

                    if (canceledStatus and canceledStatus.job) then
                        Chat.SendWhisperText(args.author, "[bRC2] Canceling arc was not successful")

                    else
                        Chat.SendWhisperText(args.author, "[bRC2] Canceled arc #" .. tostring(jobStatus.job.arc_id) .. ": " .. tostring(jobStatus.job.name))
                    end
                end, nil, 1)

            else
                Chat.SendWhisperText(args.author, "[bRC2] Unable to cancel arc: No job active")
            end

        -- RequestRestartArc requests
        elseif (unicode.match(text, "^!rra") and Options.HasPermission(args.author, "RequestRestartArc")) then
            Debug.Log("RequestRestartArc requested:", args.author)

            local jobStatus = Player.GetJobStatus()
            Debug.Table("jobStatus", jobStatus)

            if (jobStatus and jobStatus.job) then
                Game.RequestCancelArc(jobStatus.job.arc_id)
                Notification("Restarting arc, requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))

                Callback2.FireAndForget(function()
                    local canceledStatus = Player.GetJobStatus()

                    if (canceledStatus and canceledStatus.job) then
                        Chat.SendWhisperText(args.author, "[bRC2] Canceling arc was not successful")

                    else
                        Chat.SendWhisperText(args.author, "[bRC2] Canceled arc #" .. tostring(jobStatus.job.arc_id) .. ": " .. tostring(jobStatus.job.name))

                        local text = "Starting arc #" .. tostring(jobStatus.job.arc_id) .. " in 3 seconds: " .. tostring(jobStatus.job.name)

                        if (g_GroupInfo) then
                            if (g_GroupInfo.is_mine) then
                                if (Platoon.IsInPlatoon()) then
                                    Chat.SendChannelText("platoon", "[bRC2] " .. text)

                                elseif (Squad.IsInSquad()) then
                                    Chat.SendChannelText("squad", "[bRC2] " .. text)
                                end

                                Callback2.FireAndForget(Game.RequestStartArc, jobStatus.job.arc_id, 3)
                            end

                        else
                            Notification(text)
                            Callback2.FireAndForget(Game.RequestStartArc, jobStatus.job.arc_id, 3)
                        end
                    end
                end, nil, 1)

            else
                Chat.SendWhisperText(args.author, "[bRC2] Unable to cancel arc: No job active")
            end

        -- RequestTransfer requests
        elseif (unicode.match(text, "^!rt %w+") and Options.HasPermission(args.author, "RequestTransfer")) then
            Debug.Log("RequestTransfer requested:", args.author)

            if (g_ZoningInfo) then
                Chat.SendWhisperText(args.author, "[bRC2] Unable to transfer: zoning was already requested by " .. tostring(ChatLib.EncodePlayerLink(g_ZoningInfo)))

            else
                local requestedTransferZone = unicode.lower(unicode.match(text, "^!rt (%w+)"))

                if (unicode.match(text, "^!rt %d+")) then
                    requestedTransferZone = tonumber(unicode.match(text, "^!rt (%d+)"))
                end

                Debug.Log("requestedTransferZone", requestedTransferZone)

                if (c_Zones[requestedTransferZone]) then
                    g_ZoningInfo = tostring(args.author)

                    Notification("Transferring, requested by " .. tostring(ChatLib.EncodePlayerLink(args.author)))
                    Chat.SendWhisperText(args.author, "[bRC2] Transferring, this will take a moment")
                    Game.RequestTransfer((type(requestedTransferZone) == "number" and requestedTransferZone or c_Zones[requestedTransferZone]))
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

    if (Component.GetSetting("g_ReloadUI")) then
        g_ReloadUI = Component.GetSetting("g_ReloadUI")

        if (g_ReloadUI and not namecompare(g_ReloadUI, Player.GetInfo())) then
            Notification("Reloaded UI, requested by " .. tostring(ChatLib.EncodePlayerLink(g_ReloadUI)))
            Chat.SendWhisperText(g_ReloadUI, "[bRC2] Reloading UI complete")
        end

        g_ReloadUI = false

        Component.SaveSetting("g_ReloadUI", nil)
    end
end

function lf.OnPreReloadUI(args)
    Debug.Event(args)

    Component.SaveSetting("g_ReloadUI", g_ReloadUI or Player.GetInfo())
end

function lf.OnSquadRosterUpdate()
    if (Platoon.IsInPlatoon()) then
        g_GroupInfo = Platoon.GetRoster()
    elseif (Squad.IsInSquad()) then
        g_GroupInfo = Squad.GetRoster()
    else
        g_GroupInfo = false
    end

    -- Debug.Table("g_GroupInfo", g_GroupInfo)
end

function lf.MyHudNote(args)
    if (args.command and args.id and args.command == "remove") then
        if (g_HudNotes[args.id]) then
            g_HudNotes[g_HudNotes[args.id]] = nil
            g_HudNotes[args.id] = nil
        end

    elseif (args.json) then
        local json = jsontotable(args.json)
        Debug.Table("HudNote", json)

        if (json.replyTo == "groupmanager:_liaison") then
            if (json.title == "Squad Invitation Fowarded") then
                g_HudNotes[json.id] = ChatLib.StripArmyTag(json.subtitle)
                g_HudNotes[ChatLib.StripArmyTag(json.subtitle)] = json.id
            end
        end
    end

    Debug.Table("g_HudNotes", g_HudNotes)
end
