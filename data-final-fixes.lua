


if not data.raw["locomotive"]["locomotive"].equipment_grid then
    data:extend({{
        type = "equipment-grid",
        name = "floof:trainGrid",
        width = 8,
        height = 5,
        equipment_categories = { "train" }
    }})
    data.raw["locomotive"]["locomotive"].equipment_grid = data.raw["locomotive"]["locomotive"].equipment_grid or "floof:trainGrid"
    data.raw["cargo-wagon"]["cargo-wagon"].equipment_grid = data.raw["cargo-wagon"]["cargo-wagon"].equipment_grid or "floof:trainGrid"
    data.raw["fluid-wagon"]["fluid-wagon"].equipment_grid = data.raw["fluid-wagon"]["fluid-wagon"].equipment_grid or "floof:trainGrid"
    data.raw["artillery-wagon"]["artillery-wagon"].equipment_grid = data.raw["artillery-wagon"]["artillery-wagon"].equipment_grid or "floof:trainGrid"

    data.raw["cargo-wagon"]["cargo-wagon"].allow_robot_dispatch_in_automatic_mode = true
else
    local grid = data.raw["equipment-grid"][data.raw.locomotive.locomotive.equipment_grid]
    if grid and grid.equipment_categories and not grid.equipment_categories["train"] then
        table.insert(grid.equipment_categories,"train")
    end
end
