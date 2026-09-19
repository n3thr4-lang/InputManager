# InputManager

`InputManager` listens for player input and triggers the matching action. Most games only need one manager for each input system.

## Quick start

```lua
local InputManager = require(path.To.InputManager)

local manager = InputManager.new({
	Blacklist = {Enum.KeyCode.Escape},
})

local jump = manager:AddAction("Jump")
jump:AddKey(Enum.KeyCode.Space)

jump.Triggered:Connect(function(state, gameProcessed)
	if state == "began" and not gameProcessed then
		print("Player jumped")
	end
end)

manager:Activate()
```

After `Activate()`, the manager listens to `UserInputService` automatically.

## Create a manager

```lua
local manager = InputManager.new(config)
```

`config` is optional.

- `UserData`: Your own data. The system does not use or change it.
- `Blacklist`: Keys that cannot be bound or triggered. Example: `{Enum.KeyCode.Escape}`.

## Actions and contexts

```lua
local action = manager:AddAction("OpenInventory")
local context = manager:AddContext("Menu")
```

An **action** is something the player can do, such as `Jump`, `Shoot`, or `OpenInventory`.

A **context** is the current input state, such as `Menu`, `Driving`, or `Building`.

Actions without a context are global actions. They work normally unless the active context uses the same key.

See `Action.md` and `Context.md` for details.

## Main methods

### `AddAction(name, config)`

Creates an action. Returns the new action, or `nil` if the name is invalid or already used.

```lua
local reload = manager:AddAction("Reload", {
	Active = true, -- true by default
	UserData = {Cooldown = 1},
})

reload:AddKey(Enum.KeyCode.R)
```

### `AddContext(name, config)`

Creates a context. Returns the new context, or `nil` if the name is invalid or already used.

```lua
local menu = manager:AddContext("Menu", {
	GlobalFallback = true,
})
```

### `GetAction(name)` and `GetContext(name)`

Get an action or context by its name.

```lua
local jump = manager:GetAction("Jump")
local menu = manager:GetContext("Menu")
```

### `SetContext(name)`

Changes the active context. Pass `nil` to clear the current context.

```lua
manager:SetContext("Menu")
manager:SetContext(nil)
```

### `SetBlacklist(keys)`

Replaces the blacklist. A blacklisted key will not trigger an action.

```lua
manager:SetBlacklist({
	Enum.KeyCode.Escape,
	Enum.KeyCode.Unknown,
})
```

Keys that were bound before are kept, but ignored while they are blacklisted.

### `Activate()` and `Disable()`

Start or stop listening for input.

```lua
manager:Activate()
manager:Disable()
```

### `TriggerKey(key, state, gameProcessed?, position?)`

Triggers a key yourself. This is useful for testing or custom input sources.

```lua
manager:TriggerKey(Enum.KeyCode.Space, "began")
manager:TriggerKey(Enum.KeyCode.Space, "ended")
```

### `TriggerAction(name, state, gameProcessed?, position?)`

Triggers an action by name. The action does not need a bound key.

```lua
manager:TriggerAction("Jump", "began")
```

### `ResolveAction(key)`

Finds the action that a key would trigger in the current context. You usually do not need this because `TriggerKey()` and `Activate()` already use it.

## Manager signals

Signals work like `RBXScriptSignal`.

```lua
manager.ActionAdded:Connect(function(actionName)
	print("Added:", actionName)
end)
```

- `ActionAdded(actionName)`: An action was created.
- `ActionRemoved(actionName, userData)`: An action was destroyed.
- `ContextAdded(contextName)`: A context was created.
- `ContextRemoved(contextName, userData)`: A context was destroyed.
- `CurrentContextChanged(newContext, oldContext)`: The active context changed.
- `BlacklistChanged(keys)`: `SetBlacklist()` was called.
- `BlacklistKeyStopped(key, name, kind)`: A blacklisted key was blocked. `kind` is `"action"` or `"context"`.
- `Activated()`: `Activate()` was called.
- `Disabled()`: `Disable()` was called.
- `ActionTriggered(...)`: An action was triggered.

`ActionTriggered` receives these arguments:

```lua
manager.ActionTriggered:Connect(function(
	actionName,
	action,
	state,          -- "began" or "ended"
	gameProcessed,  -- true when Roblox/UI already handled the input
	key,            -- nil when TriggerAction() was used
	position,
	fallbackFrom,
	fallbackedContexts
)
end)
```

## Supported keys

- `Enum.KeyCode`, for example `Enum.KeyCode.E`
- `Enum.UserInputType`, for example `Enum.UserInputType.MouseButton1`
- `"mouse_wheel_up"` and `"mouse_wheel_down"`

You can also pass an `InputObject` to methods that accept a key.

## Cleanup

When you are done with the manager, call:

```lua
manager:Destroy()
```
