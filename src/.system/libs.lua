-- .system/libs.lua
-- uses paths module to resolve and load libraries

local module = {}

local loaded = {}

local function loadLib(file)
	if loaded[file] then
		return loaded[file]
	else
		loaded[file] = system.require(file)
		return loaded[file]
	end
end

function module.resolve(name, workingDir)
	assert(type(name) == "string", "expected string, [string]")
	assert(workingDir == nil or type(workingDir) == "string", "expected string, [string]")
	for base in system.paths.libPath():gmatch("([^:]+)") do
		local s = base:sub(1,1)
		if not (s == "/" or s == "\\") then
			base = fs.combine(workingDir or "", base)
		end
		if fs.exists(base) and fs.isDir(base) then
			local files = fs.list(base)
			for i, file in ipairs(files) do
				for ext in system.paths.libExtensions():gmatch("([^:]+)") do
					ext = ext:gsub("%*", "(.+)")
					if file:match(ext) then
						if file:gsub(ext, "%1") == name then
							return fs.combine(base, file)
						end
					end
				end
			end
		end
	end
end

return module