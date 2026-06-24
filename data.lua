--helpers.write_file("quality-degrader.txt", {"", "----------------------------------------\n"})

require ("util")
local entity_sounds = require("__base__.prototypes.entity.sounds")
local item_sounds = require("__base__.prototypes.item_sounds")
local hit_effects = require ("__base__.prototypes.entity.hit-effects")

local degrading = require("__quality-degrader__/degrading")

local burner_mining_drill_entity_prototype = data.raw["mining-drill"]["burner-mining-drill"]

local degrader_tint = {r=1.0, g=0.8, b=0.6}
local degrader_ground_tint = {r=1, g=1, b=1}

local function apply_tint_to_graphic_set(graphic_set, tint)
	if graphic_set.animation ~= nil then
		for _, animation_direction in pairs(graphic_set.animation) do
			if animation_direction.layers ~= nil then
				for _, layer in ipairs(animation_direction.layers) do
					if string.match(layer.filename, "-shadow.png") == nil then
						layer.tint = tint
					end
				end
			end
		end
	end

	return graphic_set
end

local function insert_layer_in_graphic_set(graphic_set, layer, index)
	if graphic_set.animation ~= nil then
		for _, animation_direction in pairs(graphic_set.animation) do
			local layer_copy = table.deepcopy(layer)
			if animation_direction.layers ~= nil then
				local frame_count = animation_direction.layers[1].frame_count or 1
				if animation_direction.layers[1].run_mode == "forward-then-backward" then
					frame_count = frame_count * 2 - 2
				end
				layer_copy.frame_count = frame_count
				if layer_copy.frame_count > 1 then
					layer_copy.frame_sequence = {}
					while #layer_copy.frame_sequence < layer_copy.frame_count do
						table.insert(layer_copy.frame_sequence, 1)
					end
				end
				table.insert(animation_direction.layers, index, layer_copy)
			else
				layer_copy.frame_count = 1
				animation_direction.layers = {layer_copy}
			end
		end
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
		order = "d[quality-degrader]",
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
		type = "corpse",
		name = "degrader-remnants",
		icons =
		{
			{
				icon = "__base__/graphics/icons/burner-mining-drill.png",
				tint = degrader_tint,
			},
		},
		flags = {"placeable-neutral", "not-on-map"},
		hidden_in_factoriopedia = true,
		subgroup = "smelting-machine-remnants",
		order = "e[quality-degrader]",
		collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
		selection_box = {{-1, -1}, {1, 1}},
		tile_width = 2,
		tile_height = 2,
		selectable_in_game = false,
		time_before_removed = 60 * 60 * 15, -- 15 minutes
		expires = false,
		final_render_layer = "remnants",
		remove_on_tile_placement = false,
		animation =
		{
			filename = "__base__/graphics/entity/burner-mining-drill/remnants/burner-mining-drill-remnants.png",
			line_length = 1,
			width = 272,
			height = 234,
			direction_count = 1,
			shift = util.by_pixel(-0.5, -4.5),
			scale = 0.5,
			tint = degrader_tint,
		},
	},
	{
		type = "furnace",
		name = "degrader",
		icons =
		{
			{
				icon = "__base__/graphics/icons/burner-mining-drill.png",
				tint = degrader_tint,
			},
		},
		flags = {"placeable-neutral", "placeable-player", "player-creation"},
		fast_replaceable_group = "degrader",
		corpse = "degrader-remnants",
		minable = {mining_time = 0.2, result = "degrader"},

		crafting_categories = {"quality-degrading"},
		result_inventory_size = math.min(math.max(1, quality_count - 1), 12),
		crafting_speed = 1.0,
		source_inventory_size = 1,
		max_health = 300,
		custom_input_slot_tooltip_key = "degrader-input-slot-tooltip",
		cant_insert_at_source_message_key = "inventory-restriction.cant-be-degraded",
		vector_to_place_result = {-0.35, -1.3},
		allowed_effects = {"speed", "consumption", "pollution"},
		effect_receiver = {uses_module_effects = false, uses_beacon_effects = false, uses_surface_effects = true},
		energy_usage = "90kW",

		-- Everything below is inherited from the burner mining drill.
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
		graphics_set = insert_layer_in_graphic_set
		(
			apply_tint_to_graphic_set
			(
				table.deepcopy(burner_mining_drill_entity_prototype.graphics_set),
				degrader_tint
			),
			{
				filename = "__base__/graphics/entity/burner-mining-drill/remnants/burner-mining-drill-remnants.png",
				line_length = 1,
				width = 272,
				height = 234,
				direction_count = 1,
				shift = util.by_pixel(-0.5, -4.5),
				scale = 0.5,
				tint = degrader_ground_tint,
			},
			1
		),
		graphics_set_flipped = insert_layer_in_graphic_set
		(
			apply_tint_to_graphic_set
			(
				table.deepcopy(burner_mining_drill_entity_prototype.graphics_set_flipped),
				degrader_tint
			),
			{
				filename = "__base__/graphics/entity/burner-mining-drill/remnants/burner-mining-drill-remnants.png",
				line_length = 1,
				width = 272,
				height = 234,
				direction_count = 1,
				shift = util.by_pixel(-0.5, -4.5),
				scale = 0.5,
				tint = degrader_ground_tint,
			},
			1
		),

		circuit_connector = circuit_connector_definitions["burner-mining-drill"],
		circuit_wire_max_distance = default_circuit_wire_max_distance
	}
}

table.insert(data.raw["utility-constants"].default.factoriopedia_recycling_recipe_categories, "quality-degrading")
