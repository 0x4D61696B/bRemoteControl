-- =============================================================================
--  bRC2
--    by: BurstBiscuit
--        Xsear
-- =============================================================================

if (UI) then
    return
end

require "lib/lib_ConfirmDialog"
require "lib/lib_HudManager"
require "lib/lib_RowScroller"
require "lib/lib_Tabs"
require "lib/lib_Tooltip"

local lf = {}


-- =============================================================================
--  Globals
-- =============================================================================

UI = {}


-- =============================================================================
--  Constants
-- =============================================================================

local FRAME             = Component.GetFrame("Main")
local WINDOW            = Component.GetWidget("Window")
local BODY              = Component.GetWidget("Body")
local FOSTER_CONTAINER  = Component.GetWidget("foster_container")

local c_CheckBox = [[<CheckBox dimensions="dock: fill" style="font: UbuntuMedium_9" />]]

local c_UI      = {
    TabId       = {
        Local   = 1,
        Global  = 2,
    }
}

c_UI.TabIndex     = { -- Because we can't reference it from within itself :D
    [c_UI.TabId.Local]  = "Local",
    [c_UI.TabId.Global] = "Global",
}


-- =============================================================================
--  Variables
-- =============================================================================

local g_FrameShown  = false
local g_PlayerMap   = {}

local g_UI = {
    SelectedPlayer          = nil,
    Tabs                    = nil,
    w_ButtonRemoveAll       = nil,
    w_ButtonRemovePlayer    = nil,
    w_PlayerCheckboxes      = {},
    w_SelectPlayerDropdown  = nil,
    w_TabPanes              = {},
}

-- =============================================================================
--  Functions
-- =============================================================================

function UI.Setup()
    lf.SetupUI()

    HudManager.BindOnShow(lf.OnHudShow)
end

function UI.Open()
    if (not g_FrameShown) then
        g_FrameShown = true
        Component.SetInputMode("cursor")
        FRAME:Show(true)
    end
end

function UI.Close()
    g_FrameShown = false
    Component.SetInputMode("default")
    Tooltip.Show(nil)
    FRAME:Show(false)
end

function UI.GetSelectedPlayer()
    return g_UI.SelectedPlayer or ""
end

function UI.SelectPlayer(playerName)
    if (playerName and g_PlayerMap[playerName]) then
        g_UI.w_SelectPlayerDropdown:SetSelectedByIndex(g_PlayerMap[playerName])

        -- If enabled, open UI
        if (Options.IsOpenOnAddEnabled()) then
            g_UI.Tabs:Select(c_UI.TabId.Local)
            UI.Open()
        end

    else
        Debug.Warn("Forcibly changing SelectPlayerDropdown because user removed the player that was selected") -- TODO: Not a warning
        g_UI.w_SelectPlayerDropdown:SetSelectedByIndex(1)
    end
end

function UI.UpdateUIState()
    lf.UpdateUIState()
end


-- =============================================================================
--  Local Functions
-- =============================================================================

function lf.SetupUI()
    -- Create and Define Tabs
    g_UI.Tabs = Tabs.Create(2, BODY)
    g_UI.Tabs:AddHandler("OnTabChanged", lf.OnUITabChanged)
    g_UI.Tabs:SetTab(c_UI.TabId.Local,  {id = c_UI.TabId.Local,     label = "Player permissions"}) -- Can have texture and region keys if you want an icon on the tab, like Inventory/Account Items, and also a tint key, like Arcporter
    g_UI.Tabs:SetTab(c_UI.TabId.Global, {id = c_UI.TabId.Global,    label = "Toggle commands"})

    -- Store the bodies (:D)
    g_UI.w_TabPanes[c_UI.TabId.Local]   = g_UI.Tabs:GetBody(c_UI.TabId.Local)
    g_UI.w_TabPanes[c_UI.TabId.Global]  = g_UI.Tabs:GetBody(c_UI.TabId.Global)

    -- Setup the remaining UI
    lf.SetupLocalUI(g_UI.w_TabPanes[c_UI.TabId.Local])
    lf.SetupGlobalUI(g_UI.w_TabPanes[c_UI.TabId.Global])
    Debug.Log("SetupUI Completed")

    -- Trigger a UI update to get it in the right state
    lf.UpdateUIState()

    -- Set default tab
    g_UI.Tabs:Select(c_UI.TabId.Global)
end

function lf.OnUITabChanged(args)
    Debug.Log("Swapped to tab ", c_UI.TabIndex[args.index]) -- (lots of args here if needed)
end

function lf.CreateOptionCheckBox(name, PARENT, action, optionId, initCheck)
    -- Create widgets
    local CHOICE = {GROUP=Component.CreateWidget("OptionsChoicePrint", PARENT)}
    CHOICE.GROUP:SetDims("left: 0; right: 100%; top: 0; height: 22")
    CHOICE.CHECKBOX = Component.CreateWidget(c_CheckBox, CHOICE.GROUP:GetChild("ChoiceGroup"))

    -- Configure option
    if optionId then
        -- Set initial value and save optionId tag
        if initCheck == 0 then
            initCheck = false
        end
        CHOICE.CHECKBOX:SetTag(tonumber(optionId))
        CHOICE.CHECKBOX:SetCheck(initCheck)
    end

    -- Bind state change
    CHOICE.CHECKBOX:BindEvent("OnStateChanged", function(args)
        if args.user then
            action(CHOICE.CHECKBOX:GetCheck())
        end
    end)

    CHOICE.CHECKBOX:BindEvent("OnMouseEnter", function(args)
        if (c_PermissionDescriptions[name]) then
            Tooltip.Show(c_PermissionDescriptions[name], {halign = "left"})
        end
    end)

    CHOICE.CHECKBOX:BindEvent("OnMouseLeave", function(args)
        Tooltip.Show(nil)
    end)

    -- Finish it
    CHOICE.CHECKBOX:SetDims("left:0; width:100%; height:22; top:0")
    CHOICE.CHECKBOX:SetText(name)

    -- local text_dims = CHOICE.CHECKBOX:GetTextDims().width+5 -- Dunno what to do with this yet
    --if text_dims > g_OptionsWidth then
    --    g_OptionsWidth = text_dims
    --end

    return CHOICE
end


function lf.SetupGlobalUI(PANE)
    Debug.Log("lf.SetupGlobalUI")
    -- Create list container in our tab body
    local globalUI = {GROUP = Component.CreateWidget("OptionsListPrint", PANE)} -- Created directly onto this tab body
    globalUI.LIST = globalUI.GROUP:GetChild("List")

    -- Create scroller ontop of the list
    globalUI.SCROLLER = RowScroller.Create(globalUI.LIST)
    globalUI.SCROLLER:SetSliderMargin(5, 5)
    globalUI.SCROLLER:SetSpacing(2)
    globalUI.SCROLLER:ShowSlider("auto") -- Won't show slider until neccessary
    globalUI.SCROLLER:UpdateSize()

    -- Sort the permissions by name
    local permissionList = {}

    for key in pairs(c_DefaultPermissions) do
        table.insert(permissionList, key)
    end

    table.sort(permissionList, function(a, b) return a < b end)

    for _, permissionKey in pairs(permissionList) do
        -- Create CheckBox
        Debug.Log("Creating Choice", permissionKey)

        local CHOICE = lf.CreateOptionCheckBox(permissionKey, FOSTER_CONTAINER,
            -- OnStateChange Handler
            function(value)
                Options.SetGlobalPermission(permissionKey, value)
            end,
        permissionKey, Options.GetGlobalPermission(permissionKey)) -- Default value being sent here

        -- Add to RowScroller
        globalUI.SCROLLER:AddRow(CHOICE.GROUP)
    end

    -- Just incase
    globalUI.SCROLLER:UpdateSize()
end

function lf.SetupLocalUI(PANE)
    Debug.Log("lf.SetupLocalUI")

    -- Instantiate header and list
    local localUI = {GROUP = Component.CreateWidget("OptionsListPrint2", PANE)} -- Created directly onto this tab body
    localUI.CONTAINER = localUI.GROUP:GetChild("Container")
    localUI.HEADER = localUI.CONTAINER:GetChild("Header"):GetChild("Container")
    localUI.LIST = localUI.CONTAINER:GetChild("List")

    -- Setup the local header options
        -- Player Dropdown
        localUI.SELECT_PLAYER = localUI.HEADER:GetChild("SelectPlayer")
            g_UI.w_SelectPlayerDropdown = localUI.SELECT_PLAYER
            localUI.SELECT_PLAYER:SetTitle("Player")
            localUI.SELECT_PLAYER:BindEvent("OnSelect",
                function(args)
                    -- local selectedIndex = select(2, DROPDOWN:GetSelected())
                    local selectedValue = g_UI.w_SelectPlayerDropdown:GetSelected() -- In this case, the label is actually the value.
                    Debug.Log("selectedValue", selectedValue)
                    g_UI.SelectedPlayer = (selectedValue ~= "" and selectedValue) or nil
                    lf.OnUIPlayerChanged()
                end)

        -- Player Block Checkbox
        localUI.CHOICE_BLOCK_PLAYER = localUI.HEADER:GetChild("ChoiceBlockPlayer")
            localUI.CHOICE_BLOCK_PLAYER:SetText("Block")
            localUI.CHOICE_BLOCK_PLAYER:Show(true) -- TODO: This was kind of a random thought, to have the option to tempoarily "ignore" a player. Incase Plebsis acts up, for example. :)

        -- Remove Player Button
        localUI.BUTTON_REMOVE_PLAYER = localUI.HEADER:GetChild("ButtonRemovePlayer")
            g_UI.w_ButtonRemovePlayer = localUI.BUTTON_REMOVE_PLAYER
            localUI.BUTTON_REMOVE_PLAYER:SetText("Remove player")
            localUI.BUTTON_REMOVE_PLAYER:SetParam("tint", "#FF0000")
            localUI.BUTTON_REMOVE_PLAYER:BindEvent("OnSubmit",
                function()
                    -- Assert state
                    assert(UI.GetSelectedPlayer() ~= "")

                    -- Remove that player
                    ConfirmDialog.OpenConfirmDialog(
                        {
                            title               = "Confirm",
                            message             = "Do you really want to remove " .. tostring(UI.GetSelectedPlayer()) .. "?",
                            enableInvisClose    = true,
                            posButtonKey        = "CONFIRM_BUTTON_TEXT",
                            posButtonColor      = "FF0000",
                            negButtonKey        = "CANCEL"
                        },
                        function(confirmed)
                            if (confirmed) then
                                Debug.Log("Confirmed removal of", UI.GetSelectedPlayer())
                                Options.AddOrRemoveName(UI.GetSelectedPlayer())
                            end
                        end
                    )
                end
            )

        -- Remove All Button
        localUI.BUTTON_REMOVE_ALL = localUI.HEADER:GetChild("ButtonRemoveAll")
            g_UI.w_ButtonRemoveAll = localUI.BUTTON_REMOVE_ALL
            localUI.BUTTON_REMOVE_ALL:SetParam("tint", "#FF0000")
            localUI.BUTTON_REMOVE_ALL:SetText("Remove all")
            localUI.BUTTON_REMOVE_ALL:BindEvent("OnSubmit",
                function()
                    ConfirmDialog.OpenConfirmDialog(
                        {
                            title               = "Confirm",
                            message             = "Do you really want to remove ALL whitelisted players?",
                            enableInvisClose    = true,
                            posButtonKey        = "CONFIRM_BUTTON_TEXT",
                            posButtonColor      = "FF0000",
                            negButtonKey        = "CANCEL"
                        },
                        function(confirmed)
                            if (confirmed) then
                                Debug.Log("Confirmed removal of all players")
                                Options.RemoveAllPlayers()
                            end
                        end
                    )
                end
            )

    -- Setup the list
        -- Create scroller ontop of the list
        localUI.SCROLLER = RowScroller.Create(localUI.LIST)
        localUI.SCROLLER:SetSliderMargin(5, 5)
        localUI.SCROLLER:SetSpacing(2)
        localUI.SCROLLER:ShowSlider("auto") -- Won't show slider until neccessary
        localUI.SCROLLER:UpdateSize()

        -- Sort the permissions by name
        local permissionList = {}

        for key in pairs(c_DefaultPermissions) do
            table.insert(permissionList, key)
        end

        table.sort(permissionList, function(a, b) return a < b end)

        -- Create checkboxes and add them to the scrolling list
        for _, permissionKey in pairs(permissionList) do
            -- Create CheckBox
            local CHOICE = lf.CreateOptionCheckBox(permissionKey, FOSTER_CONTAINER,
                -- OnStateChange Handler
                function(value)
                    -- Assert state
                    assert(UI.GetSelectedPlayer() ~= "") -- We must have a selected player in order to change his options
                    assert(type(Options.GetPlayerPermissions(UI.GetSelectedPlayer())) == "table") -- There must be a permissions table for the selected player

                    -- Change that player's permissions
                    Options.SetPlayerPermission(UI.GetSelectedPlayer(), permissionKey, value)
                end,
            permissionKey, c_DefaultPermissions[permissionKey]) -- Default value being sent here

            -- Disable for now
            CHOICE.CHECKBOX:Disable()

            -- Store global reference so that we can change later
            g_UI.w_PlayerCheckboxes[permissionKey] = CHOICE

            -- Add to RowScroller
            localUI.SCROLLER:AddRow(CHOICE.GROUP)
        end

        -- Just incase
        localUI.SCROLLER:UpdateSize()
end

function lf.UpdateUIState()
    Debug.Log("lf.UpdateUIState()")
    lf.RepopulatePlayerDropdown()

    local haveAtLeastOnePlayer = (next(Options.GetPlayerPermissions())) or false

    if haveAtLeastOnePlayer then
        if (UI.GetSelectedPlayer() ~= "") then
            g_UI.w_ButtonRemovePlayer:Enable()
        end

        g_UI.w_ButtonRemoveAll:Enable()

    else
        Debug.Log("No whitelisted players, disabling buttons and checkboxes")

        -- Disable remove buttons
        g_UI.w_ButtonRemovePlayer:Disable()
        g_UI.w_ButtonRemoveAll:Disable()

        -- Uncheck all checkboxes and disable them
        for _, CHOICE in pairs(g_UI.w_PlayerCheckboxes) do
            CHOICE.CHECKBOX:SetCheck(false)
            CHOICE.CHECKBOX:Disable()
        end
    end
end

function lf.RepopulatePlayerDropdown()
    Debug.Log("lf.RepopulatePlayerDropdown()")

    if not g_UI.w_SelectPlayerDropdown then
        Debug.Warn("RepopulatePlayerDropdown called before player dropdown was created :(")
        return
    end

    -- Clear existing items
    g_UI.w_SelectPlayerDropdown:ClearItems()
    g_PlayerMap = {}

    -- Sort the player names
    local playerList = {}

    for player in pairs(Options.GetPlayerPermissions()) do
        table.insert(playerList, player)
    end

    table.sort(playerList, function(a, b) return unicode.lower(a) < unicode.lower(b) end)

    -- Add item for each player
    for i, playerName in pairs(playerList) do
        g_UI.w_SelectPlayerDropdown:AddItem(playerName)
        g_PlayerMap[playerName] = i
    end

    -- Attempt to auto select a player
    if (#playerList > 0) then
        if (UI.GetSelectedPlayer() == "" or not g_PlayerMap[UI.GetSelectedPlayer()]) then
            g_UI.w_SelectPlayerDropdown:SetSelectedByIndex(1)

        elseif (g_PlayerMap[UI.GetSelectedPlayer()]) then
            g_UI.w_SelectPlayerDropdown:SetSelectedByIndex(g_PlayerMap[UI.GetSelectedPlayer()])
        end
    end
end


function lf.OnUIPlayerChanged()
    Debug.Log("lf.OnUIPlayerChanged()")

    -- Get player
    local player = UI.GetSelectedPlayer()

    -- We have a player, proceed enabling/disabling checkboxes based on permissionKeys
    if player ~= "" then
        -- Get permissions
        local playerPermissions = Options.GetPlayerPermissions(player)

        -- Load new permission values into checkboxes
        for permissionKey, CHOICE in pairs(g_UI.w_PlayerCheckboxes) do
            -- Get checkbox reference and permissionValue for this permissionKey
            local CHECKBOX = CHOICE.CHECKBOX
            local permissionValue = playerPermissions[permissionKey]

            -- Enable the checkbox
            CHECKBOX:Enable()

            -- Set the Checkbox to the appropriate state if we have a value for the key
            if permissionValue ~= nil then
                CHECKBOX:SetCheck(permissionValue)

            -- If the permissionValue is nil, then the permissionKey does not exist
            else
                Debug.Warn("Player " .. tostring(player) .. " is missing " .. tostring(permissionKey) .. " in his permissions table, for which we have a checkbox.")
                local defaultPermission = c_DefaultPermissions[permissionKey]

                Options.SetPlayerPermission(player, permissionKey, defaultPermission)
                CHECKBOX:SetCheck(defaultPermission)
            end
        end

    -- We have no player, disable all checkboxes
    else
        Debug.Log("No player selected, disabling all checkboxes")

        for _, CHOICE in pairs(g_UI.w_PlayerCheckboxes) do
            CHOICE.CHECKBOX:SetCheck(false)
            CHOICE.CHECKBOX:Disable()
        end
    end
end

function lf.OnHudShow(show, duration)
    FRAME:ParamTo("alpha", tonumber(show), duration)
end
