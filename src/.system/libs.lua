-- .system/libs.lua
-- uses paths module to resolve and load libraries

local module = {}

function module.resolve(name, workingDir)
	return system.paths.resolve(system.paths.libPath(), system.paths.libExtensions(), name, workingDir)
end

local loaded = {}

function module.load(file)
	if loaded[file] then
		return loaded[file]
	else
		loaded[file] = system.require(file)
		return loaded[file]
	end
end

return module