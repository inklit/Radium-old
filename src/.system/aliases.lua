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

-- returns a read-only table of aliases
function module.list()
	local copy = {}
	
	for k,v in pairs(aliases) do
		copy[k] = v
	end

	return copy
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
		local data = system.ini.load("/etc/aliases.conf")

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