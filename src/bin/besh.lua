-- bin/besh.lua
-- BEtter SHell - a replacement for the CraftOS shell

local currentDir = ""
local programStack = {}

local shell = {}

function shell.dir()
	return currentDir
end

function shell.setDir(dir)
	currentDir = dir
end

function shell.run(cmd, ...)
	local resolvedCmd = shell.resolveProgram(cmd) or cmd
	if not fs.exists(resolvedCmd) then
		return false, "file not found: " .. resolvedCmd
	end

	programStack[#programStack + 1] = resolvedCmd

	local env = setmetatable({ shell = shell }, { __index = _G })
	local pid, err = system.procmgr.new(resolvedCmd, env, ...)
	
	if pid == nil and err ~= nil then
		error(err, 0)
		return false
	end

	system.procmgr.waitForExit(pid)

	return true
end

function shell.resolveProgram(program)
	local aliasResolved = system.aliases.resolve(program)
	return system.paths.resolve(
		system.paths.path(),
		system.paths.pathExtensions(),
		aliasResolved,
		currentDir
	)
end

function shell.resolve(file)
	local firstChar = file:sub(1, 1)

	if firstChar == "/" or firstChar == "\\" then
		return fs.combine("", file)
	else
		return fs.combine(currentDir, file)
	end
end

function shell.exit()
	system.procmgr.kill(__PID__)
end

function shell.path()
	return system.paths.path()
end

function shell.pathExtensions()
	return system.paths.pathExtensions()
end

function shell.setPath(path)
	return system.paths.setPath(path)
end

function shell.aliases()
	return system.aliases.list()
end

function shell.setAlias(alias, path)
	return system.aliases.set(alias, path)
end

function shell.clearAlias(alias)
	return system.aliases.set(alias, nil)
end

function shell.programs(includeHidden)
	local programs = {}

	local function hasProgram(prog)
		for _,v in pairs(programs) do
			if v == prog then
				return true
			end
		end

		return false
	end

	for path in shell.path():gmatch("([^:]+)") do
		local absPath = shell.resolve(path)
		local files = fs.list(absPath)
		for _, f in ipairs(files) do
			local fPath = fs.combine(absPath, f)
			if not fs.isDir(fPath) then
				for ext in shell.pathExtensions():gmatch("([^:]+)") do
					local ext = ext:gsub("%.", "%%."):gsub("%*", "(.+)")
					if f:match(ext) then
						local n = f:match(ext)
						if not hasProgram(n) then
							table.insert(programs, n)
						end
						break
					end
				end
			end
		end
	end

	return programs
end

function shell.getRunningProgram()
	return programStack[#programStack]
end

local shellHistory = {}

-- resolve environment variables and whatnot
local function preprocessCommand(cmd)
	-- TODO: actually do this
	return cmd
end

local function processCommand(cmd)
	local elems = {}

	for elem in cmd:gmatch("[^%s]+") do
		elems[#elems + 1] = elem
	end

	local ok, err = pcall(function()
		local success, err = shell.run(table.unpack(elems))
		if err and not success then
			printError(err)
		end
		programStack[#programStack] = nil
	end)
end

do
	local args = {...}
	if #args > 0 then
		shell.run(unpack(args))
	else
		while true do
			write(system.paths.normalise(currentDir, true) .. "$ ")

			local input = read(nil, shellHistory)
			shellHistory[#shellHistory + 1] = input

			local preprocessed = preprocessCommand(input)
			processCommand(preprocessed)
		end
	end
end