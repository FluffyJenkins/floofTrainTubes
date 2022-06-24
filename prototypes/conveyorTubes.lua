local recipe = {
	{
		type = "recipe",
		name = "floof:conveyorTubeOut",
		localised_name = { "floofTrainTubes.tubeFill" },
		localised_description = { "floofTrainTubes.tubeFillDesc" },
		enabled = true,
		energy_required = 10,
		ingredients =
		{
			{ "electronic-circuit", 10 },
			{ "iron-gear-wheel", 20 },
			{ "steel-plate", 20 },
		},
		result = "floof:conveyorTubeOut"
	},
	{
		type = "recipe",
		name = "floof:conveyorTubeIn",
		localised_name = { "floofTrainTubes.tubePull" },
		localised_description = { "floofTrainTubes.tubePullDesc" },
		enabled = true,
		energy_required = 10,
		ingredients =
		{
			{ "electronic-circuit", 10 },
			{ "iron-gear-wheel", 20 },
			{ "steel-plate", 20 },
		},
		result = "floof:conveyorTubeIn"
	}
}

local equipment = {
	{
		type = "battery-equipment",
		name = "floof:conveyorTubeOut",
		localised_name = { "floofTrainTubes.tubeFill" },
		localised_description = { "floofTrainTubes.tubeFillDesc" },
		take_result = "floof:conveyorTubeOut",
		sprite = {
			layers = {
				{
					filename = "__floofTrainTubes__/graphics/BG.png",
					width = 128,
					height = 128,
					priority = "medium",
				},
				{
					filename = "__floofTrainTubes__/graphics/Arrow_Out.png",
					width = 128,
					height = 128,
					shift = util.by_pixel(-32,32),
					priority = "medium",
				}
			}
		},
		shape = {
			width = 1,
			height = 1,
			type = 'full',
		},
		energy_source =
		{
			type = "electric",
			buffer_capacity = "0MJ",
			input_flow_limit = "0KW",
			output_flow_limit = "0KW",
			usage_priority = "secondary-input"
		},
		categories = { "train" },
	},
	{
		type = "battery-equipment",
		name = "floof:conveyorTubeIn",
		localised_name = { "floofTrainTubes.tubePull" },
		localised_description = { "floofTrainTubes.tubePullDesc" },
		take_result = "floof:conveyorTubeIn",
		sprite = {
			layers = {
				{
					filename = "__floofTrainTubes__/graphics/BG.png",
					width = 128,
					height = 128,
					priority = "medium",
				},
				{
					filename = "__floofTrainTubes__/graphics/Arrow_In.png",
					width = 128,
					height = 128,
					shift = util.by_pixel(-32,32),
					priority = "medium",
				}
			}
		},
		shape = {
			width = 1,
			height = 1,
			type = 'full',
		},
		energy_source =
		{
			type = "electric",
			buffer_capacity = "0MJ",
			input_flow_limit = "0KW",
			output_flow_limit = "0KW",
			usage_priority = "secondary-input"
		},
		categories = { "train" },
	}
}

local item = {
	{
		type = "item",
		name = "floof:conveyorTubeOut",
		localised_name = { "floofTrainTubes.tubeFill" },
		localised_description = { "floofTrainTubes.tubeFillDesc" },
		icons = {
			{
				icon = "__floofTrainTubes__/graphics/BG.png",
				icon_size = 128,
			},
			{
				icon = "__floofTrainTubes__/graphics/Arrow_Out.png",
				icon_size = 128,
				shift = util.by_pixel(-32,32),
			}
		},
		subgroup = "equipment",
		order = "z",

		placed_as_equipment_result = "floof:conveyorTubeOut",
		stack_size = 5,
	},
	{
		type = "item",
		name = "floof:conveyorTubeIn",
		localised_name = { "floofTrainTubes.tubePull" },
		localised_description = { "floofTrainTubes.tubePullDesc" },
		icons = {
			{
				icon = "__floofTrainTubes__/graphics/BG.png",
				icon_size = 128,
			},
			{
				icon = "__floofTrainTubes__/graphics/Arrow_In.png",
				icon_size = 128,
				shift = util.by_pixel(-32,32),
			}
		},
		subgroup = "equipment",
		order = "z",

		placed_as_equipment_result = "floof:conveyorTubeIn",
		stack_size = 5,
	}
}

local grid =
{
	type = "equipment-grid",
	name = "floof:grid",
	width = 8,
	height = 5,
	equipment_categories = { "train" }
}

data:extend(recipe)
data:extend(item)
data:extend(equipment)
data:extend(
	{
		{
			name = "floof:trainTubeTech",
			type = "technology",
			icon = "__floofTrainTubes__/graphics/BG.png",
			icon_size = 128,
			prerequisites = { "railway" },
			effects = {
				{
					type = "unlock-recipe",
					recipe = "floof:conveyorTubeOut"
				},
				{
					type = "unlock-recipe",
					recipe = "floof:conveyorTubeIn"
				}
			},
			unit = {
				count = 100,
				ingredients = {
					{ "automation-science-pack", 1 },
					{ "logistic-science-pack", 1 },
				},
				time = 30,
			},
			order = "c-g-c"
		},
		{
			type = "equipment-category",
			name = "train"
		},
		--grid,
	})
