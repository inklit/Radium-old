local termutils = require "termutils"

local data = {
	{"hello", "this", "is", "a", "test"},
	{"of", "the", "termutils", "lib"},
	{"with", "a", "very", "long", "lineeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"}
}

termutils.table(data)