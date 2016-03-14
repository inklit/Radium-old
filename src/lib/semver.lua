-- lib/semver.lua
-- basic semantic versioning tools, with metatable goodness

local function isEqual(a, b)
	assert(type(a) == "table", "expected table, table")
	assert(type(b) == "table", "expected table, table")
	assert(a.major and a.minor and a.patch and a.label, "arguments should be semver objects")
	assert(b.major and b.minor and b.patch and b.label, "arguments should be semver objects")
	return a.major == b.major and a.minor == b.minor and a.patch == b.patch and a.label == b.label
end

-- returns true if a is less than b, else false
local function isLess(a, b)
	assert(type(a) == "table", "expected table, table")
	assert(type(b) == "table", "expected table, table")
	assert(a.major and a.minor and a.patch and a.label, "arguments should be semver objects")
	assert(b.major and b.minor and b.patch and b.label, "arguments should be semver objects")
	if a.major == b.major then
		if a.minor == b.minor then
			return a.patch < b.patch
		elseif a.minor < b.minor then
			return true
		end
	elseif a.major < b.major then
		return true
	end
	return false
end

-- returns true if a is less or equal to b, else false
local function isLessOrEqual(a, b)
	assert(type(a) == "table", "expected table, table")
	assert(type(b) == "table", "expected table, table")
	assert(a.major and a.minor and a.patch and a.label, "arguments should be semver objects")
	assert(b.major and b.minor and b.patch and b.label, "arguments should be semver objects")
	return isEqual(a, b) or isLess(a, b)
end

-- converts the object to a string
local function versionToString(a)
	assert(type(a) == "table", "expected table, table")
	assert(a.major and a.minor and a.patch and a.label, "arguments should be semver objects")
	local out = "v" .. a.major .. "." .. a.minor .. "." .. a.patch
	if a.label ~= "" then
		out = out .. "-" .. a.label
	end
	return out
end

-- creates a new semantic version object
local function new(major, minor, patch, label)
	assert(type(major) == "number" or major == nil, "expected [number], [number], [number], [string]")
	assert(type(minor) == "number" or minor == nil, "expected [number], [number], [number], [string]")
	assert(type(patch) == "number" or patch == nil, "expected [number], [number], [number], [string]")
	assert(type(label) == "string" or label == nil, "expected [number], [number], [number], [string]")
	local ver = setmetatable({}, {
		__eq = isEqual,
		__lt = isLess,
		__le = isLessOrEqual,
		__tostring = versionToString,
		__call = function(t) return t end
	})
	ver.major = major or 1
	ver.minor = minor or 0
	ver.patch = patch or 0
	ver.label = label or ""
	return ver
end

return {new = new}