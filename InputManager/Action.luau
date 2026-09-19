local Types = require(script.Parent.Types)
local Helper = require(script.Parent.Helper)
local Signal = require(script.Parent.Signal)

local Action = {}
Action.__index = Action

function Action.new(config: Types.ActionConfig, name: string, manager: Types.Manager): Types.Action

	if not name or typeof(name) ~= "string" then return end
	if not manager then return end
	config = (config and typeof(config) == "table") and config or {}

	local self = setmetatable({} :: Types.Action, Action)

	self.Active = if config.Active ~= nil then config.Active else true
	self.UserData = config.UserData

	self.Name = name 
	self.Manager = manager


	self.Triggered = Signal.new()
	self.Disabled = Signal.new()
	self.Activated = Signal.new()
	self.KeyAdded = Signal.new()
	self.KeyRemoved = Signal.new()

	return self
end

function Action:Destroy()
	local self = self :: Types.Action
	local manager = self.Manager

	if not manager then
		return
	end

	if manager.ActionList[self.Name] ~= self then
		return
	end

	local name = self.Name
	local userData = self.UserData

	for key in pairs(manager.ActionToKey[name]) do
		if manager.KeyToAction[key] == name then
			manager.KeyToAction[key] = nil
		end
	end

	manager.ActionToKey[name] = nil
	manager.ActionList[name] = nil

	self.Triggered:Destroy()
	self.Disabled:Destroy()
	self.Activated:Destroy()
	self.KeyAdded:Destroy()
	self.KeyRemoved:Destroy()

	self.Manager = nil
	setmetatable(self, nil)
	
	manager.ActionRemoved:Fire(name, userData)
end

function Action:Activate()

	local self = self :: Types.Action

	local manager = self.Manager

	if not manager then return end

	if self.Active then return end

	self.Active = true

	self.Activated:Fire()

end

function Action:Disable()
	local self = self :: Types.Action

	local manager = self.Manager

	if not manager then return end

	if not self.Active then return end

	self.Active = false

	self.Disabled:Fire()

end

function Action:AddKey(key: Types.InputKey | InputObject)
	local self = self :: Types.Action

	local manager = self.Manager

	if not manager then return end

	key = Helper.NormalizeKey(key)

	if not key then warn("invalid key") return end

	if manager.Blacklist[key] then warn("key is blacklisted") manager.BlacklistKeyStopped:Fire(key, self.Name, "action") return end

	if manager.KeyToAction[key] then warn("key already binded to an action globaly")

		return

	end

	manager.ActionToKey[self.Name][key] = true
	manager.KeyToAction[key] = self.Name

	self.KeyAdded:Fire(key)

end

function Action:RemoveKey(key: Types.InputKey | InputObject)
	local self = self :: Types.Action

	local manager = self.Manager

	if not manager then return end

	key = Helper.NormalizeKey(key)

	if not key then warn("invalid key") return end

	if not manager.KeyToAction[key] then warn("key is not existed") return end

	if manager.KeyToAction[key] ~= self.Name then
		warn("key is not binded to this action")
		return
	end

	manager.ActionToKey[self.Name][key] = nil
	manager.KeyToAction[key] = nil

	self.KeyRemoved:Fire(key)

end

function Action:HasKey(key: Types.InputKey): boolean
	local self = self :: Types.Action

	local manager = self.Manager

	if not manager then return false end

	key = Helper.NormalizeKey(key)

	local result = false

	result = manager.ActionToKey[self.Name][key] ~= nil

	return result

end

function Action:GetKey(): {Types.InputKey}?
	local self = self :: Types.Action

	local manager = self.Manager

	if not manager then return end

	return Helper.DictToArray(manager.ActionToKey[self.Name])

end

return Action