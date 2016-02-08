-- .system/aliases.lua
-- responsible for managing shell aliases such as 'ls' -> 'list'

local module = {}
local aliases = {}

-- sets an alias
-- will override any existing aliases!!
function module.set(alias, realPath)
	aliases[alias] = realPath
end

function module.resolve(alias)
	return aliases[alias] or alias
end

-- load default aliases
do
	local function addAliases(tbl)
		if tbl ~= nil then
			for k,v in pairs(tbl) do
				if type(k) == "string" and type(v) == "string" then
					module.set(k, v)
				end
			end
		end
	end

	if fs.exists("/etc/aliases.conf") then
		local ini = system.libs.load(system.libs.resolve("ini"))
		local data = ini.load("/etc/aliases.conf")

		addAliases(data.All)

		if term.isColour() then
			addAliases(data.Advanced)
		end

		if turtle then
			addAliases(data.Turtle)
		end

		if commands then
			addAliases(data.Command)
		end

		if http then
			addAliases(data.HTTP)
		end
	end
end

return module