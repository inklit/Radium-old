-- .system/filesys.lua
-- implements the radium filesystem

local fs = _G.fs

local module = {}
local providers = {}
local paths = {}

local defaultProvider

function module.getProvider(type)
	return providers[type]
end

do
	local data = system.ini.load("/etc/fileproviders.conf")

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

				providers[k] = system.require(path, env)
			end
		end

		if data.Config then
			defaultProvider = data.Config.default
		end

		defaultProvider = defaultProvider or "hdd"
	end

	if module.getProvider(defaultProvider) == nil then
		printError("No " .. defaultProvider .. " provider found!! FS will not work!")
	end
end

return module