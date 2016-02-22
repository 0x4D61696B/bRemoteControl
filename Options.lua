-- =============================================================================
--  bRemoteControl
--    by: BurstBiscuit
-- =============================================================================

require "lib/lib_InterfaceOptions"

if (Options) then
    return
end


-- =============================================================================
--  Variables
-- =============================================================================

Options = {}

Options.IO = {
	
}

local c_OptionsMap = {
	Names = {
		Enable = false,
		List = {}
	},
	Special = {
		Enable = false,
		Developer = false,
		Ranger = false,
		Publisher = false,
		Mentor = false
	}
}

local CB2_ApplyOptions


-- =============================================================================
--  Interface Options
-- =============================================================================

function Options.OnOptionChanged(id, value)
    if (c_OptionsMap[id]) then
        c_OptionsMap[id](value)
    else
        Debug.Log("Unhandled message", {id = id, value = value})
    end
    
    -- Don't spam option updates
    if (CB2_ApplyOptions:Pending()) then
        CB2_ApplyOptions:Reschedule(1)
    else
        CB2_ApplyOptions:Schedule(1)
    end
end

function Options.Setup()
    InterfaceOptions.SaveVersion(2)
    
    -- General options
    InterfaceOptions.StartGroup({label = "General options"})
        InterfaceOptions.AddCheckBox({id = "GENERAL_ENABLE", label = "Addon enabled", default = false})
		InterfaceOptions.AddCheckBox({id = "GENERAL_DEBUG", label = "Debug enabled", default = false})
    InterfaceOptions.StopGroup()
    
    CB2_ApplyOptions = Callback2.Create()
    CB2_ApplyOptions:Bind(Options.ApplyOptions)
    
    InterfaceOptions.SetCallbackFunc(Options.OnOptionChanged)
    
    if (Component.GetSetting("NAMES_LIST")) then
        Options.IO.Character.Name.List = Component.GetSetting("NAMES_LIST")
    end
end

-- =============================================================================
--  Functions
-- =============================================================================

function Options.AddRemovePlayerName(name)
    Debug.Log("AddRemovePlayerName()", name)
    local playerName = ChatLib.StripArmyTag(name)
    
    if (Options.IO.Character.Name.List[playerName]) then
        Notification("Removing " .. ChatLib.EncodePlayerLink(playerName) .. " from the tracking list")
        Options.IO.Character.Name.List[playerName] = nil
        Tracker.CheckAvailableTargets()
    elseif (namecompare(playerName, Player.GetInfo())) then
        Notification("You can't add yourself to the tracking list")
    else
        Notification("Adding " .. ChatLib.EncodePlayerLink(playerName) .. " to the tracking list")
        Options.IO.Character.Name.List[playerName] = true
        Tracker.CheckAvailableTargets()
    end
    
    Component.SaveSetting("NAMES_LIST", Options.IO.Character.Name.List)
end

function Options.ClearPlayerNames()
    Notification("Clearing the list of tracked character names")
    Options.IO.Character.Name.List = {}
    Tracker.CheckAvailableTargets()
    Component.SaveSetting("NAMES_LIST", Options.IO.Character.Name.List)
end

function Options.ListPlayerNames()
    local count = 0
    local names = ""
    
    for k, _ in pairs(Options.IO.Names.List) do
        names = names .. " " .. ChatLib.EncodePlayerLink(k)
        count = count + 1
    end
    
    if (count > 0) then
        local plural = function() if (count > 2) then return "s" else return "" end end
        
        Notification("Currently whitelisted " .. count .. " name" .. plural() .. ":" .. names)
    else
        Notification("There are no names on the whitelist.")
    end
end

function Options.ApplyOptions()
    Debug.Log("Options.IO", Options.IO)
    Debug.Log("Applying options ...")
end
