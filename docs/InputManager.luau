# InputManager

`InputManager` receives input from the player and triggers the corresponding action. You will usually only need **one** manager for an input system.

## Quick Start

```lua
local InputManager = require(path.To.InputManager)

local manager = InputManager.new({

    -- Keys listed here will not be used.
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

After `Activate()`, the manager automatically listens for input from `UserInputService`.

## Creating a Manager

```lua
local manager = InputManager.new(config)
```

`config` is optional.

| Value       | Description                                                                                  |
| ----------- | -------------------------------------------------------------------------------------------- |
| `UserData`  | Custom data you want to attach to the manager. The library does not use or modify this data. |
| `Blacklist` | A list of keys that cannot be bound or triggered. For example: `{Enum.KeyCode.Escape}`.      |

## Actions and Contexts

```lua
local action = manager:AddAction("OpenInventory")

local context = manager:AddContext("Menu")
```

* **Action** is something that needs to be performed, such as `Jump`, `Shoot`, or `OpenInventory`.
* **Context** represents the current state, such as `Menu`, `Driving`, or `Building`.

An action without a context is a global action. It is always available unless a context assigns the same key.

See also: `docs/Action` and `docs/Context`.

## Main Methods

### `AddAction(name, config)`

Creates a new action. Returns the newly created action, or `nil` if the name is invalid or already exists.

```lua
local reload = manager:AddAction("Reload", {

    Active = true, -- true by default

    UserData = {Cooldown = 1},

})

reload:AddKey(Enum.KeyCode.R)
```

### `AddContext(name, config)`

Creates a new context. Returns the newly created context, or `nil` if the name is invalid or already exists.

```lua
local menu = manager:AddContext("Menu", {

    GlobalFallback = true,

})
```

### `GetAction(name)` and `GetContext(name)`

Retrieves an action or context by name.

```lua
local jump = manager:GetAction("Jump")

local menu = manager:GetContext("Menu")
```

### `SetContext(name)`

Changes the current context. Pass `nil` to return to having no active context.

```lua
manager:SetContext("Menu")

manager:SetContext(nil)
```

### `SetBlacklist(keys)`

Replaces the entire blacklist. Keys in the blacklist will not trigger.

```lua
manager:SetBlacklist({

    Enum.KeyCode.Escape,

    Enum.KeyCode.Unknown,

})
```

> Keys that were already bound remain in their respective mappings, but they will be ignored when triggered while they are blacklisted.

### `Activate()` and `Disable()`

`Activate()` starts listening for input. `Disable()` stops listening for input.

```lua
manager:Activate()

manager:Disable()
```

### `TriggerKey(key, state, gameProcessed?, position?)`

Manually triggers an input key. Useful for testing or when input comes from a custom source.

```lua
manager:TriggerKey(Enum.KeyCode.Space, "began")

manager:TriggerKey(Enum.KeyCode.Space, "ended")
```

### `TriggerAction(name, state, gameProcessed?, position?)`

Manually triggers an action by name. The action does not need to have a key bound to it.

```lua
manager:TriggerAction("Jump", "began")
```

### `ResolveAction(key)`

Finds the action currently associated with a key in the active context. You usually do not need to call this directly; `TriggerKey()` and `Activate()` already use it internally.

## Manager Signals

Signals work similarly to `RBXScriptSignal`:

```lua
manager.ActionAdded:Connect(function(actionName)

    print("Added:", actionName)

end)
```

| Signal                  | When it fires                | Parameters                               |
| ----------------------- | ---------------------------- | ---------------------------------------- |
| `ActionAdded`           | An action is created         | `actionName`                             |
| `ActionRemoved`         | An action is removed         | `actionName`, `userData`                 |
| `ContextAdded`          | A context is created         | `contextName`                            |
| `ContextRemoved`        | A context is removed         | `contextName`, `userData`                |
| `CurrentContextChanged` | The current context changes  | `newContext`, `oldContext`               |
| `BlacklistChanged`      | `SetBlacklist` is called     | `keys`                                   |
| `BlacklistKeyStopped`   | A blacklisted key is blocked | `key`, `name`, `"action"` or `"context"` |
| `Activated`             | `Activate()` is called       | none                                     |
| `Disabled`              | `Disable()` is called        | none                                     |
| `ActionTriggered`       | An action is triggered       | See below                                |

`ActionTriggered` receives:

```lua
manager.ActionTriggered:Connect(function(

    actionName,

    action,

    state,          -- "began" or "ended"

    gameProcessed,  -- true if Roblox/UI processed the input

    key,            -- the key that was used; nil when TriggerAction is called

    position,       -- input position, if available

    fallbackFrom,   -- the fallback context that found the action, if any

    fallbackedContexts

)

end)
```

## Supported Inputs

* `Enum.KeyCode`, for example `Enum.KeyCode.E`
* `Enum.UserInputType`, for example `Enum.UserInputType.MouseButton1`
* `"mouse_wheel_up"` and `"mouse_wheel_down"`

You can also pass an `InputObject` directly to methods that accept an input key.

## Cleanup

When you no longer need the manager, call:

```lua
manager:Destroy()
```
