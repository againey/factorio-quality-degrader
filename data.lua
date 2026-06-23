--helpers.write_file("quality-degrader.txt", {"", "----------------------------------------\n"})

local entity_sounds = require("__base__.prototypes.entity.sounds")
local item_sounds = require("__base__.prototypes.item_sounds")
local hit_effects = require ("__base__.prototypes.entity.hit-effects")

local degrading = require("__quality-degrader__/degrading")

local burner_mining_drill_entity_prototype = data.raw["mining-drill"]["burner-mining-drill"]

local degrader_tint = {r=0.85, g=0.75, b=0.65}

local function apply_tint_to_animation_direction(animation_direction, tint)
	if animation_direction ~= nil and animation_direction.layers ~= nil then
		for _, layer in ipairs(animation_direction.layers) do
			if string.match(layer.filename, "-shadow.png") == nil then
				layer.tint = tint
			end
		end
	end
end

local function apply_tint_to_graphic_set(graphic_set, tint)
	if graphic_set.animation ~= nil then
		for key, _ in pairs(graphic_set.animation) do
		end
		apply_tint_to_animation_direction(graphic_set.animation.north, tint)
		apply_tint_to_animation_direction(graphic_set.animation.north_east, tint)
		apply_tint_to_animation_direction(graphic_set.animation.east, tint)
		apply_tint_to_animation_direction(graphic_set.animation.south_east, tint)
		apply_tint_to_animation_direction(graphic_set.animation.south, tint)
		apply_tint_to_animation_direction(graphic_set.animation.south_west, tint)
		apply_tint_to_animation_direction(graphic_set.animation.west, tint)
		apply_tint_to_animation_direction(graphic_set.animation.north_west, tint)
	end

	return graphic_set
end

local second_level_quality_prototype = degrading.get_first_quality_prototype_with_level(1)
local quality_count = degrading.count_quality_levels(second_level_quality_prototype) + 1

data:extend{
	{
		type = "recipe-category",
		name = "quality-degrading",
	},
	{
		type = "item",
		name = "degrader",
		icons =
		{
			{
				icon = "__base__/graphics/icons/burner-mining-drill.png",
				tint = degrader_tint,
			},
		},
		subgroup = "smelting-machine",
		order = "e[degrader]",
		inventory_move_sound = item_sounds.drill_inventory_move,
		pick_sound = item_sounds.drill_inventory_pickup,
		drop_sound = item_sounds.drill_inventory_move,
		place_result = "degrader",
		stack_size = 20,
		weight = 40 * kg,
		random_tint_color = item_tints.iron_rust,
	},
	{
		type = "recipe",
		name = "degrader",
		ingredients =
		{
			{type = "item", name = "advanced-circuit", amount = 10},
			{type = "item", name = "steel-plate", amount = 40},
			{type = "item", name = "iron-gear-wheel", amount = 10},
			{type = "item", name = "stone-brick", amount = 20}
		},
		results = {{type="item", name="degrader", amount=1}},
		energy_required = 2,
		enabled = false,
	},
	{
		type = "furnace",
		name = "degrader",
		icons =
		{
			{
				icon = "__base__/graphics/icons/burner-mining-drill.png",
				tint = {r=1, g=0.5, b=0, a=0.25},
			},
		},
		flags = {"placeable-neutral", "placeable-player", "player-creation"},
		fast_replaceable_group = "degrader",
		minable = {mining_time = 0.2, result = "degrader"},

		crafting_categories = {"quality-degrading"},
		result_inventory_size = math.min(math.max(1, quality_count - 1), 12),
		crafting_speed = 1.0,
		source_inventory_size = 1,
		custom_input_slot_tooltip_key = "degrader-input-slot-tooltip",
		cant_insert_at_source_message_key = "inventory-restriction.cant-be-degraded",
		vector_to_place_result = {-0.5, -1.3},
		allowed_effects = {}, -- no beacon effects on the degrader
		energy_usage = "300kW",

		-- Everything below is inherited from the burner mining drill.
		corpse = "burner-mining-drill-remnants",
		dying_explosion = "burner-mining-drill-explosion",
		collision_box = {{-0.7, -0.7}, {0.7, 0.7}},
		selection_box = {{-1, -1}, {1, 1}},
		damaged_trigger_effect = hit_effects.entity(),
		working_sound =
		{
			sound = sound_variations("__base__/sound/burner-mining-drill", 2, 0.6, volume_multiplier("tips-and-tricks", 0.8)),
			fade_in_ticks = 4,
			fade_out_ticks = 20
		},
		open_sound = entity_sounds.drill_open,
		close_sound = entity_sounds.drill_close,
		energy_source =
		{
			type = "burner",
			fuel_categories = {"chemical"},
			effectivity = 1,
			fuel_inventory_size = 1,
			emissions_per_minute = { pollution = 12 },
			light_flicker = {color = {0,0,0}},
			smoke =
			{
				{
					name = "smoke",
					deviation = {0.1, 0.1},
					frequency = 3
				}
			}
		},
		use_mirroring = true,
		graphics_set = apply_tint_to_graphic_set(table.deepcopy(burner_mining_drill_entity_prototype.graphics_set), degrader_tint),
		graphics_set_flipped = apply_tint_to_graphic_set(table.deepcopy(burner_mining_drill_entity_prototype.graphics_set_flipped), degrader_tint),

		circuit_connector = circuit_connector_definitions["burner-mining-drill"],
		circuit_wire_max_distance = default_circuit_wire_max_distance
	}
}

--table.insert(data.raw["utility-constants"].default.factoriopedia_recycling_recipe_categories, "quality-degrading")
