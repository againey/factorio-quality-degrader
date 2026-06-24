local degrading = require("__quality-degrader__/degrading")

local root_quality_technologies = degrading.get_all_root_quality_technologies()
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

for name, recipe in pairs(data.raw.recipe) do
	degrading.generate_degrading_recipe_for_recipe(recipe)
end
