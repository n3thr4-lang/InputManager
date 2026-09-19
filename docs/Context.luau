# Context

A Context represents the current input state being used. It allows the same key to perform different actions depending on the current state.

For example, `E` can open a door during normal gameplay, but select an item while a menu is open.

## Quick Example

```lua
local interact = manager:AddAction("Interact")

interact:AddKey(Enum.KeyCode.E) -- global action

local selectItem = manager:AddAction("SelectItem")

local closeInventory = manager:AddAction("CloseInventory")

local inventory = manager:AddContext("Inventory")

inventory:SetKey({
    [Enum.KeyCode.E] = "SelectItem",
    [Enum.KeyCode.Q] = "CloseInventory",
})

manager:SetContext("Inventory")
```

When `Inventory` is the current context, `E` triggers `SelectItem` instead of `Interact`.

## Creating a Context

```lua
local driving = manager:AddContext("Driving", {
    GlobalFallback = false,
    Fallback = {"OnFoot"},
    UserData = {Vehicle = car},
})
```

| Value            | Description                                                                                      |
| ---------------- | ------------------------------------------------------------------------------------------------ |
| `GlobalFallback` | Whether to try global actions if the current context does not have the key. Defaults to `false`. |
| `Fallback`       | A list of other contexts to try, in order, when the current context does not have the key.       |
| `UserData`       | Custom data associated with the context.                                                         |

## Setting Keys for a Context

```lua
driving:SetKey({
    [Enum.KeyCode.W] = "Accelerate",
    [Enum.KeyCode.S] = "Brake",
    [Enum.KeyCode.F] = "ExitVehicle",
})
```

The key is the input, and the value is the **name of an existing action**. Create the actions first:

```lua
manager:AddAction("Accelerate")
manager:AddAction("Brake")
manager:AddAction("ExitVehicle")
```

`SetKey()` replaces the context's entire key list. To add a key, get the current list, modify it, then pass it back to `SetKey()`.

```lua
local keys = driving:GetKey()

keys[Enum.KeyCode.H] = "Horn"

driving:SetKey(keys)
```

## Switching Contexts

```lua
manager:SetContext("Driving")

-- No context is currently active
manager:SetContext(nil)
```

The manager can only have one `CurrentContext` at a time.

## Fallback

Fallbacks allow you to reuse key bindings across different contexts.

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

`Swimming` does not have a binding for `Space`, so the manager tries `OnFoot`. As a result, `Jump` still triggers.

The order of `Fallback` matters. The manager uses the first fallback context with a matching key.

You can change the fallback list after creating the context:

```lua
swimming:SetFallback({"OnFoot", "Default"})
```

## Global Fallback

Global fallback is a fallback path to global actions.

```lua
local menu = manager:AddContext("Menu")

menu:EnableGlobalFallback()
```

If `Menu` does not have a binding for `M`, the manager will try the global action bound to `M`.

Disable it again with:

```lua
menu:DisableGlobalFallback()
```

## Checking Keys

```lua
if driving:HasKey(Enum.KeyCode.W) then
    print("W is used while driving")
end

local keys = driving:GetKey()
```

`GetKey()` returns a copy of the key list, so modifying it does not change the context until you call `SetKey()`.

## Signals

| Signal                   | When it fires                       | Parameters                         |
| ------------------------ | ----------------------------------- | ---------------------------------- |
| `KeyChanged`             | `SetKey()` is called                | new key list                       |
| `FallbackChanged`        | `SetFallback()` is called           | new fallback list                  |
| `OnFallback`             | This context is tried as a fallback | `key`, `foundAction`, `actionName` |
| `GlobalFallbackEnabled`  | Global fallback is enabled          | none                               |
| `GlobalFallbackDisabled` | Global fallback is disabled         | none                               |

Example of debugging fallback behavior:

```lua
onFoot.OnFallback:Connect(function(key, foundAction, actionName)
    print("Tried OnFoot:", key, foundAction, actionName)
end)
```

## Destroying a Context

```lua
driving:Destroy()
```

The context is removed from the manager along with its key bindings and signals.
