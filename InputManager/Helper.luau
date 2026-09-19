local Helper = {}
local Types = require(script.Parent.Types)

function Helper.ResolveInput(inputObject: InputObject): Types.InputKey?
	if typeof(inputObject) ~= "Instance"
		or not inputObject:IsA("InputObject")
	then
		return
	end

	local inputType = inputObject.UserInputType

	if inputType == Enum.UserInputType.MouseWheel then
		if inputObject.Position.Z > 0 then
			return "mouse_wheel_up"
		elseif inputObject.Position.Z < 0 then
			return "mouse_wheel_down"
		end

		return
	end

	if inputType == Enum.UserInputType.Keyboard then
		return inputObject.KeyCode
	end

	return inputType
end


function Helper.KeyValidation(key: Types.InputKey): boolean
	if typeof(key) == "EnumItem" then
		return key.EnumType == Enum.KeyCode
			or key.EnumType == Enum.UserInputType
	end

	if key == "mouse_wheel_up" or key == "mouse_wheel_down" then
		return true
	end

	return false
end

function Helper.NormalizeKey(key: Types.InputKey | InputObject): Types.InputKey?

	if not key then return end

	if typeof(key) == "Instance" and key:IsA("InputObject") then
		key = Helper.ResolveInput(key)
	else
		key = Helper.KeyValidation(key) and key or nil
	end

	return key

end

function Helper.ArrayToDict(t: {any}, customValue: any): ({[any]: any})

	customValue = (customValue ~= nil) and customValue or true

	if typeof(t) ~= "table" then return end

	local new = {}

	for i, v in pairs(t) do

		new[v] = customValue

	end

	return new

end

function Helper.DictToArray(t: {[any]: any}): {any}

	if typeof(t) ~= "table" then return end

	local new = {}

	for i, v in pairs(t) do

		table.insert(new, i)

	end

	return new

end



return Helper