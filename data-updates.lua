local quality = require("__quality-degrader__/quality")
local degrading = require("__quality-degrader__/degrading")

--Unlock the recipe to craft the degrader for all root quality techs.
local root_quality_technologies = quality.get_root_quality_technologies()
if #root_quality_technologies == 0 then
	data.raw.recipe["degrader"].enabled = true
else
	for _, technology_prototype in ipairs(root_quality_technologies) do
		local effect = { type = "unlock-recipe", recipe = "degrader", hidden = false }
		if technology_prototype.effects ~= nil then
			table.insert(technology_prototype.effects, effect)
		else
			technology_prototype.effects = {effect}
		end
	end
end

--Auto-generate degrading recipes for all recycling recipes.
for name, recipe in pairs(data.raw.recipe) do
	if degrading.is_recycling_recipe(recipe) == true then
		degrading.generate_degrading_recipes_for_recipe(recipe)
	end
end

--Update the degrader's output slot count based on the longest quality sequence.
local quality_sequences = quality.get_quality_sequences()
local longest_quality_sequence_length = 0
for _, quality_sequence in pairs(quality_sequences) do
	longest_quality_sequence_length = math.max(longest_quality_sequence_length, #quality_sequence)
end
data.raw.furnace["degrader"].result_inventory_size = math.min(math.max(1, longest_quality_sequence_length - 1), 12)
