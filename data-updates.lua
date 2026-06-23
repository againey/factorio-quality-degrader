local degrading = require("__quality-degrader__/degrading")

for name, recipe in pairs(data.raw.recipe) do
	degrading.generate_degrading_recipe(recipe)
end
