-- .system/filesys.lua
-- implements the radium filesystem

local fileProvidersConfigFile = "/etc/filesystem.conf"

local fs = _G.fs

-- the providers need access to the original fs api,
-- which gets overriden by fswrapper
local ccfs = {}

for k,v in pairs(_G.fs) do
	ccfs[k] = v
end

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

function module.copy(from, to)
	local pfrom = routePath(from)
	local pto = routePath(to)

	if pfrom.id == pto.id then
		if pfrom.copy then
			-- if there is a copy function, use it
			-- it's probably faster than manual copy
			return pfrom.copy(from, to)
		end
	end

	-- fallback in case there is no copy function
	-- or the path providers differ
	local ffrom = pfrom.openFile(from, "r")
	local fto = pto.openFile(to, "w")

	fto.write(ffrom.readAll())

	ffrom.close()
	fto.close()
end

function module.move(from, to)
	local pfrom = routePath(from)
	local pto = routePath(to)

	if pfrom.id ~= pto.id then
		module.copy(from, to)
		return module.deleteFile(from)
	else
		if pfrom.move then
			return pfrom.move(from, to)
		else
			module.copy(from, to)
			return module.deleteFile(from)
		end
	end
end

-- set up the fs call routers
do
	local notImplemented = function()
		return error("function not implemented")
	end

	local providerFuncs = {
		openFile = notImplemented;
		deleteFile = notImplemented;
		exists = notImplemented;
		isDirectory = notImplemented;
		getFiles = notImplemented;
		makeDir = notImplemented;
	}

	for k,v in pairs(providerFuncs) do
		module[k] = function(path, ...)
			local provider = routePath(path)
			local func = provider[k] or v
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
				local env = setmetatable({ fs = ccfs }, { __index = _G })

				local provider, err = system.require(path, env)
				if not provider then
					printError(err)
				else
					provider.id = k
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