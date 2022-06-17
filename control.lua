--[[
TODO:
Make tube button show up on artillery and loco (might be easier to just make seperate buttons for
each type!
]]

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

fUtil = require("scripts.floofUtils")
fUtil.debugMode = true

local allowedNamed = { ["cargo-wagon"] = true, ["locomotive"] = true, ["artillery-wagon"] = true, ["fluid-wagon"] = true }

local function hasTube(grid)
	local contents = grid.get_contents()
	return contents["floof:conveyorTubeOut"] or contents["floof:conveyorTubeIn"]
end

local function isValid(ent)
	return ent.grid and hasTube(ent.grid)
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
	if event.entity and isValid(event.entity) then
		ent = event.entity
	else
		local player = game.players[event.player_index]
		if player.opened and player.opened.unit_number and isValid(player.opened) then
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

local function initCheck(event, playerOnly)
	-- TODO write init checks for globals and if not existing create them (might need some more default templates)
	local ent = findCorrectEntity(event)
	local player = game.players[event.player_index]
	if playerOnly ~= true and ent and not floofTubes.inventories[ent.unit_number] then
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

	if player and not floofTubes.players[event.player_index] then
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
		local valid = isValid(ent)
		toggleConfigButtons(event, valid)
	end
end

local function on_gui_closed(event)
	local player = game.players[event.player_index]
	floofGui.hideConfigWindow(event)
	if event.entity then
		local ent = event.entity
		if allowedNamed[ent.type] ~= nil and isValid(ent) then
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
	if isValid(ent) and isGUIType(player) and isValidEquipment(event.equipment.name) then
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
	local ent = player.opened
	if ent.grid and isGUIType(player) and isValidEquipment(event.equipment) then
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
local itemPrototypes = game.item_prototypes
local function genRequests()

	function getFilterSafe(invent, slotIndex)
		if invent.is_filtered() then
			return invent.get_filter(slotIndex)
		end
		return nil
	end

	local requestList = {
	}

	local function newRequestFromItemStack(requests, itemStack, slotFilter, i) --i = for entity.unit_number
		local iS = {}
		if itemStack.valid_for_read then
			iS = { item = itemStack, name = itemStack.name, count = itemStack.count, max = itemStack.prototype.stack_size }
		else
			iS = { item = itemStack, name = slotFilter, count = 0, max = itemPrototypes[slotFilter].stack_size, set = itemStack.can_set_stack(slotFilter) }
		end
		if iS.count < iS.max then
			local needed = iS.max - iS.count

			if not requests[iS.name] then
				requests[iS.name] = { stacks = { { item = iS, source_unit_number = i.entity.unit_number, needed = needed, factor = needed / iS.max } }, totalNeeded = iS.max - iS.count }
			else
				requests[iS.name].totalNeeded = requests[iS.name].totalNeeded + (iS.max - iS.count)
				requests[iS.name].stacks[#requests[iS.name].stacks + 1] = { item = iS, source_unit_number = i.entity.unit_number, needed = needed, factor = needed / iS.max }
			end
		end
		return requests
	end

	for _, i in pairs(floofTubes.inventories) do
		if i.fill and i.entity.valid then

			local counts = {}

			for _, itemName in pairs(i.config.fill.internalFilter) do
				if itemName ~= "_blank_" then
					if counts[itemName] then
						counts[itemName].needed = counts[itemName].needed + counts[itemName].prototype.stack_size
					else
						counts[itemName] = { name = itemName, prototype = itemPrototypes[itemName], needed = itemPrototypes[itemName].stack_size }
					end
				end
			end

			if i.config.fill.onlyFilteredSlots and i.inventory.is_filtered() or i.config.fill.onlyInternalFilter then
				if not requestList[i.entity.train.id] then
					requestList[i.entity.train.id] = {}
				end
				requests = requestList[i.entity.train.id]
				local invent = i.inventory
				for slotIndex = 1, #invent do
					local itemStack = invent[slotIndex]
					local slotFilter = getFilterSafe(invent, slotIndex) or nil

					if i.config.fill.onlyInternalFilter and (not i.config.fill.onlyFilteredSlots and slotFilter == nil or i.config.fill.onlyFilteredSlots) and itemStack.valid_for_read then
						if counts[itemStack.name] then
							local countItem = counts[itemStack.name]
							if itemStack.count < itemStack.prototype.stack_size then
								if not countItem.stacks then
									countItem.stacks = { itemStack }
								else
									countItem.stacks[#countItem.stacks + 1] = itemStack
								end
							end
							countItem.needed = countItem.needed - itemStack.count
							if countItem.needed <= 0 then
								counts[itemStack.name] = nil
							end
						end
					end

					if i.config.fill.onlyFilteredSlots and slotFilter ~= nil and itemStack.valid then
						newRequestFromItemStack(requests, itemStack, slotFilter, i)
					end
				end

				if i.config.fill.onlyInternalFilter then

					local reserved = {}

					function getEmptySlotNotReserved(name)
						for slotIndex = 1, #invent do
							if not reserved[slotIndex] then
								local slot = invent[slotIndex]
								local unfiltered = getFilterSafe(invent, slotIndex) == nil and not i.config.fill.onlyFilteredSlots
								local filtered = name and (getFilterSafe(invent, slotIndex) == name or getFilterSafe(invent, slotIndex) == nil) and i.config.fill.onlyFilteredSlots
								if (unfiltered or filtered) and not slot.valid_for_read then
									reserved[slotIndex] = true
									return slot
								end
							end
						end
						return nil
					end

					for k, v in pairs(counts) do
						local emptyStack
						while v.needed > 0 do
							if v.stacks then
								emptyStack = v.stacks[1]
								v.stacks[1] = nil
							elseif i.config.fill.onlyFilteredSlots then
								emptyStack = getEmptySlotNotReserved(v.name)
							else
								emptyStack = getEmptySlotNotReserved()
							end
							if emptyStack ~= nil then
								newRequestFromItemStack(requests, emptyStack, v.name, i)
								v.needed = v.needed - ((emptyStack.valid_for_read and emptyStack.count) or v.prototype.stack_size)
							else
								v.needed = -1 --no space!
							end
						end
					end
				end
			end
		end
		if not i.entity.valid then
			floofTubes.inventories[_] = nil
		end
	end
	local aaa = "aaa"
	--fUtil.debug(aaa, "aaa")
	return requestList
end

local function calc(available, needed, totalNeeded, max)
	max = max or 50
	if available >= totalNeeded then
		local factor = needed / max
		return factor / (available / max) * available
	else
		return ((available / totalNeeded) * totalNeeded) * (needed / totalNeeded)
	end

end

local function processRequests(requestList)

	local function inInternalFilter(internalFilter, internalKey)
		for _, itemName in pairs(internalFilter) do
			if itemName == internalKey then
				return true
			end
		end
		return false
	end

	function getValidItemCount(key, i, invent)

		local totalCount = 0
		local filteredSlots = i.config.pull.onlyFilteredSlots
		local filteredInternal = i.config.pull.onlyInternalFilter
		for slotIndex = 1, #invent do
			local slot = invent[slotIndex]
			if slot.valid_for_read and slot.name == key then
				local a = (filteredSlots and getFilterSafe(invent,slotIndex) == key and not filteredInternal)
				local b = (filteredInternal and inInternalFilter(i.config.pull.internalFilter, key) and not filteredSlots)
				local c = (not filteredInternal and not filteredSlots) and getFilterSafe(invent,slotIndex) == nil
				local d = (filteredInternal and filteredSlots) and (inInternalFilter(i.config.pull.internalFilter, key) or getFilterSafe(invent,slotIndex) == key)
				if (a or b or c or d) then
					totalCount = totalCount + slot.count
				end
			end
		end
		return totalCount
	end

	function removeValidItems(key, amount, i, invent)

		local filteredSlots = i.config.pull.onlyFilteredSlots
		local filteredInternal = i.config.pull.onlyInternalFilter
		for slotIndex = 1, #invent do
			local slot = invent[slotIndex]
			if slot.valid_for_read and slot.name == key and slot.count ~= 0 then
				local a = (filteredSlots and getFilterSafe(invent,slotIndex) == key and not filteredInternal)
				local b = (filteredInternal and inInternalFilter(i.config.pull.internalFilter, key) and not filteredSlots)
				local c = (not filteredInternal and not filteredSlots) and getFilterSafe(invent,slotIndex) == nil
				local d = (filteredInternal and filteredSlots) and (inInternalFilter(i.config.pull.internalFilter, key) or getFilterSafe(invent,slotIndex) == key)
				if (a or b or c or d) then

					if slot.count > amount then
						slot.count = slot.count - amount
						amount = 0
					else
						amount = amount - slot.count
						slot.clear()
					end
					if amount == 0 then return end
				end
			end
		end
	end

	if not requestList then return end
	for _, i in pairs(floofTubes.inventories) do
		if i.entity and i.entity.valid and i.pull and requestList[i.entity.train.id] then
			local requests = requestList[i.entity.train.id]
			for requestKey, request in pairs(requests) do
				for _, stack in pairs(request.stacks) do
					if i.entity.unit_number ~= stack.source_unit_number then
						local invent = i.inventory
						local requestCount = getValidItemCount(requestKey, i, invent) -- invent.get_item_count(requestKey)
						if requestCount ~= 0 then
							local amount = 0
							if requestCount >= request.totalNeeded then -- has more then/equal needed
								amount = stack.needed

							else -- has less than needed
								amount = math.ceil(calc(requestCount, stack.needed, request.totalNeeded))
							end
							local amountToAdd = amount
							if stack.item.count ~= 0 then
								amountToAdd = stack.item.item.count + amount
							end
							local canSet = stack.item.item.can_set_stack({ name = requestKey, count = amountToAdd })
							if canSet then
								request.totalNeeded = request.totalNeeded - amount
								stack.item.item.set_stack({ name = requestKey, count = amountToAdd })
								removeValidItems(requestKey, amount, i, invent) --invent.remove({ name = requestKey, count = amount })
							end
						end



					end
				end
			end
		end
	end
end

local function on_tick(event)

	if event.tick % 300 == 0 then
		local requests = genRequests()
		processRequests(requests)
	end
	if event.tick % 30 == 0 then
		for _, i in pairs(floofTubes.players) do
			if i.gui.tubeConfigWindow and i.gui.tubeConfigWindow.base ~= nil and i.gui.tubeConfigWindow.base.valid then
				i.gui.tubeConfigWindow.base.bring_to_front()
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

	script.on_event(defines.events.on_tick, on_tick)

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

local function on_configuration_changed(event)
	if not floofTubes.players then
		floofTubes.players = {}
	end

end

script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)

script.on_init(on_init)