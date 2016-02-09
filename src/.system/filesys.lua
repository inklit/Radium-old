-- .system/filesys.lua
-- implements the radium filesystem

local fs = _G.fs

local module = {}
local providers = {}

function module.getProvider(type)
	return providers[type]
end

do
	local data = system.ini.load("/etc/fileproviders.conf").Providers

	if data ~= nil then
		for k,v in pairs(data) do
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
end

return module