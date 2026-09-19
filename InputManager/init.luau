--service--
local uis = game:GetService("UserInputService")

local Types = require(script.Types)
local Helper = require(script.Helper)
local Signal = require(script.Signal)

--subsystem--
local ActionHandler = require(script.Action)
local ContextHandler = require(script.Context)

local InputManager = {} :: Types.InputManager
InputManager.__index = InputManager

function InputManager.new(config: Types.ManagerConfig): Types.Manager
	local self = setmetatable({} :: Types.Manager, InputManager)

	config = (config and typeof(config) == "table") and config or {}

	-- exposed --
	self.CurrentContext = nil

	-- query --
	self.ActionToKey = {}
	self.KeyToAction = {}
	self.ContextKey = {}

	-- container --
	self.ActionList = {}
	self.ContextList = {}
	self.UserData = config.UserData
	self.Blacklist = config.Blacklist and Helper.ArrayToDict(config.Blacklist) or {}
	self.Connection = {}

	-- signals --
	self.ActionAdded = Signal.new()
	self.ActionRemoved = Signal.new()
	self.Activated = Signal.new()
	self.Disabled = Signal.new()
	self.Destroying = Signal.new()


	self.ContextAdded = Signal.new()
	self.ContextRemoved = Signal.new()
	self.CurrentContextChanged = Signal.new()

	self.BlacklistChanged = Signal.new()
	self.BlacklistKeyStopped = Signal.new()
	self.ActionTriggered = Signal.new()


	self.Active = false

	return self
end

function InputManager:GetAction(actionName: string): Types.Action?
	local self = self :: Types.Manager

	return self.ActionList[actionName]

end


function InputManager:GetContext(contextName: string): Types.Context?
	local self = self :: Types.Manager

	return self.ContextList[contextName]

end


function InputManager:AddAction(actionName: string, actionConfig: Types.ActionConfig?): Types.Action?
	local self = self :: Types.Manager

	if not actionName or typeof(actionName) ~= "string" or (self.ActionList[actionName]) --[[check if action has existed]] then return end

	local newAction = ActionHandler.new(actionConfig, actionName, self)

	if not newAction then return end

	self.ActionList[actionName] = newAction

	self.ActionToKey[actionName] = {}

	self.ActionAdded:Fire(actionName)

	return newAction

end

function InputManager:AddContext(contextName: string, contextConfig: Types.ContextConfig?): Types.Context?
	local self = self :: Types.Manager

	if not contextName or typeof(contextName) ~= "string" or (self.ContextList[contextName]) then return end

	local newContext = ContextHandler.new(contextConfig, contextName, self)

	if not newContext then return end

	self.ContextKey[contextName] = {}

	self.ContextList[contextName] = newContext

	self.ContextAdded:Fire(contextName)

	return newContext

end

function InputManager:SetBlacklist(blacklist: {Types.InputKey})
	local self = self :: Types.Manager

	local blacklistConverted = Helper.ArrayToDict(blacklist)

	if not blacklistConverted then warn("invalid blacklist table") return end

	self.Blacklist = blacklistConverted
	self.BlacklistChanged:Fire(table.clone(blacklist))

end

function InputManager:ResolveAction(object: Types.InputKey | InputObject): (string?, Types.Action?, string?, {string}?)
	local self = self :: Types.Manager

	if not object then
		return
	end

	local resolvedInput

	if typeof(object) == "Instance" and object:IsA("InputObject") then
		resolvedInput = Helper.ResolveInput(object)
	else
		resolvedInput = Helper.KeyValidation(object) and object
	end

	if not resolvedInput or self.Blacklist[resolvedInput] then
		return
	end

	local currentContext = self.CurrentContext

	local actionName
	local fallbackFrom
	local onFallback
	local fallbackedContext = {}

	if currentContext then

		local existedContext = self.ContextList[currentContext]

		if not existedContext then
			return
		end

		local contextKey = self.ContextKey[currentContext]
		if not contextKey then
			return
		end

		actionName = contextKey[resolvedInput]

		if not actionName and existedContext.Fallback then
			for _, otherContextName in ipairs(existedContext.Fallback) do
				local fallbackContextKey = self.ContextKey[otherContextName]
				onFallback = self.ContextList[otherContextName] and self.ContextList[otherContextName].OnFallback or nil

				if fallbackContextKey then
					actionName = fallbackContextKey[resolvedInput]
					
				end

				table.insert(fallbackedContext, otherContextName)

				if onFallback then

					onFallback:Fire(resolvedInput, actionName and true or false, actionName)

				end

				if actionName then
					fallbackFrom = otherContextName
					break
				end
			end
		end

		if not actionName and existedContext.GlobalFallback then
			actionName = self.KeyToAction[resolvedInput]
		end

	else

		actionName = self.KeyToAction[resolvedInput]

	end

	if not actionName then
		return
	end

	local resolvedAction = self.ActionList[actionName]

	if not resolvedAction then
		return
	end

	return actionName, resolvedAction, fallbackFrom, fallbackedContext
end

function InputManager:TriggerKey(key: Types.InputKey | InputObject, state: "began" | "ended", gameProcessed: boolean?, inputPosition: Vector3?)
	local self = self :: Types.Manager

	key = Helper.NormalizeKey(key)

	if not key then warn("invalid key") return end

	if self.Blacklist[key] then
		return
	end

	if not state or typeof(state) ~= "string" or (state ~= "began" and state ~= "ended") then return end

	local actionName, action, fallbackFrom, fallbackedContext = self:ResolveAction(key)

	if not action then return end

	if not action.Active then return end

	if state == "ended" and (key == "mouse_wheel_up" or key == "mouse_wheel_down") then warn("mouse scroll event only have began state (also same for mouse move just to remind u)") return end

	gameProcessed = gameProcessed ~= nil and gameProcessed or false

	action.Triggered:Fire(state, gameProcessed, key, inputPosition, fallbackFrom, fallbackedContext)

	self.ActionTriggered:Fire(actionName, action, state, gameProcessed, key, inputPosition, fallbackFrom, fallbackedContext)

end

function InputManager:TriggerAction(actionName: string, state: "began" | "ended", gameProcessed: boolean?, inputPosition: Vector3?)
	local self = self :: Types.Manager

	local action = self.ActionList[actionName]
	if not action then return end

	action:Trigger(state, gameProcessed, inputPosition)
	
end

function InputManager:SetContext(contextName: string?)
	local self = self :: Types.Manager

	if contextName ~= nil then
		if typeof(contextName) ~= "string" then
			return
		end

		if not self.ContextList[contextName] then
			return
		end
	end

	if self.CurrentContext == contextName then
		return
	end

	local previousContext = self.CurrentContext
	self.CurrentContext = contextName

	self.CurrentContextChanged:Fire(contextName, previousContext)
end

function InputManager:Activate()
	local self = self :: Types.Manager

	if self.Active then
		return
	end

	self.Active = true

	self.Connection.Began = uis.InputBegan:Connect(function(input, gameProcessed)
		self:TriggerKey(input, "began", gameProcessed, input.Position)
	end)

	self.Connection.Changed = uis.InputChanged:Connect(function(input, gameProcessed)
		self:TriggerKey(input, "began", gameProcessed, input.Position)
	end)

	self.Connection.Ended = uis.InputEnded:Connect(function(input, gameProcessed)
		self:TriggerKey(input, "ended", gameProcessed, input.Position)
	end)

	self.Activated:Fire()
end

function InputManager:Disable()
	local self = self :: Types.Manager

	if not self.Active then return end

	self.Active = false

	if self.Connection.Began then self.Connection.Began:Disconnect() self.Connection.Began = nil end
	if self.Connection.Changed then self.Connection.Changed:Disconnect() self.Connection.Changed = nil end
	if self.Connection.Ended then self.Connection.Ended:Disconnect() self.Connection.Ended = nil end

	self.Disabled:Fire()

end

function InputManager:Destroy()
	local self = self :: Types.Manager
	
	self.Destroying:Fire()

	for _, action in pairs(self.ActionList) do

		action:Destroy()

	end

	for _, context in pairs(self.ContextList) do

		context:Destroy()

	end

	if self.Connection.Began then self.Connection.Began:Disconnect() self.Connection.Began = nil end
	if self.Connection.Changed then self.Connection.Changed:Disconnect() self.Connection.Changed = nil end
	if self.Connection.Ended then self.Connection.Ended:Disconnect() self.Connection.Ended = nil end
	
	self.ActionAdded:Destroy()
	self.ActionRemoved:Destroy()
	self.Activated:Destroy()
	self.Disabled:Destroy()
	self.Destroying:Destroy()
	self.ContextAdded:Destroy()
	self.ContextRemoved:Destroy()
	self.CurrentContextChanged:Destroy()
	self.BlacklistChanged:Destroy()
	self.BlacklistKeyStopped:Destroy()
	self.ActionTriggered:Destroy()
	
	setmetatable(self,nil)

end

return InputManager