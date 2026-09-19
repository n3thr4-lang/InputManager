local Types = require(script.Parent.Types)
local Helper = require(script.Parent.Helper)
local Signal = require(script.Parent.Signal)

local Context = {}
Context.__index = Context

function Context.new(config: Types.ContextConfig, name: string, manager: Types.Manager): Types.Context

	config = (config and typeof(config) == "table") and config or {}
	if not name or typeof(name) ~= "string" then return end
	if not manager then return end

	local self = setmetatable({} :: Types.Context, Context)

	self.Name = name
	self.Manager = manager

	-- exposed --
	self.UserData = config.UserData
	self.GlobalFallback = if config.GlobalFallback ~= nil then config.GlobalFallback else false

	-- container --
	self.Fallback = (config.Fallback and typeof(config.Fallback) == "table" and table.clone(config.Fallback)) or {}

	-- signals --
	self.KeyChanged = Signal.new()
	self.OnFallback = Signal.new()
	self.GlobalFallbackEnabled = Signal.new()
	self.GlobalFallbackDisabled = Signal.new()
	self.FallbackChanged = Signal.new()

	return self
end

function Context:SetFallback(fallbackList: {string})
	local self = self :: Types.Context
	if not fallbackList or typeof(fallbackList) ~= "table" then return end

	self.Fallback = table.clone(fallbackList)
	self.FallbackChanged:Fire(table.clone(fallbackList))
end

function Context:HasKey(key: Types.InputKey): boolean
	local self = self :: Types.Context

	local manager = self.Manager
	if not manager then return end

	return manager.ContextKey[self.Name][key] ~= nil

end

function Context:GetKey(): {[Types.InputKey]: string}?
	local self = self :: Types.Context
	local manager = self.Manager
	if not manager then return end
	return table.clone((manager.ContextKey[self.Name]))
end

function Context:EnableGlobalFallback()
	local self = self :: Types.Context
	self.GlobalFallback = true
	self.GlobalFallbackEnabled:Fire()
end

function Context:DisableGlobalFallback()
	local self = self :: Types.Context
	self.GlobalFallback = false
	self.GlobalFallbackDisabled:Fire()
end

function Context:SetKey(keyList: {[Types.InputKey]: string})
	local self = self :: Types.Context
	local manager = self.Manager
	if not manager then return end
	if typeof(keyList) ~= "table" then warn("invalid") return end

	local filtered = {}

	for key, action in pairs(keyList) do

		if manager.Blacklist[key] then

			manager.BlacklistKeyStopped:Fire(key, self.Name, "context")

		else

			filtered[key] = action

		end

	end

	manager.ContextKey[self.Name] = filtered
	self.KeyChanged:Fire(table.clone(filtered))
end

function Context:Destroy()
	local self = self :: Types.Context

	local manager = self.Manager
	if not manager then return end

	if manager.ContextList[self.Name] ~= self then
		return
	end

	local name = self.Name
	local userData = self.UserData

	manager.ContextKey[name] = nil

	manager.ContextList[name] = nil

	self.KeyChanged:Destroy()
	self.OnFallback:Destroy()
	self.GlobalFallbackEnabled:Destroy()
	self.GlobalFallbackDisabled:Destroy()
	self.FallbackChanged:Destroy()

	setmetatable(self, nil)
	self.Manager = nil

	manager.ContextRemoved:Fire(name, userData)

end

return Context