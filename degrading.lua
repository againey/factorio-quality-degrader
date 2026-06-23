local recipes = data.raw.recipe

local function generate_degrading_recipe_icons_from_item(item)
	local icons = {}
	if item.icons == nil then
		icons =
		{
			{
				icon = item.icon,
				--icon_size = item.icon_size,
				--scale = (0.5 * defines.constant.default_icon_size / (item.icon_size or defines.constant.default_icon_size)) * 0.8,
			},
			{
				icon = "__quality-degrader__/graphics/icons/degrading.png",
			},
		}
	else
		icons = {}
		for i = 1, #item.icons do
			--local icon = table.deepcopy(item.icons[i]) -- we are gonna change the scale, so must copy the table
			--icon.scale = ((icon.scale == nil) and (0.5 * defines.constant.default_icon_size / (icon.icon_size or defines.constant.default_icon_size)) or icon.scale) * 0.8
			--icon.shift = util.mul_shift(icon.shift, 0.8)
			--icons[#icons + 1] = icon
			icons[#icons + 1] = item.icons[i]
		end
		icons[#icons + 1] =
		{
			icon = "__quality-degrader__/graphics/icons/degrading.png",
		}
	end
	return icons
end

local function is_recycling_recipe(recipe)
	if recipe.categories == nil then return false end
	for _, category in ipairs(recipe.categories) do
		if category == "recycling" then return true end
	end
	return false
end

local function default_can_degrade_recipe(recipe)
	if is_recycling_recipe(recipe) == false then return false end
	return true
end

local function default_can_degrade_item(item)
	if item.flags ~= nil and item.flags["only-in-cursor"] then return false end
	return true
end

local function get_recipe_ingredient_item(recipe)
	if #recipe.ingredients ~= 1 then return false end
	local ingredient = recipe.ingredients[1]
	if ingredient.type ~= "item" then return false end

	return data.raw.item[ingredient.name]
end

local function get_prototype(base_type, name)
	for type_name in pairs(defines.prototypes[base_type]) do
		local prototypes = data.raw[type_name]
		if prototypes and prototypes[name] then
			return prototypes[name]
		end
	end
end

local function get_item_localised_name(item_name)
	local item = get_prototype("item", item_name)
	if item == nil then return end
	if item.localised_name ~= nil then
		return item.localised_name
	end

	local prototype
	local type_name = "item"
	if item.place_result ~= nil then
		prototype = get_prototype("entity", item.place_result)
		type_name = "entity"
	elseif item.place_as_equipment_result ~= nil then
		prototype = get_prototype("equipment", item.place_as_equipment_result)
		type_name = "equipment"
	elseif item.place_as_tile ~= nil then
		-- Tiles with variations don't have a localised name
		local tile_prototype = data.raw.tile[item.place_as_tile.result]
		if tile_prototype ~= nil and tile_prototype.localised_name ~= nil then
			prototype = tile_prototype
			type_name = "tile"
		end
	end

	if prototype ~= nil and prototype.localised_name ~= nil then
		return prototype.localised_name
	else
		return { type_name .. "-name." .. item_name }
	end
end

local function get_recipe_percent_spoiled_for_item(item)
	if item.spoil_ticks == nil or item.spoil_ticks == 0 then
		return nil
	else
		return 0.8
	end
end

local function get_quality_module_technology_effects()
	local technologies = data.raw.technology
	if technologies == nil then return nil end
	local quality_module_technology = technologies["quality-module"]
	if quality_module_technology == nil then return nil end
	return quality_module_technology.effects
end

local quality_module_technology_effects = get_quality_module_technology_effects()
local function add_degrading_recipe_unlock(recipe)
	if quality_module_technology_effects == nil then
		recipe.enabled = true
		return
	end
	table.insert(quality_module_technology_effects, { type = "unlock-recipe", recipe = recipe.name, hidden = true })
end

local function get_first_quality_prototype_with_level(quality_level)
	if data.raw.quality == nil then return nil end
	for _, quality_prototype in pairs(data.raw.quality) do
		if quality_prototype.level == quality_level then
			return quality_prototype
		end
	end
end

local function get_better_quality_prototype(quality_prototype, change)
	if quality_prototype == nil or data.raw.quality == nil then return nil end

	if change == nil then
		while quality_prototype.next ~= nil do
			quality_prototype = data.raw.quality[quality_prototype.next]
		end
	else
		while change > 0 do
			if quality_prototype.next == nil then return nil end
			quality_prototype = data.raw.quality[quality_prototype.next]
			change = change - 1
		end
	end

	return quality_prototype
end

local function get_one_level_worse_quality_prototype(quality_prototype)
	if quality_prototype == nil or data.raw.quality == nil then return nil end

	for _, other_quality_prototype in pairs(data.raw.quality) do
		if other_quality_prototype.next == quality_prototype.name then
			return other_quality_prototype
		end
	end

	return nil
end

local function count_quality_levels(first_quality_prototype, last_quality_prototype)
	if first_quality_prototype == nil or data.raw.quality == nil then return 0 end

	local count = 1
	local quality_prototype = first_quality_prototype
	while quality_prototype.next ~= nil do
		quality_prototype = data.raw.quality[quality_prototype.next]
		if quality_prototype == nil then return count end
		count = count + 1
		if quality_prototype == last_quality_prototype then return count end
	end

	return count
end

local second_level_quality_prototype = get_first_quality_prototype_with_level(1)
local first_level_quality_prototype = get_one_level_worse_quality_prototype(second_level_quality_prototype)
local last_level_quality_prototype = get_better_quality_prototype(second_level_quality_prototype)
local next_to_last_level_quality_prototype = get_one_level_worse_quality_prototype(last_level_quality_prototype)

local function generate_degrading_recipe_for_item(item, recipe, can_degrade_item)
	--helpers.write_file("quality-degrader.txt", {"", "Considering item " .. item.name .. "\n"}, true)

	local can_degrade_item = can_degrade_item or default_can_degrade_item
	if can_degrade_item(item) == false then return end

	--helpers.write_file("quality-degrader.txt", {"", "Creating recipe " .. item.name .. "-degrading\n"}, true)

	local degrading_recipe =
	{
		type = "recipe",
		name = item.name .. "-degrading",
		localised_name = {"recipe-name.degrading", get_item_localised_name(item.name)},
		icon = nil,
		icons = generate_degrading_recipe_icons_from_item(item),
		subgroup = item.subgroup,
		categories = {"quality-degrading"},
		can_set_quality = true,
		ingredients =
		{
			{
				type = "item",
				name = item.name,
				amount = 1,
				quality_min = second_level_quality_prototype.name,
				quality_max = last_level_quality_prototype.name,
			},
		},
		results =
		{
			{
				type = "item",
				name = item.name,
				amount = 1,
				quality_min = first_level_quality_prototype.name,
				quality_max = next_to_last_level_quality_prototype.name,
				quality_change = -1,
				percent_spoiled = get_recipe_percent_spoiled_for_item(item),
			},
		},
		main_product = item.name,
		energy_required = 0.25,
		crafting_machine_tint = recipe.crafting_machine_tint,
		auto_recycle = false,
		enabled = false,
		hidden = true,
		unlock_results = false,
		hide_from_player_crafting = true,
		hide_from_bonus_gui = true,
		allow_decomposition = false,
		allow_as_intermediate = false,
		allow_intermediates = false,
		allow_consumption = false,
		allow_speed = false,
		allow_productivity = false,
		allow_pollution = false,
		allow_quality = false,
	}

	add_degrading_recipe_unlock(degrading_recipe)
	data:extend({degrading_recipe})
end

local function generate_degrading_recipe_for_recipe(recipe, can_degrade_recipe, can_degrade_item)
	if second_level_quality_prototype == nil then return end

	--helpers.write_file("quality-degrader.txt", {"", "Considering recipe " .. recipe.name .. "\n"}, true)
	local can_degrade_recipe = can_degrade_recipe or default_can_degrade_recipe
	if not can_degrade_recipe(recipe) then return end

	local item = get_recipe_ingredient_item(recipe)
	if item ~= nil then
		generate_degrading_recipe_for_item(item, recipe, can_degrade_item)
	end
end

local lib = {}

lib.get_first_quality_prototype_with_level = get_first_quality_prototype_with_level
lib.get_better_quality_prototype = get_better_quality_prototype
lib.get_one_level_worse_quality_prototype = get_one_level_worse_quality_prototype
lib.count_quality_levels = count_quality_levels
lib.generate_degrading_recipe = generate_degrading_recipe_for_recipe

return lib
