-- .system/filesys.lua
-- implements the radium filesystem

local fileProvidersConfigFile = "/etc/filesystem.conf"

local fs = _G.fs

local module = {}
local providers = {}
local routes = {}

local defaultProvider

function module.getProvider(type)
	return providers[type]
end

function module.route(path, provider)
	assert(type(path) == "string", "path must be a string")
	assert(type(provider) == "string", "provider must be a string")
	assert(not fs.exists(path), "path already exists")

	routes[system.paths.normalise(path)] = provider
end

-- set up the fs call routers
do
	local providerFuncs = {
		"openFile";
		"deleteFile";
		"exists";
	}

	local function routePath(path)
		local npath = system.paths.normalise(path, true)
		
		for route,provider in pairs(routes) do
			route = route:gsub("%*", "%.%-")

			if npath:match(route) then
				return module.getProvider(provider)
			end
		end

		return module.getProvider(defaultProvider)
	end

	for _,v in pairs(providerFuncs) do
		module[v] = function(path, ...)
			local provider = routePath(path)
			local func = provider[v]
			return func(path, ...)
		end
	end
end

-- load file providers from the config file
do
	local data = system.ini.load(fileProvidersConfigFile)

	if data ~= nil then
		if data.Providers then
			for k,v in pairs(data.Providers) do
				local path = system.libs.resolve(v) or v
				local env = setmetatable({
					ccfs = setmetatable({}, {
						-- prevents file providers from passing
						-- around the original fs api
						__index = function(tbl, key)
							return rawget(fs, key)
						end
					})
				}, { __index = _G })

				local provider, err = system.require(path, env)
				if not provider then
					printError(err)
				else
					providers[k] = provider
				end
			end
		end

		if data.Config then
			defaultProvider = data.Config.default
		end

		defaultProvider = defaultProvider or "hdd"

		if data.Routes then
			for k,v in pairs(data.Routes) do
				module.route(v, k)
			end
		end
	end

	if module.getProvider(defaultProvider) == nil then
		printError("No " .. defaultProvider .. " provider found!! FS will not work!")
	end
end

return module