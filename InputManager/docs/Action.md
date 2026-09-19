# Action

An action is something a player can do through input: jump, shoot, open an inventory, sprint, and so on.

## Create an action

```lua
local reload = manager:AddAction("Reload", {
	Active = true, -- true by default
	UserData = {Cooldown = 1.5},
})
```

- `Active`: Whether the action can receive input. Default: `true`.
- `UserData`: Your own data. The system does not use it.

Action names must be unique inside a manager.

## Bind and remove keys

```lua
reload:AddKey(Enum.KeyCode.R)
reload:AddKey(Enum.UserInputType.MouseButton1)

reload:RemoveKey(Enum.KeyCode.R)
```

One global key can only belong to one action. For example, if `R` is bound to `Reload`, it cannot also be bound to `OpenMap`.

Supported keys:

- `Enum.KeyCode`, such as `Enum.KeyCode.R`
- `Enum.UserInputType`, such as `Enum.UserInputType.MouseButton1`
- `"mouse_wheel_up"` or `"mouse_wheel_down"`

## Receive input

Use `Triggered` to run the action logic.

```lua
reload.Triggered:Connect(function(state, gameProcessed, key)
	if state ~= "began" or gameProcessed then
		return
	end

	print("Reloaded with", key.Name)
end)
```

`state` is either:

- `"began"`: The player pressed a key or started an input.
- `"ended"`: The player released a key or ended an input.

All `Triggered` arguments:

```lua
action.Triggered:Connect(function(
	state,
	gameProcessed,
	key,
	inputPosition,
	fallbackFrom,
	fallbackedContexts
)
end)
```

- `key` is the input that triggered the action. It is `nil` when `manager:TriggerAction()` was used.
- `inputPosition` can be useful for mouse or touch input.
- `fallbackFrom` is the fallback context that supplied the action, if any.
- `fallbackedContexts` lists the contexts that were checked.

## Enable or disable an action

```lua
reload:Disable()  -- Keeps its keys, but does not run.
reload:Activate() -- Allows it to run again.
```

## Trigger an action

```lua
reload:Trigger("began")  -- manually trigger the run by object itself
```

The current state is available as `reload.Active`.

## Check keys

```lua
if reload:HasKey(Enum.KeyCode.R) then
	print("R is bound to Reload")
end

for _, key in reload:GetKey() do
	print(key)
end
```

`GetKey()` returns a list of keys. Changing that list does not change the action; use `AddKey()` or `RemoveKey()` instead.

## Action signals

- `Triggered(state, gameProcessed, key, inputPosition, fallbackFrom, fallbackedContexts)`: The action was triggered.
- `Activated()`: `Activate()` was called.
- `Disabled()`: `Disable()` was called.
- `KeyAdded(key)`: A key was bound successfully.
- `KeyRemoved(key)`: A key was removed successfully.

```lua
reload.KeyAdded:Connect(function(key)
	print("Bound:", key)
end)
```

## Destroy an action

```lua
reload:Destroy()
```

This removes every bound key, removes the action from the manager, and destroys the action signals.
