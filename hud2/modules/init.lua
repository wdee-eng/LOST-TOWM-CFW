QBCore = exports['qb-core']:GetCoreObject(), exports['qb-core']:GetCoreObject()

function Load(name)
	local resourceName = GetCurrentResourceName()
	local chunk = LoadResourceFile(resourceName, ('modules/%s.lua'):format(name))
	if chunk then
		local err
		chunk, err = load(chunk, ('@@%s/modules/%s.lua'):format(resourceName, name), 't')
		if err then
			error(('\n^1 %s'):format(err), 0)
		end
		return chunk()
	end
end