# Context

A context is the current input state. It lets the same key do different things at different times.

For example, `E` can interact with a door while playing normally, but select an item while an inventory is open.

## Quick example

```lua
local interact = manager:AddAction("Interact")
interact:AddKey(Enum.KeyCode.E) -- Global action

manager:AddAction("SelectItem")
manager:AddAction("CloseInventory")

local inventory = manager:AddContext("Inventory")
inventory:SetKey({
	[Enum.KeyCode.E] = "SelectItem",
	[Enum.KeyCode.Q] = "CloseInventory",
})

manager:SetContext("Inventory")
```

While `Inventory` is active, `E` triggers `SelectItem`, not `Interact`.

## Create a context

```lua
local driving = manager:AddContext("Driving", {
	GlobalFallback = false,
	Fallback = {"OnFoot"},
	UserData = {Vehicle = car},
})
```

- `GlobalFallback`: If this context does not use a key, try the global action for that key. Default: `false`.
- `Fallback`: Other contexts to try, in order, when this context does not use a key.
- `UserData`: Your own data. The system does not use it.

## Set context keys

```lua
manager:AddAction("Accelerate")
manager:AddAction("Brake")
manager:AddAction("ExitVehicle")

driving:SetKey({
	[Enum.KeyCode.W] = "Accelerate",
	[Enum.KeyCode.S] = "Brake",
	[Enum.KeyCode.F] = "ExitVehicle",
})
```

The key is the input. The value is the name of an action that already exists.

`SetKey()` replaces every old context key. To add one key, get the current list, add the key, then set it again.

```lua
local keys = driving:GetKey()
keys[Enum.KeyCode.H] = "Horn"
driving:SetKey(keys)
```

## Change the active context

```lua
manager:SetContext("Driving")

-- No active context
manager:SetContext(nil)
```

A manager has only one `CurrentContext` at a time.

## Fallback

Fallback lets contexts share controls.

```lua
local onFoot = manager:AddContext("OnFoot")
onFoot:SetKey({
	[Enum.KeyCode.Space] = "Jump",
})

local swimming = manager:AddContext("Swimming", {
	Fallback = {"OnFoot"},
})

manager:SetContext("Swimming")
```

`Swimming` does not use `Space`, so the manager tries `OnFoot`. `Jump` can still run.

Fallback order matters: the manager uses the first context with a matching key.

```lua
swimming:SetFallback({"OnFoot", "Default"})
```

## Global fallback

Global fallback is a backup for global actions.

```lua
local menu = manager:AddContext("Menu")
menu:EnableGlobalFallback()
```

If `Menu` does not use `M`, the manager tries the global action bound to `M`.

```lua
menu:DisableGlobalFallback()
```

## Check context keys

```lua
if driving:HasKey(Enum.KeyCode.W) then
	print("W is used while driving")
end

local keys = driving:GetKey()
```

`GetKey()` returns a copy. Changing it does not change the context until you call `SetKey()`.

## Context signals

- `KeyChanged(keys)`: `SetKey()` was called.
- `FallbackChanged(fallbackList)`: `SetFallback()` was called.
- `OnFallback(key, foundAction, actionName)`: This context was checked as a fallback.
- `GlobalFallbackEnabled()`: Global fallback was enabled.
- `GlobalFallbackDisabled()`: Global fallback was disabled.

```lua
onFoot.OnFallback:Connect(function(key, foundAction, actionName)
	print("Tried OnFoot:", key, foundAction, actionName)
end)
```

## Destroy a context

```lua
driving:Destroy()
```

This removes the context, its keys, and its signals from the manager.
