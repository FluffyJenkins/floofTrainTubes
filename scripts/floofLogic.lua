local floofLogic = {
    aaaaaaaaaaaaaaa = false,
    floofTubes = {}
}

function floofLogic.processFills()
end


function getFilterSafe(invent, slotIndex)
    if invent.is_filtered() then
        return invent.get_filter(slotIndex)
    end
    return nil
end

function calc(available, needed, totalNeeded, max)
	max = max or 50
	if available >= totalNeeded then
		local factor = needed / max
		return factor / (available / max) * available
	else
		return ((available / totalNeeded) * totalNeeded) * (needed / totalNeeded)
	end
end



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
            local a = (filteredSlots and getFilterSafe(invent, slotIndex) == key and not filteredInternal)
            local b = (filteredInternal and inInternalFilter(i.config.pull.internalFilter, key) and not filteredSlots)
            local c = (not filteredInternal and not filteredSlots) and getFilterSafe(invent, slotIndex) == nil
            local d = (filteredInternal and filteredSlots) and (inInternalFilter(i.config.pull.internalFilter, key) or getFilterSafe(invent, slotIndex) == key)
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
            local a = (filteredSlots and getFilterSafe(invent, slotIndex) == key and not filteredInternal)
            local b = (filteredInternal and inInternalFilter(i.config.pull.internalFilter, key) and not filteredSlots)
            local c = (not filteredInternal and not filteredSlots) and getFilterSafe(invent, slotIndex) == nil
            local d = (filteredInternal and filteredSlots) and (inInternalFilter(i.config.pull.internalFilter, key) or getFilterSafe(invent, slotIndex) == key)
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

function floofLogic.genRequests()
	local itemPrototypes = game.item_prototypes

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

	for _, i in pairs(floofLogic.floofTubes.inventories) do
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
			floofLogic.floofTubes.inventories[_] = nil
		end
	end
	local aaa = "aaa"
	--fUtil.debug(aaa, "aaa")
	return requestList
end


function floofLogic.processRequests(requestList,requestLimiter)

	if not requestList then return end
	for _, i in pairs(floofLogic.floofTubes.inventories) do
		if i.entity and i.entity.valid and i.pull and requestList[i.entity.train.id] then
			local requests = requestList[i.entity.train.id]
			for requestKey, request in pairs(requests) do
				for _, stack in pairs(request.stacks) do
					if i.entity.unit_number ~= stack.source_unit_number then
						local invent = i.inventory
						local requestCount = getValidItemCount(requestKey, i, invent) -- invent.get_item_count(requestKey)
						requestCount = math.min(requestCount, requestLimiter)
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



return floofLogic