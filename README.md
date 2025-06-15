# Hitbox

A flexible, efficient hitbox system for Roblox games that supports both server and client-side hit detection.

## Installation
Can be installed through [Wally](https://wally.run/package/breezy1214/hitbox?version=1.0.0)

## Features

- Server and client-side hit detection
- Support for different hitbox shapes (box, sphere, custom parts)
- Humanoid and object detection
- Velocity prediction for moving hitboxes
- Debug visualization
- Configurable parameters (debounce time, lifetime, etc.)
- Blacklist support to exclude specific instances
- Signal-based event system for hit detection
- Proper cleanup and memory management

## Setup

1. Place the `HitboxSettings` folder in ReplicatedStorage
2. Add the following object values to the settings folder:
   - `Alive Folder`: Reference to the folder containing all alive characters
   - `Ignore Folder`: Reference to the folder where the hitbox will ignore
   - `Velocity Constant`: (Optional) Numeric value for velocity calculations (default: 6)

## Usage Examples

### Basic Hitbox

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    InitialPosition = character.HumanoidRootPart.CFrame,
    SizeOrPart = Vector3.new(5, 5, 5),
    Debug = true
})

hitbox.HitSomeone:Connect(function(hitCharacters)
    for _, character in ipairs(hitCharacters) do
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        humanoid:TakeDamage(10)
    end
end)

hitbox:Start()

-- When done:
hitbox:Destroy()
```

### Client-Side Hitbox

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    UseClient = player,
    SizeOrPart = 5,
    LookingFor = "Humanoid",
    Debug = true
})

hitbox.HitSomeone:Connect(function(hitCharacters)
    for _, character in ipairs(hitCharacters) do
        -- Handle hit logic
    end
end)

hitbox:Start()
```

### Attaching Hitbox to a Moving Part

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(5, 5, 5),
    VelocityPrediction = true
})

hitbox:Start()
hitbox:WeldTo(character.HumanoidRootPart)

-- Change offset later:
hitbox:ChangeWeldOffset(CFrame.new(0, 0, -2))
```

## API Reference

### Constructors

#### `Hitbox.new(params: HitboxParams)`

Creates a new hitbox with the specified parameters.

**Parameters:**
- `params`: Table of configuration options:
  - `InitialPosition`: (CFrame) Starting position
  - `SizeOrPart`: (Vector3|number|Part) Hitbox size or reference part
  - `Debug`: (boolean) Whether to show debug visualization
  - `Debris`: (number) Lifetime in seconds before auto-destruction
  - `DebounceTime`: (number) Time before hitting the same target again
  - `LookingFor`: ("Humanoid"|"Object") Detection target type
  - `SpatialOption`: ("InBox"|"InRadius"|"InPart"|"Magnitude") Detection method
  - `Blacklist`: (table) Instances to exclude from detection
  - `UseClient`: (Player) Player to handle client-side detection
  - `VelocityPrediction`: (boolean) Whether to apply velocity-based position prediction
  - `DotProductRequirement`: (table) Direction-based hit validation

### Methods

#### `Hitbox:Start()`
Activates the hitbox for hit detection.

#### `Hitbox:Stop()`
Temporarily stops hit detection.

#### `Hitbox:SetPosition(newPosition: CFrame)`
Updates the hitbox position.

#### `Hitbox:WeldTo(part: BasePart, offset: CFrame?)`
Attaches the hitbox to a part with optional offset.

#### `Hitbox:Unweld()`
Detaches the hitbox from any welded part.

#### `Hitbox:ChangeWeldOffset(offset: CFrame)`
Updates the offset for a welded hitbox.

#### `Hitbox:SetVelocityPrediction(enabled: boolean)`
Enables or disables velocity-based position prediction.

#### `Hitbox:SetDebug(enabled: boolean)`
Toggles debug visualization.

#### `Hitbox:ClearTaggedChars()`
Clears the list of recently hit characters.

#### `Hitbox:Destroy()`
Destroys the hitbox and cleans up all resources.

### Static Methods

#### `Hitbox.ClearHitboxesWithID(id: number|string)`
Destroys all hitboxes with the specified ID.

#### `Hitbox.ClearClientHitboxes(client: Player)`
Destroys all hitboxes associated with a client.

#### `Hitbox.GetHitboxCache()`
Returns the current cache of active hitboxes.

### Events

#### `Hitbox.HitSomeone`
Fires when the hitbox detects a character.

#### `Hitbox.HitObject`
Fires when the hitbox detects an object.

## Advanced Configuration

### Dot Product Requirements

For directional hit detection (e.g., front-facing attacks):

```lua
local hitbox = Hitbox.new({
    -- ...other parameters
    DotProductRequirement = {
        PartForVector = character.HumanoidRootPart,
        VectorType = "LookVector", -- "LookVector", "UpVector", or "RightVector"
        DotProduct = 0.5, -- Minimum dot product (0.0 to 1.0)
        Negative = false -- Whether to negate the vector
    }
})
```

## Tips and Best Practices

1. For low-latency combat systems, use client-side hitboxes with server validation
2. Set appropriate debounce times to prevent hit spamming
3. Use the blacklist to exclude the attacker from their own hitboxes
4. Utilize velocity prediction for fast-moving hitboxes
5. Keep hitbox sizes reasonable for performance
6. Remember to call `:Destroy()` when hitboxes are no longer needed

## Troubleshooting

- If hits aren't registering, check that targets are in the correct Alive Folder
- For visualizing issues, enable Debug mode to see hitbox positions
- Ensure SpatialOption matches your SizeOrPart type
- Verify that RemoteEvents are properly replicated
- Check for typos in folder names and settings
