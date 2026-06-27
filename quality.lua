local recipes = data.raw.recipe

local quality_sequences
local function get_quality_sequences()
	if quality_sequences ~= nil then return quality_sequences end

	local qualities = data.raw.quality
	if qualities == nil then return {} end

	quality_sequences = {}

	local final_qualities = {}
	local prior_quality_map = {}

	--Step 1: Find qualities with no next quality, and build a map of prior qualities.
	for quality_name, quality_prototype in pairs(qualities) do
		if quality_prototype.next == nil then
			--helpers.write_file("quality-degrader.txt", {"", "found final quality " .. quality_name .. "\n"}, true)
			table.insert(final_qualities, quality_prototype)
		else
			--helpers.write_file("quality-degrader.txt", {"", "found link from quality " .. quality_prototype.next .. " to prior quality " .. quality_name .. "\n"}, true)
			prior_quality_map[quality_prototype.next] = quality_prototype
		end
	end

	--Step 2: For each final quality, walk back along prior qualities to build the full sequence.
	for _, final_quality_prototype in ipairs(final_qualities) do
		local quality_sequence = { final_quality_prototype }
		local prior_quality_prototype = prior_quality_map[final_quality_prototype.name]
		while prior_quality_prototype ~= nil do
			table.insert(quality_sequence, 1, prior_quality_prototype)
			prior_quality_prototype = prior_quality_map[prior_quality_prototype.name]
		end
		quality_sequences[quality_sequence[1].name] = quality_sequence

		--helpers.write_file("quality-degrader.txt", {"", "Quality sequence:\n"}, true)
		--for _, quality_prototype in ipairs(quality_sequence) do
		--	helpers.write_file("quality-degrader.txt", {"", "\t" .. quality_prototype.name .. "(" .. quality_prototype.level .. ")\n"}, true)
		--end
	end

	return quality_sequences
end


local root_quality_technologies = nil
local function get_root_quality_technologies()
	if root_quality_technologies ~= nil then return root_quality_technologies end

	local technologies = data.raw.technology
	local qualities = data.raw.quality
	if technologies == nil or qualities == nil then return {} end

	--Step 1: Find all technologies that unlock a quality above level 0.
	local quality_technologies = {}
	for technology_name, technology_prototype in pairs(technologies) do
		if technology_prototype.effects ~= nil then
			for _, effect in ipairs(technology_prototype.effects) do
				if effect.type == "unlock-quality" then
					local quality_prototype = qualities[effect.quality]
					if quality_prototype ~= nil and quality_prototype.level > 0 then
						quality_technologies[technology_name] = technology_prototype
						break
					end
				end
			end
		end
	end

	--Step 2: Determine which quality techs have at least one other quality tech as a prerequisite.
	local technology_states = {} --tech_name: true if is downstream from quality tech; tech_name: false if not
	local function is_downstream_from_quality_technology(technology_prototype)
		if technology_prototype.prerequisites ~= nil then
			for _, prerequisite in ipairs(technology_prototype.prerequisites) do
				local state = technology_states[prerequisite]
				if state ~= nil then
					return state
				elseif quality_technologies[prerequisite] ~= nil then
					technology_states[prerequisite] = true
					return true
				else
					state = is_downstream_from_quality_technology(technologies[prerequisite])
					technology_states[prerequisite] = state
					return state
				end
			end
		end
		return false
	end

	--Step 3: Take only the quality techs that have no other quality tech as a prerequisite.
	root_quality_technologies = {}
	for technology_name, technology_prototype in pairs(quality_technologies) do
		if is_downstream_from_quality_technology(technology_prototype) == false then
			table.insert(root_quality_technologies, technology_prototype)
		end
	end
	
	return root_quality_technologies
end

local lib = {}

lib.get_quality_sequences = get_quality_sequences
lib.get_root_quality_technologies = get_root_quality_technologies

return lib
