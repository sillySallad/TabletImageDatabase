local validation = {}

function validation.isValidId(id)
	return type(id) == 'number'
		and id > 0
		and id % 1 == 0
end

function validation.isValidTag(tag)
	return type(tag) == 'string'
		and not tag:find("%s")
		and not tag:find("^[%-%+%?]")
end

return validation
