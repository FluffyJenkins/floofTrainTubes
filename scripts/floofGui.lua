core_util = require("__core__/lualib/util.lua") -- adds table.deepcopy

--[[
    TODO Add buttons and shizzzzzz
]]

local floofGui = {
    floofTubes = {},
    templates = {
        configButton = {
            type = "button",
            name = "floof:openTubeConfig",
            caption = "Conveyor Tube Config",
            visible = true,
            anchor = {
                gui = defines.relative_gui_type.container_gui,
                position = defines.relative_gui_position.right,
                -- names = { "cargo-wagon", "locomotive", "artillery-wagon", "fluid-wagon" }
            }
        },
        configWindow = {
            base = {
                type = "frame",
                name = "floof:tubeConfigWindow",
                -- caption = "Train Conveyor Tube Config",
                visible = false,
                direction = "vertical",
                extra_style = {
                    use_header_filler = false,
                    horizontally_stretchable = "on",
                    vertically_stretchable = "on",
                    --size = { 395, 165 },
                }
            },
            title_bar = {
                type = "flow",
                name = "title_bar",
                extra_style = {
                    horizontally_stretchable = "on",
                    vertically_stretchable = false,
                    bottom_padding = 4,
                    horizontal_spacing = 8
                }
            },
            title_label = {
                type = "label",
                name = "title_label",
                caption = "Train Conveyor Tube config",
                style = "frame_title",
                ignored_by_interaction = true,
            },
            drag_handle = {
                type = "empty-widget",
                style = "draggable_space_header",
                ignored_by_interaction = true,
                extra_style = {
                    height = 24,
                    horizontally_stretchable = true,
                    vertically_stretchable = true,
                    --left_margin = 4,
                    right_margin = 4,
                },
            },
            close_button = {
                type = "sprite-button",
                name = "close_button",
                style = "frame_action_button",
                sprite = "utility/close_white",
                hovered_sprite = "utility/close_black",
                clicked_sprite = "utility/close_black"
            },
            inner_flow = {
                type = "flow",
                name = "inner_flow",
                extra_style = {
                    horizontally_stretchable = "on",
                    -- horizontally_stretchable = "on",
                    horizontal_spacing = 12
                }

            },
            inner_frame = {
                type = "frame",
                name = "inner_frame",
                style = "inside_shallow_frame_with_padding",
                extra_style = {
                    horizontally_stretchable = "on",
                    vertically_stretchable = "on",
                }
            },
            controls_flow = {
                type = "flow",
                name = "controls_flow",
                direction = "vertical",
                extra_style = {
                    horizontally_stretchable = "on",
                    horizontal_align = "left",
                    vertical_spacing = 16
                }
            },
            button = {
                type = "button",
                name = "button",
                caption = "button"
            },
            mode = {
                type = "switch",
                name = "modeSwitch",
                switch_state = "right",
                visible = false,
                left_label_caption = { "floofTrainTubes.pull" },
                right_label_caption = { "floofTrainTubes.fill" },
                extra_style = {
                    horizontal_align = "center"
                }
            },
            filterSwitchFlow = {
                type = "flow",
                name = "filterSwitchFlow",
                direction = "horizontal"
            },
            filterSwitchLabel = {
                type = "label",
                name = "filterSwitchLabel",
                caption = { "floofTrainTubes.filterSwitchPull" }
            },
            filterSwitch = {
                type = "switch",
                name = "filterSwitch",
            },
            filterInternalSwitchFlow = {
                type = "flow",
                name = "filterInternalSwitchFlow",
                direction = "horizontal"
            },
            filterInternalSwitchLabel = {
                type = "label",
                name = "filterInternalSwitchLabel",
                caption = { "floofTrainTubes.filterInternalSwitchPull" }
            },
            filterInternalSwitch = {
                type = "switch",
                name = "filterInternalSwitch",
            },
            filterInternalFrame = {
                type = "frame",
                name = "filterInternalFrame",
                visible = false,
                direction = "horizontal",
                style = "slot_button_deep_frame",
                extra_style = {
                    --size = { 400, 120 }
                }
            },
            filterInternalSlotTable = {
                type = "table",
                name = "filterInternalSlotTable",
                column_count = 10,
                style = "filter_slot_table",

            },
            filterInternalSlot = {
                type = "choose-elem-button",
                style = "logistic_slot_button",
                elem_type = "item",
                elem_filters = { "item" }
            }
        }
    }
}

floofTubes = global.floofTubes

local function fMerge(a, b)
    for k, v in pairs(b) do
        a[k] = v
    end
    return a
end

function floofGui.genConfigButton(name, caption, event, anchor, props)
    props = props or {}
    anchor = anchor or {}
    local player = game.players[event.player_index]
    local gui = player.gui.relative
    if gui["floof:" .. name] then
        gui["floof:" .. name].destroy()
    end

    ---@diagnostic disable-next-line:undefined-field
    local configButton = table.deepcopy(floofGui.templates.configButton)
    configButton.name = "floof:" .. name
    configButton.caption = caption
    local tempAnchor = configButton.anchor
    --util.merge(tempAnchor, anchor)

    configButton.anchor = fMerge(tempAnchor, anchor)

    util.merge(configButton, props)
    return gui.add(configButton)
end

function floofGui.add(gui, _template, extra, prefix)

    ---@diagnostic disable-next-line:undefined-field
    local template = table.deepcopy(_template)

    if template.name and prefix then
        template.name = prefix .. "-" .. template.name
    end

    local element = gui.add(template)

    extra = extra or template.extra_style
    if extra ~= nil then
        for k, v in pairs(extra) do
            element.style[k] = v
        end
    end


    local extra_params = template.extra_params or {}
    for k, v in pairs(extra_params) do
        element[k] = v
    end

    return element
end

local function validWindow(event)
    local player = game.players[event.player_index]
    local playerGUI = player.gui.screen
    local base = playerGUI["floof:tubeConfigWindow"]
    local baseValid = false
    local controlsValid = false

    if base and base.inner_frame and base.inner_frame.controls_flow then
        baseValid = true
    end
    if baseValid then
        local controls_flow = base.inner_frame.controls_flow
        if controls_flow.filterSwitchFlow and controls_flow.filterInternalSwitchFlow and controls_flow.modeSwitch and controls_flow.filterInternalFrame then
            controlsValid = true
        end
    end
    return baseValid and controlsValid
end

function floofGui.buildWindow(event, visible)
    local player = game.players[event.player_index]
    local playerGUI = player.gui.screen
    local conWin = floofGui.templates.configWindow
    local windowGUIs = {}
    local controlGUIs = {}

    -- window first

    windowGUIs["base"] = floofGui.add(playerGUI, conWin.base)
    windowGUIs.base.auto_center = true

    windowGUIs["title_bar"] = floofGui.add(windowGUIs["base"], conWin.title_bar)
    windowGUIs["title_bar"].drag_target = windowGUIs["base"]
    floofGui.add(windowGUIs["title_bar"], conWin.title_label)
    floofGui.add(windowGUIs["title_bar"], conWin.drag_handle)
    floofGui.add(windowGUIs["title_bar"], conWin.close_button)

    windowGUIs["inner_frame"] = floofGui.add(windowGUIs["base"], conWin.inner_frame)
    windowGUIs["controls_flow"] = floofGui.add(windowGUIs["inner_frame"], conWin.controls_flow)


    -- now controls


    controlGUIs["mode"] = floofGui.add(windowGUIs["controls_flow"], conWin.mode)

    controlGUIs["filterSwitchFlow"] = floofGui.add(windowGUIs["controls_flow"], conWin.filterSwitchFlow)
    controlGUIs["filterSwitchLabel"] = floofGui.add(controlGUIs["filterSwitchFlow"], conWin.filterSwitchLabel)
    controlGUIs["filterSwitch"] = floofGui.add(controlGUIs["filterSwitchFlow"], conWin.filterSwitch)

    controlGUIs["filterInternalSwitchFlow"] = floofGui.add(windowGUIs["controls_flow"], conWin.filterInternalSwitchFlow)
    controlGUIs["filterInternalSwitchLabel"] = floofGui.add(controlGUIs["filterInternalSwitchFlow"], conWin.filterInternalSwitchLabel)
    controlGUIs["filterInternalSwitch"] = floofGui.add(controlGUIs["filterInternalSwitchFlow"], conWin.filterInternalSwitch)

    controlGUIs["filterInternalFrame"] = floofGui.add(windowGUIs["controls_flow"], conWin.filterInternalFrame, nil)
    controlGUIs["filterInternalSlotTable"] = floofGui.add(controlGUIs["filterInternalFrame"], conWin.filterInternalSlotTable, nil)

    -- save gui references to player global

    local gPlayerGUI = floofGui.floofTubes.players[event.player_index].gui
    gPlayerGUI.tubeConfigWindow = windowGUIs
    gPlayerGUI.tubeConfigControls = controlGUIs
end

function floofGui.configToGUI(event, config)
    local gPlayerGUI = floofGui.floofTubes.players[event.player_index].gui

    gPlayerGUI.tubeConfigControls.mode.visible = config.both
    gPlayerGUI.tubeConfigControls.mode.switch_state = config.fill and "right" or "left"

    gPlayerGUI.tubeConfigControls.filterSwitchLabel.caption = config.fill and { "floofTrainTubes.filterSwitchFill" } or { "floofTrainTubes.filterSwitchPull" }
    gPlayerGUI.tubeConfigControls.filterSwitchLabel.style.font = config.onlyFilteredSlots and "default-bold" or "default"
    gPlayerGUI.tubeConfigControls.filterSwitch.switch_state = config.onlyFilteredSlots and "right" or "left"

    gPlayerGUI.tubeConfigControls.filterInternalSwitchLabel.caption = config.fill and { "floofTrainTubes.filterInternalSwitchFill" } or { "floofTrainTubes.filterInternalSwitchPull" }
    gPlayerGUI.tubeConfigControls.filterInternalSwitchLabel.style.font = config.onlyInternalFilter and "default-bold" or "default"
    gPlayerGUI.tubeConfigControls.filterInternalSwitch.switch_state = config.onlyInternalFilter and "right" or "left"

    gPlayerGUI.tubeConfigControls.filterInternalFrame.visible = config.onlyInternalFilter

    local slotTable = gPlayerGUI.tubeConfigControls.filterInternalSlotTable
    slotTable.clear()

    for k, v in pairs(config.internalFilter) do
        local temp = floofGui.add(slotTable, {
            type = "choose-elem-button",
            name = k,
            elem_type = "item",
            elem_filters = { ["item"] = true }
        })
        if config.internalFilter[k] ~= "_blank_" then temp.elem_value = config.internalFilter[k] end
    end
end

function floofGui.showConfigWindow(event, config)

    local player = game.players[event.player_index]
    local playerGUI = player.gui.screen
    if not validWindow(event) then
        floofGui.buildWindow(event)
    end

    floofGui.configToGUI(event, config)
    playerGUI["floof:tubeConfigWindow"].visible = true
end

function floofGui.hideConfigWindow(event)

    local player = game.players[event.player_index]
    local playerGUI = player.gui.screen
    if validWindow(event) then
        playerGUI["floof:tubeConfigWindow"].visible = false
    end
end

function floofGui.genConfigWindow(event)
    local player = game.players[event.player_index]
    local playerGUI = player.gui.screen
    local guis = {}
    -- if playerGUI["floof:tubeConfigWindow"] then playerGUI["floof:tubeConfigWindow"].destroy() end
    local conWin = floofGui.templates.configWindow

    guis["base"] = floofGui.add(playerGUI, conWin.base)
    guis.base.auto_center = true


    guis["title_bar"] = floofGui.add(guis["base"], conWin.title_bar, nil)
    guis["title_bar"].drag_target = guis["base"]
    floofGui.add(guis["title_bar"], conWin.title_label, nil)
    floofGui.add(guis["title_bar"], conWin.drag_handle, nil)
    floofGui.add(guis["title_bar"], conWin.close_button, nil)

    -- guis["inner_flow"] = floofGui.add(guis["base"], conWin.inner_flow)
    guis["inner_frame"] = floofGui.add(guis["base"], conWin.inner_frame, nil)
    guis["controls_flow"] = floofGui.add(guis["inner_frame"], conWin.controls_flow, nil)
    -- guis["button"] = floofGui.add(guis["controls_flow"], conWin.button, nil, conWin.base.name)
    return guis
end

function floofGui.genConfigOptions(event, config, modeSwitcher)

    local player = game.players[event.player_index]
    local playerGUI = player.gui.screen
    local baseKey = "floof:tubeConfigWindow"
    local guis = { base = playerGUI[baseKey], controls_flow = playerGUI[baseKey].inner_frame.controls_flow }
    local conWin = floofGui.templates.configWindow

    guis["mode"] = floofGui.add(guis["controls_flow"], conWin.mode)
    guis["mode"].left_label_caption = { "floofTrainTubes.pull" }
    guis["mode"].right_label_caption = { "floofTrainTubes.fill" }
    guis["mode"].switch_state = config.fill == true and "right" or "left"
    guis["mode"].visible = modeSwitcher or false

    guis["filterSwitchFlow"] = floofGui.add(guis["controls_flow"], conWin.filterSwitchFlow, nil)
    -- conWin.filterSwitchLabel.caption = config.fill and { "floofTrainTubes.filterSwitchFill" } or { "floofTrainTubes.filterSwitchPull" }
    guis["filterSwitchLabel"] = floofGui.add(guis["filterSwitchFlow"], conWin.filterSwitchLabel, nil)
    guis["filterSwitch"] = floofGui.add(guis["filterSwitchFlow"], conWin.filterSwitch, nil)
    -- guis["filterSwitch"].switch_state = config.onlyFilteredSlots and "right" or "left"

    guis["filterInternalSwitchFlow"] = floofGui.add(guis["controls_flow"], conWin.filterInternalSwitchFlow, nil)
    -- conWin.filterInternalSwitchLabel.caption = config.fill and { "floofTrainTubes.filterInternalSwitchFill" } or { "floofTrainTubes.filterInternalSwitchPull" }
    guis["filterInternalSwitchLabel"] = floofGui.add(guis["filterInternalSwitchFlow"], conWin.filterInternalSwitchLabel, nil)

    guis["filterInternalSwitch"] = floofGui.add(guis["filterInternalSwitchFlow"], conWin.filterInternalSwitch, nil)
    -- guis["filterInternalSwitch"].switch_state = config.onlyInternalFilter and "right" or "left"

    conWin.filterInternalFrame.visible = config.onlyInternalFilter
    guis["filterInternalFrame"] = floofGui.add(guis["controls_flow"], conWin.filterInternalFrame, nil)
    guis["filterInternalSlotTable"] = floofGui.add(guis["filterInternalFrame"], conWin.filterInternalSlotTable, nil)

    guis["filterInternalSlotTable"].clear()
    if config.internalFilter then
        for k, v in pairs(config.internalFilter) do
            local temp = floofGui.add(guis["filterInternalSlotTable"], {
                type = "choose-elem-button",
                name = k,
                elem_type = "item",
                elem_filters = { ["item"] = true }
            })
            if config.internalFilter[k] ~= "_blank_" then temp.elem_value = config.internalFilter[k] end
        end
    end


    return guis
end

return floofGui
