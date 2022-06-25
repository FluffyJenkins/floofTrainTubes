local requestLimiter = 1e6
local requestRate = 300

local default_config = {
	fill = {
		fill = true,
		both = false,
		internalFilter = {
			floofTrainTubesSlot1 = "_blank_", floofTrainTubesSlot2 = "_blank_", floofTrainTubesSlot3 = "_blank_", s4 = "_blank_", s5 = "_blank_",
			s6 = "_blank_", s7 = "_blank_", s8 = "_blank_", s9 = "_blank_", s10 = "_blank_",
			s11 = "_blank_", s12 = "_blank_", s13 = "_blank_", s14 = "_blank_", s15 = "_blank_",
			s16 = "_blank_", s17 = "_blank_", s18 = "_blank_", s19 = "_blank_", s20 = "_blank_",
			s21 = "_blank_", s22 = "_blank_", s23 = "_blank_", s24 = "_blank_", s25 = "_blank_",
			s26 = "_blank_", s27 = "_blank_", s28 = "_blank_", s29 = "_blank_", s30 = "_blank_",
		}, -- {itemName,itemName,itemName} {"iron-plate","copper-plate","coal"}
		onlyFilteredSlots = false,
		onlyInternalFilter = false,
	},
	pull = {
		fill = false,
		both = false,
		internalFilter = {
			s1 = "_blank_", s2 = "_blank_", s3 = "_blank_", s4 = "_blank_", s5 = "_blank_",
			s6 = "_blank_", s7 = "_blank_", s8 = "_blank_", s9 = "_blank_", s10 = "_blank_",
			s11 = "_blank_", s12 = "_blank_", s13 = "_blank_", s14 = "_blank_", s15 = "_blank_",
			s16 = "_blank_", s17 = "_blank_", s18 = "_blank_", s19 = "_blank_", s20 = "_blank_",
			s21 = "_blank_", s22 = "_blank_", s23 = "_blank_", s24 = "_blank_", s25 = "_blank_",
			s26 = "_blank_", s27 = "_blank_", s28 = "_blank_", s29 = "_blank_", s30 = "_blank_",
		}, -- {itemName,itemName,itemName} {"iron-plate","copper-plate","coal"}
		onlyFilteredSlots = false,
		onlyInternalFilter = false,
	}
}

local function genDefaultSlots()
	default_config.fill.internalFilter = {}
	default_config.pull.internalFilter = {}
	for i = 1, 30 do
		default_config.fill.internalFilter["floofTrainTubesSlot" .. i] = "_blank_"
		default_config.pull.internalFilter["floofTrainTubesSlot" .. i] = "_blank_"
	end
end

genDefaultSlots()

local floofTubes = {
	players = {
	},
	inventories = {},
	tubes = {
		{
			tube = nil,
			type = nil, -- tube.inPipe,
			parent = nil,
		}
	}
}

floofGui = require("scripts.floofGui")
floofLogic = require("scripts.floofLogic")

fUtil = require("scripts.floofUtils")
fUtil.debugMode = false

local allowedNamed = { ["cargo-wagon"] = true, ["locomotive"] = true, ["artillery-wagon"] = true, ["fluid-wagon"] = true }

local function hasTube(grid)
	local contents = grid.get_contents()
	return contents["floof:conveyorTubeOut"] or contents["floof:conveyorTubeIn"]
end

local function isValidEntityFromEvent(event)
	local player = game.players[event.player_index]
	local grid = nil
	if player and player.opened then
		local object_name = player.opened.object_name
		if object_name == "LuaEquipmentGrid" then
			grid = player.opened
		elseif object_name == "LuaEntity" then
			grid = player.opened.grid or nil
		end
	end
	local ent = player.opened -- and event.entity and player.opened or player.opened and player.opened.grid and (event.grid == player.opened.grid) and player.opened or nil
	return ent and grid and hasTube(grid)
end

local function isAPartOfConfigWindow(gPlayerGUI, elem)
	for _, i in pairs(gPlayerGUI.tubeConfigControls) do
		if elem == i then return true end
	end
	return false
end

local function isGUIType(player)
	return (player.opened_gui_type == defines.gui_type.entity)
end

local function isValidEquipment(equipment)
	return equipment == "floof:conveyorTubeOut" or equipment == "floof:conveyorTubeIn"
end

local function findCorrectEntity(event)
	local ent = false
	if event.entity and isValidEntityFromEvent(event) then
		ent = event.entity
	else
		local player = game.players[event.player_index]
		if player.opened and player.opened.unit_number and (player.opened.grid and hasTube(player.opened.grid)) then
			ent = player.opened
		end
	end
	return ent
end

local function getPlayerConfig(event, ent, newSide)

	ent = ent or findCorrectEntity(event)
	local gPlayerGUI = floofTubes.players[event.player_index].gui
	if ent and ent.valid and gPlayerGUI.tubeConfigControls then
		local invent = floofTubes.inventories[ent.unit_number]
		local mode = newSide ~= nil and newSide or (newSide == nil and invent.fill)
		local config = invent.config[mode and "fill" or "pull"]
		config.both = invent.fill and invent.pull
		return config
	end
	return default_config
end

local function getInventoryFromGrid(grid)
	for _, invent in pairs(floofTubes.inventories) do
		if invent.entity and invent.entity.valid and invent.entity.grid and invent.entity.grid == grid then
			return invent
		end
	end
	return nil
end

local function initEnt(ent)
	floofTubes.inventories[ent.unit_number] = {
		unit_number = ent.unit_number,
		inventory = ent.get_inventory(defines.inventory.chest),
		entity = ent,
		---@diagnostic disable-next-line:undefined-field
		config = table.deepcopy(default_config),
		train = ent.train,
		train_id = ent.train.id,
		fill = false,
		pull = false,
	}
end

local function initPlayer(event)
	local player = game.players[event.player_index]
	if player then
		if not floofTubes.players[event.player_index] then
			floofTubes.players[event.player_index] = {
				gui = {
					tubeConfigWindow = {},
					tubeConfigControls = {},
					configButtons = {},
				},
				player_index = event.player_index
			}
		end

		if not player.gui.screen["floof:tubeConfigWindow"] then
			floofGui.buildWindow(event, false)
		end
	end
end

local function initCheck(event, playerOnly)
	-- TODO write init checks for globals and if not existing create them (might need some more default templates)
	local ent = findCorrectEntity(event)
	if playerOnly ~= true and ent and not floofTubes.inventories[ent.unit_number] then
		initEnt(ent)
	end

	initPlayer(event)
end

local function toggleConfigUI(event, visible)
	--fUtil.debug("visible?"..(visible and "true" or "false"),"toggleConfigUI")
	local player = game.players[event.player_index]
	local playerGUI = player.gui.screen
	local gPlayerGUI = floofTubes.players[event.player_index].gui
	--[[
	if (not gPlayerGUI.tubeConfigWindow or not gPlayerGUI.tubeConfigWindow.base or gPlayerGUI.tubeConfigWindow.base.valid == false) then
		createConfigWindow(event)
		--game.players[event.player_index].opened = elem
	end
	if visible and gPlayerGUI.tubeConfigWindow and gPlayerGUI.tubeConfigWindow.base then
		gPlayerGUI.tubeConfigWindow.base.visible = true
	end
	]]
	if visible then
		floofGui.showConfigWindow(event, getPlayerConfig(event))
	else
		floofGui.hideConfigWindow(event)
	end
end

local function getDefineForType(name)
	local guiType = defines.relative_gui_type.container_gui
	if name == "locomotive" then guiType = defines.relative_gui_type.train_gui end
	if name == "cargo-wagon" then guiType = defines.relative_gui_type.container_gui end
	if name == "artillery-wagon" then guiType = defines.relative_gui_type.container_gui end
	if name == "fluid-wagon" then guiType = defines.relative_gui_type.container_gui end
	return guiType
end

local function createConfigButtons(event)
	local playerGUI = game.players[event.player_index].gui.relative

	local gPlayerGUI = floofTubes.players[event.player_index].gui
	for name, _ in pairs(allowedNamed) do
		if playerGUI["floof:openTubeConfig_" .. name] then
			playerGUI["floof:openTubeConfig_" .. name].destroy()
		end
		gPlayerGUI.configButtons["floof:openTubeConfig_" .. name] = floofGui.genConfigButton("openTubeConfig_" .. name, "Conveyor Tube Config", event, { gui = getDefineForType(name), type = name })
	end
end

local function toggleConfigButtons(event, visible)
	local playerGUI = game.players[event.player_index].gui.relative
	playerGUI["floof:openTubeConfig_locomotive"].visible = visible
	playerGUI["floof:openTubeConfig_cargo-wagon"].visible = visible
	playerGUI["floof:openTubeConfig_artillery-wagon"].visible = visible
	playerGUI["floof:openTubeConfig_fluid-wagon"].visible = visible
end

local function on_gui_opened(event)
	local player = game.players[event.player_index]

	if event.entity and allowedNamed[event.entity.type] ~= nil then
		initCheck(event)
		createConfigButtons(event)
		local ent = event.entity
		local valid = isValidEntityFromEvent(event)
		toggleConfigButtons(event, valid)
	end
end

local function on_gui_closed(event)
	local player = game.players[event.player_index]
	floofGui.hideConfigWindow(event)
	if event.entity then
		local ent = event.entity
		if allowedNamed[ent.type] ~= nil and isValidEntityFromEvent(event) then
			toggleConfigUI(event, false)
		end
	end
	if event.element then
		local elem = event.element
		if elem.name == "floof:tubeConfigWindow" then
			toggleConfigUI(event, false)
		end
	end
end

local function on_gui_click(event)

	local gPlayerGUI = floofTubes.players[event.player_index].gui
	if gPlayerGUI.configButtons[event.element.name] or (event.element and event.element.parent and event.element.parent.parent and
		event.element.parent.parent.name == "floof:tubeConfigWindow" and event.element.name == "close_button") then
		toggleConfigUI(event, not (gPlayerGUI.tubeConfigWindow and gPlayerGUI.tubeConfigWindow.base.visible))
	end
end

local function on_gui_switch_state_changed(event)
	if event.element.valid and event.element.get_mod() == "floofTrainTubes" then
		local ent = findCorrectEntity(event)
		if ent == nil or ent and floofTubes.inventories[ent.unit_number] == nil then return end
		local elem = event.element
		local gPlayerGUI = floofTubes.players[event.player_index].gui
		if isAPartOfConfigWindow(gPlayerGUI, elem) then
			local mode = gPlayerGUI.tubeConfigControls.mode.switch_state == "right"
			---@diagnostic disable-next-line
			local config = floofTubes.inventories[ent.unit_number].config[mode and "fill" or "pull"]

			if elem.name == "filterSwitch" then
				config.onlyFilteredSlots = elem.switch_state == "right"
			end
			if elem.name == "filterInternalSwitch" then
				config.onlyInternalFilter = elem.switch_state == "right"
			end

			floofGui.configToGUI(event, getPlayerConfig(event, ent, mode))
		end
	end
end

local function on_gui_elem_changed(event)
	local name = event.element.name -- s1 for first button
	if name:find("floofTrainTubesSlot", 1, true) == 1 then
		initCheck(event)
		local gPlayerGUI = floofTubes.players[event.player_index].gui
		local invent = floofTubes.inventories[findCorrectEntity(event).unit_number]
		local mode = gPlayerGUI.tubeConfigControls.mode.switch_state == "right" and "fill" or "pull"
		invent.config[mode].internalFilter[name] = event.element.elem_value
	end
end

local function on_player_placed_equipment(event)
	local player = game.players[event.player_index]
	local ent = player.opened
	if isValidEntityFromEvent(event) and isGUIType(player) and isValidEquipment(event.equipment.name) then
		toggleConfigButtons(event, true)
		initCheck(event)
		local invent = floofTubes.inventories[ent.unit_number]
		if invent and invent.entity.valid then
			fUtil.debug("Tube has been put in a slot!")
			if event.equipment.name == "floof:conveyorTubeIn" then invent.pull = true end
			if event.equipment.name == "floof:conveyorTubeOut" then invent.fill = true end
			--testing on name below cause invent.fill can already be true
			floofGui.configToGUI(event, getPlayerConfig(event, ent, event.equipment.name == "floof:conveyorTubeOut"))

		elseif invent and not invent.entity.valid then
			invent = nil
		end
	end
end

local function on_player_removed_equipment(event)
	local player = game.players[event.player_index]
	local ent = player.opened and event.entity and player.opened or nil
	if ent and ent.grid and isGUIType(player) and isValidEquipment(event.equipment) then
		if hasTube(ent.grid) then
			local invent = floofTubes.inventories[ent.unit_number]
			if event.equipment == "floof:conveyorTubeIn" then invent.pull = false end
			if event.equipment == "floof:conveyorTubeOut" then invent.fill = false end

			floofGui.configToGUI(event, getPlayerConfig(event, ent))
			fUtil.debug("Tube has been removed from a slot!")
		else
			local invent = floofTubes.inventories[ent.unit_number]
			invent.fill = false
			invent.pull = false
			floofGui.hideConfigWindow(event)
			toggleConfigButtons(event, false)
			fUtil.debug("All tubes has been removed from a grid!")
		end
	end
end

local function on_player_joined_game(event)
	initCheck(event)
end

local function on_train_created(event)
	if event.old_train_id_1 or event.old_train_id_2 then
		for k, v in pairs(floofTubes.inventories) do
			if not v.entity or v.entity.valid == false then
				floofTubes.inventories[k] = nil
				fUtil.debug("cleaning up orphaned config", "on_train_created")
				return
			end
			if v.train_id == event.old_train_id_1 or v.train_id == event.old_train_id_2 then
				v.train = v.entity.train
				v.train_id = v.entity.train and v.entity.train.id or nil
			end
		end
	end
end

local function on_tick(event)

	if event.tick % requestRate == 0 then
		local requests = floofLogic.genRequests()
		floofLogic.processRequests(requests,requestLimiter)
	end
	if event.tick % 30 == 0 then
		for _, i in pairs(floofTubes.players) do
			if i.gui.tubeConfigWindow and i.gui.tubeConfigWindow.base ~= nil and i.gui.tubeConfigWindow.base.valid then
				i.gui.tubeConfigWindow.base.bring_to_front()
			end
		end
	end
end


local function on_entity_settings_pasted(event)
	if event.source and event.source.valid and event.destination and event.destination.valid then
		if floofTubes.inventories[event.source.unit_number] then
			---@diagnostic disable-next-line:undefined-field
			local config = table.deepcopy(floofTubes.inventories[event.source.unit_number].config)
			local aaaaaaa = "aaaaaaaa"
			if not floofTubes.inventories[event.destination.unit_number] then initEnt(event.destination) end
			local invent = floofTubes.inventories[event.destination.unit_number]
			invent.config = config
		end
	end
end

local function on_equipment_inserted(event)
	if event.equipment and event.equipment.valid then
		if event.equipment.name == "floof:conveyorTubeIn" or event.equipment.name == "floof:conveyorTubeOut" then
			local invent = getInventoryFromGrid(event.grid)
			if invent then
				invent.pull = false
				invent.fill = false
				for _, equipment in pairs(invent.entity.grid.equipment) do
					if equipment.name == "floof:conveyorTubeIn" then invent.pull = true end
					if equipment.name == "floof:conveyorTubeOut" then invent.fill = true end
				end
			end
		end
	end
end

local function on_init()
	global.floofTubes = floofTubes
end

local function on_load()
	floofTubes = global.floofTubes
	floofGui.floofTubes = global.floofTubes
	floofLogic.floofTubes = global.floofTubes

	requestLimiter = settings.global["floofTrainTubes-requestLimiter"].value
	requestRate = settings.global["floofTrainTubes-requestRate"].value

	script.on_event(defines.events.on_tick, on_tick)

	script.on_event(defines.events.on_equipment_inserted, on_equipment_inserted)
	script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
	script.on_event(defines.events.on_player_placed_equipment, on_player_placed_equipment)
	script.on_event(defines.events.on_player_removed_equipment, on_player_removed_equipment)

	script.on_event(defines.events.on_gui_click, on_gui_click)
	script.on_event(defines.events.on_gui_opened, on_gui_opened)
	script.on_event(defines.events.on_gui_closed, on_gui_closed)
	script.on_event(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)
	script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)

	script.on_event(defines.events.on_train_created, on_train_created)

	script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
end

local function on_runtime_mod_setting_changed(event)
	if event.setting_type == "runtime-global" then
		if event.setting == "floofTrainTubes-requestLimiter" then
			requestLimiter = settings.global["floofTrainTubes-requestLimiter"]
		end
		if event.setting == "floofTrainTubes-requestRate" then
			requestRate = settings.global["floofTrainTubes-requestRate"]
		end
	end
end

script.on_load(on_load)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)

script.on_init(on_init)
