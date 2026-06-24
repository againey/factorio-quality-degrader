for force_name, force in pairs(game.forces) do
	for quality_name, quality_prototype in pairs(prototypes.quality) do
		if quality_prototype.level > 0 and force.is_quality_unlocked(quality_name) then
			for recipe_name, recipe in pairs(force.recipes) do
				if recipe.has_category("quality-degrading") then
					--recipe.enabled = true
				end
			end
			break
		end
	end
end
