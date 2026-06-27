local quality = require("__quality-degrader__/quality")

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
	return true
end

local function default_can_degrade_item(item)
	if item.flags ~= nil and item.flags["only-in-cursor"] then return false end
	return true
end

local function get_recipe_item(recipe)
	if is_recycling_recipe(recipe) then
		if #recipe.ingredients ~= 1 then return nil end
		local ingredient = recipe.ingredients[1]
		if ingredient.type ~= "item" then return nil end
		return data.raw.item[ingredient.name]
	else
		local item_result = nil
		for _, result in ipairs(recipe.results) do
			if result.type == "item" then
				if item_result ~= nil then return nil end
				item_result = result
			end
		end
		if item_result == nil then return nil end
		return data.raw.item[item_result.name]
	end
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

local function add_degrading_recipe_unlock(recipe)
	local root_quality_technologies = quality.get_root_quality_technologies()
	if #root_quality_technologies == 0 then
		recipe.enabled = true
	else
		for _, technology_prototype in ipairs(root_quality_technologies) do
			local effect = { type = "unlock-recipe", recipe = recipe.name, hidden = true }
			if technology_prototype.effects ~= nil then
				table.insert(technology_prototype.effects, effect)
			else
				technology_prototype.effects = {effect}
			end
		end
	end
end

local default_crafting_machine_tint = {primary = {0.125,0.125,0.125,0.125}, secondary = {0.125,0.125,0.125,0.125}, tertiary = {0.125,0.125,0.125,0.125}, quaternary = {0.125,0.125,0.125,0.125}}

local function generate_degrading_recipes_for_item(item, crafting_machine_tint, can_degrade_item)
	--helpers.write_file("quality-degrader.txt", {"", "Considering item " .. item.name .. "\n"}, true)

	local quality_sequences = quality.get_quality_sequences()
	if quality_sequences == nil then return end

	local has_non_trivial_quality_sequence = false
	for first_quality_name, quality_sequence in pairs(quality_sequences) do
		--helpers.write_file("quality-degrader.txt", {"", "Considering quality sequence starting from " .. first_quality_name .. " with " .. #quality_sequence .. " qualities.\n"}, true)
		if #quality_sequence > 1 then
			has_non_trivial_quality_sequence = true
			break
		end
	end
	if has_non_trivial_quality_sequence == false then return end

	local can_degrade_item = can_degrade_item or default_can_degrade_item
	if can_degrade_item(item) == false then return end

	--helpers.write_file("quality-degrader.txt", {"", "Creating recipe " .. item.name .. "-degrading\n"}, true)

	local localised_name = {"recipe-name.degrading", get_item_localised_name(item.name)}
	local icons = generate_degrading_recipe_icons_from_item(item)
	local result_percent_spoiled = get_recipe_percent_spoiled_for_item(item)
	local crafting_machine_tint = crafting_machine_tint or default_crafting_machine_tint

	local degrading_recipes = {}
	for first_quality_name, quality_sequence in pairs(quality_sequences) do
		if #quality_sequence > 1 then
			local degrading_recipe =
			{
				type = "recipe",
				name = (first_quality_name == "normal") and (item.name .. "-degrading") or (item.name .. "-degrading-" .. first_quality_name),
				localised_name = localised_name,
				icon = nil,
				icons = icons,
				subgroup = item.subgroup,
				categories = {"quality-degrading"},
				can_set_quality = true,
				ingredients =
				{
					{
						type = "item",
						name = item.name,
						amount = 1,
						quality_min = quality_sequence[2].name,
					},
				},
				results =
				{
					{
						type = "item",
						name = item.name,
						amount = 1,
						quality_change = -1,
						percent_spoiled = result_percent_spoiled,
					},
				},
				main_product = item.name,
				energy_required = 10,
				crafting_machine_tint = crafting_machine_tint,
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

			table.insert(degrading_recipes, degrading_recipe)
			add_degrading_recipe_unlock(degrading_recipe)
		end
	end

	data:extend(degrading_recipes)
end

local function generate_degrading_recipes_for_recipe(recipe, can_degrade_recipe, can_degrade_item)
	--helpers.write_file("quality-degrader.txt", {"", "Considering recipe " .. recipe.name .. "\n"}, true)
	local can_degrade_recipe = can_degrade_recipe or default_can_degrade_recipe
	if not can_degrade_recipe(recipe) then return end

	local item = get_recipe_item(recipe)
	if item == nil then return end

	generate_degrading_recipes_for_item(item, recipe.crafting_machine_tint, can_degrade_item)
end

local lib = {}

lib.is_recycling_recipe = is_recycling_recipe
lib.generate_degrading_recipes_for_item = generate_degrading_recipes_for_item
lib.generate_degrading_recipes_for_recipe = generate_degrading_recipes_for_recipe

return lib
