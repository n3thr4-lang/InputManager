# Action

An Action represents something the player can trigger through input, such as jumping, shooting, opening an inventory, accelerating, and so on.

## Creating an Action

```lua
local reload = manager:AddAction("Reload", {
    Active = true, -- defaults to true
    UserData = {Cooldown = 1.5},
})
```

| Value      | Description                                                                 |
| ---------- | --------------------------------------------------------------------------- |
| `Active`   | Whether the Action responds to input. Defaults to `true`.                   |
| `UserData` | Custom data associated with the Action. The library does not use this data. |

Action names must be unique within the manager.

## Binding and Removing Keys

```lua
reload:AddKey(Enum.KeyCode.R)
reload:AddKey(Enum.UserInputType.MouseButton1)

reload:RemoveKey(Enum.KeyCode.R)
```

A global key can only be bound to one Action. For example, if `R` is already bound to `Reload`, you cannot bind `R` to `OpenMap`.

Supported inputs:

* `Enum.KeyCode`, such as `Enum.KeyCode.R`
* `Enum.UserInputType`, such as `Enum.UserInputType.MouseButton1`
* `"mouse_wheel_up"` or `"mouse_wheel_down"`

## Receiving Input

Listen to the `Triggered` signal to run the Action's logic.

```lua
reload.Triggered:Connect(function(state, gameProcessed, key)
    if state ~= "began" then
        return
    end

    if gameProcessed then
        return -- Don't reload while the player is typing in chat or using UI.
    end

    print("Reload by", key.Name)
end)
```

`state` has two possible values:

| Value     | Description                                   |
| --------- | --------------------------------------------- |
| `"began"` | The player pressed a key or started an input. |
| `"ended"` | The player released a key or ended an input.  |

The full `Triggered` signature is:

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

* `key` is the input that triggered the Action. It is `nil` when using `manager:TriggerAction()`.
* `inputPosition` can be useful for mouse or touch input.
* `fallbackFrom` is the name of the Context that provided the Action through fallback, if any.
* `fallbackedContexts` contains the Contexts that were checked during fallback.

## Activating and Disabling an Action

```lua
reload:Disable()  -- The Action keeps its keys but no longer runs.
reload:Activate() -- Allows the Action to run again.
```

The current state is stored in `reload.Active`.

## Checking Keys

```lua
if reload:HasKey(Enum.KeyCode.R) then
    print("R is bound to Reload")
end

local keys = reload:GetKey()

for _, key in keys do
    print(key)
end
```

`GetKey()` returns a list of keys. Modifying this list does not change the Action. Use `AddKey()` or `RemoveKey()` instead.

## Signals

| Signal       | When it fires                 | Parameters              |
| ------------ | ----------------------------- | ----------------------- |
| `Triggered`  | The Action is triggered       | See **Receiving Input** |
| `Activated`  | `Activate()` is called        | none                    |
| `Disabled`   | `Disable()` is called         | none                    |
| `KeyAdded`   | A key is successfully bound   | `key`                   |
| `KeyRemoved` | A key is successfully removed | `key`                   |

Example:

```lua
reload.KeyAdded:Connect(function(key)
    print("Bound", key)
end)
```

## Destroying an Action

```lua
reload:Destroy()
```

This removes all keys bound to the Action, removes the Action from the manager, and destroys the Action's signals.
