# EZ Hitbox

[![Wally](https://img.shields.io/badge/Wally-5.0.0-blue)](https://wally.run/package/breezy1214/hitbox?version=5.0.0)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Roblox](https://img.shields.io/badge/Platform-Roblox-00A2FF)](https://create.roblox.com/store/asset/104231461734810/Hitbox)

A flexible, high-performance hitbox system for Roblox games with advanced features like hit point detection, velocity prediction, and comprehensive debugging tools. Works seamlessly on both server and client.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Features](#features)
- [Usage Examples](#usage-examples)
- [API Reference](#api-reference)
- [Hit Point Detection](#hit-point-detection)
- [Advanced Configuration](#advanced-configuration)
- [Migration from v4.x](#migration-from-v4x)
- [Tips and Best Practices](#tips-and-best-practices)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Installation

### Wally (Recommended)

```toml
[dependencies]
Hitbox = "breezy1214/hitbox@5.0.0"
```

### Manual Installation

1. Download the latest release from the GitHub repository
2. Place the module in your game's ReplicatedStorage

## Quick Start

```lua
local Hitbox = require(path.to.Hitbox)

-- Simplest: Sphere hitbox
local hit = Hitbox.sphere(10, character.HumanoidRootPart.CFrame)
hit.OnHit:Connect(function(characters)
    for _, char in characters do
        print("Hit:", char.Name)
    end
end)
hit:Start()

-- Box hitbox
local hit = Hitbox.box(Vector3.new(10, 5, 10), CFrame.new(0, 5, 0))
hit.OnHit:Connect(function(characters) ... end)
hit:Start()

-- From existing part
local hit = Hitbox.fromPart(workspace.MyHitboxPart)
hit:Start()
```

## Features

### Core Functionality

- **Universal hit detection** - Works identically on server and client
- **Precise hit point detection** - Get exact collision positions, normals, and materials
- **Multiple hitbox shapes** - Support for box, sphere, and custom part shapes
- **Flexible target detection** - Detect humanoids, objects, or both
- **Velocity prediction** - Compensate for fast-moving hitboxes
- **Visual debugging** - See your hitboxes in real-time
- **Tag filtering** - Optional CollectionService tag filtering

### Advanced Features

- **High performance** - Optimized spatial queries and caching
- **Configurable parameters** - Debounce time, lifetime, and more
- **Blacklist support** - Exclude specific instances from detection
- **Signal-based events** - Clean, reactive hit detection system
- **Proper cleanup** - Automatic memory management and resource cleanup
- **Factory methods** - Convenient `sphere()`, `box()`, and `fromPart()` constructors
- **Auto-start option** - Start detection immediately on creation

## Usage Examples

### Basic Server-Side Hitbox

Perfect for weapons, abilities, or any server-authoritative hit detection:

```lua
local Hitbox = require(path.to.Hitbox)

-- Create a simple sword slash hitbox
local hitbox = Hitbox.box(Vector3.new(8, 8, 4), character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3), {
    Lifetime = 0.5,
    DebounceTime = 1.0,
    Debug = true,
    Blacklist = {character}, -- Don't hit yourself
})

hitbox.OnHit:Connect(function(hitCharacters)
    for _, hitChar in hitCharacters do
        local humanoid = hitChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:TakeDamage(25)
            print("Hit:", hitChar.Name)
        end
    end
end)

hitbox:Start()
```

### Sphere Hitbox with Auto-Destroy

```lua
local Hitbox = require(path.to.Hitbox)

-- Explosion radius check
local hitbox = Hitbox.sphere(15, explosionPosition, {
    Lifetime = 0.1,      -- Auto-destroy after 0.1 seconds
    AutoStart = true,    -- Start immediately
    Debug = true,
})

hitbox.OnHit:Connect(function(hitCharacters)
    for _, character in hitCharacters do
        applyExplosionDamage(character, 50)
    end
end)
-- No need to call :Start() when AutoStart = true
```

### Full Constructor

For complete control over all parameters:

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    Size = Vector3.new(10, 6, 8),
    CFrame = character.HumanoidRootPart.CFrame,
    LookingFor = "Humanoid",
    DebounceTime = 0.5,
    Lifetime = 5,
    Debug = true,
    VelocityPrediction = true,
    VelocityConstant = 6,
    Blacklist = {character},
    Tag = "Enemy",  -- Only detect instances tagged "Enemy"
    DetectHitPoints = true,
})

hitbox.OnHitWithPoint:Connect(function(hitData)
    for _, data in hitData do
        print("Hit:", data.Object.Name, "at", data.Position)
    end
end)

hitbox:Start()
```

### Object Detection with Hit Points

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.box(Vector3.new(5, 5, 5), gunBarrel.CFrame, {
    LookingFor = "Object",
    DetectHitPoints = true,
    Debug = true,
})

hitbox.HitObjectWithPoint:Connect(function(hitData)
    for _, data in hitData do
        print("Hit:", data.Object.Name)
        print("Position:", data.Position)
        print("Normal:", data.Normal)
        print("Material:", data.Material)
        
        -- Create bullet hole at exact position
        createBulletHole(data.Object, data.Position, data.Normal)
    end
end)

hitbox:Start()
```

### Moving Hitbox with Velocity Prediction

For projectiles or fast-moving attacks:

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.box(Vector3.new(2, 2, 6), projectilePart.CFrame, {
    VelocityPrediction = true,
    VelocityConstant = 6,
    Lifetime = 3.0,
    Blacklist = {character},
    Debug = true,
})

hitbox:WeldTo(projectilePart)

hitbox.OnHit:Connect(function(hitCharacters)
    for _, hitChar in hitCharacters do
        damageCharacter(hitChar, 50)
    end
    projectilePart:Destroy()
    hitbox:Destroy()
end)

hitbox:Start()
```

### Directional Hit Detection

Only hit targets in front of the attacker:

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    Size = Vector3.new(10, 6, 8),
    CFrame = character.HumanoidRootPart.CFrame,
    DotProductRequirement = {
        PartForVector = character.HumanoidRootPart,
        VectorType = "LookVector",
        DotProduct = 0.3, -- ~70 degree cone in front
        Negative = false
    },
    Debug = true,
})

hitbox.OnHit:Connect(function(hitCharacters)
    for _, hitChar in hitCharacters do
        print("Front hit on:", hitChar.Name)
    end
end)

hitbox:Start()
```

### Tag-Based Filtering

Only detect instances with specific CollectionService tags:

```lua
local Hitbox = require(path.to.Hitbox)

-- Only hit enemies tagged with "Enemy"
local hitbox = Hitbox.sphere(10, position, {
    Tag = "Enemy",
    Debug = true,
})

hitbox.OnHit:Connect(function(enemies)
    for _, enemy in enemies do
        damageEnemy(enemy)
    end
end)

hitbox:Start()
```

### One-Shot Area Check

Check an area without continuous detection:

```lua
local function getCharactersInArea(position, radius)
    local hitbox = Hitbox.sphere(radius, CFrame.new(position))
    local targets = hitbox:GetParts()
    hitbox:Destroy()
    return targets
end

local nearbyCharacters = getCharactersInArea(Vector3.new(0, 5, 0), 20)
print("Found", #nearbyCharacters, "characters")
```

## API Reference

### Factory Methods

#### `Hitbox.sphere(radius, cframe?, params?) -> Hitbox`

Creates a sphere-shaped hitbox.

```lua
local hitbox = Hitbox.sphere(10, CFrame.new(0, 5, 0), {
    Debug = true,
    DebounceTime = 0.5,
})
```

#### `Hitbox.box(size, cframe?, params?) -> Hitbox`

Creates a box-shaped hitbox.

```lua
local hitbox = Hitbox.box(Vector3.new(10, 5, 10), CFrame.new(0, 5, 0), {
    Debug = true,
})
```

#### `Hitbox.fromPart(part, params?) -> Hitbox`

Creates a hitbox using an existing part's shape.

```lua
local hitbox = Hitbox.fromPart(workspace.SwordHitbox, {
    DebounceTime = 0.5,
})
```

### Constructor

#### `Hitbox.new(params: HitboxParams) -> Hitbox`

Creates a new hitbox instance with full configuration.

**Parameters Table:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `Size` | `Vector3 \| number` | Required | Box dimensions or sphere radius |
| `Part` | `BasePart` | nil | Use existing part's shape (alternative to Size) |
| `CFrame` | `CFrame` | `CFrame.identity` | Starting position and orientation |
| `SpatialOption` | `string` | Auto-detected | `"InBox"`, `"InRadius"`, `"InPart"`, or `"Magnitude"` |
| `LookingFor` | `string` | `"Humanoid"` | `"Humanoid"` or `"Object"` |
| `Blacklist` | `{Instance}` | `{}` | Instances to exclude from detection |
| `Tag` | `string` | nil | Only detect instances with this CollectionService tag |
| `DebounceTime` | `number` | `0` | Cooldown between hitting same target |
| `Lifetime` | `number` | `0` | Auto-destroy after seconds (0 = never) |
| `AutoStart` | `boolean` | `false` | Start detection immediately |
| `Debug` | `boolean` | `false` | Show visual representation |
| `DetectHitPoints` | `boolean` | `false` | Enable precise hit locations |
| `VelocityPrediction` | `boolean` | `true` | Compensate for movement |
| `VelocityConstant` | `number` | `6` | Velocity prediction divisor |
| `DotProductRequirement` | `table` | nil | Directional hit filtering |
| `ID` | `string \| number` | nil | Identifier for batch operations |

### Instance Methods

#### `Hitbox:Start() -> void`

Activates the hitbox for hit detection.

#### `Hitbox:Stop() -> void`

Temporarily pauses hit detection without destroying the hitbox.

#### `Hitbox:Destroy() -> void`

Destroys the hitbox and cleans up all resources.

#### `Hitbox:GetParts() -> {Model | BasePart}`

Returns all targets currently inside the hitbox without using events.

#### `Hitbox:SetCFrame(cframe: CFrame) -> void`

Updates the hitbox position and orientation.

#### `Hitbox:WeldTo(part: BasePart, offset: CFrame?) -> void`

Attaches the hitbox to a part with optional offset.

#### `Hitbox:Unweld() -> void`

Detaches the hitbox from any welded part.

#### `Hitbox:SetWeldOffset(offset: CFrame) -> void`

Updates the offset for a welded hitbox.

#### `Hitbox:LinkToInstance(instance: Instance) -> void`

Links the hitbox's lifecycle to an instance. When the instance is destroyed, the hitbox is automatically cleaned up.

#### `Hitbox:EnableVelocityPrediction(enabled: boolean) -> void`

Toggles velocity-based position prediction.

#### `Hitbox:EnableDebug(enabled: boolean) -> void`

Toggles visual debug representation.

#### `Hitbox:ClearTaggedCharacters() -> void`

Clears the debounce list, allowing all characters to be hit again.

#### `Hitbox:ClearTaggedObjects() -> void`

Clears the debounce list for objects.

### Static Methods

#### `Hitbox.ClearHitboxesByID(id: number | string) -> void`

Destroys all hitboxes with the specified ID.

#### `Hitbox.GetHitboxCache() -> {Hitbox}`

Returns the cache of all active hitboxes.

### Events

| Event | Fires When | Data |
|-------|------------|------|
| `OnHit` | Characters detected | `{Model}` |
| `HitObject` | Objects detected | `{BasePart}` |
| `OnHitWithPoint` | Characters detected (with `DetectHitPoints`) | `{HitPointData}` |
| `HitObjectWithPoint` | Objects detected (with `DetectHitPoints`) | `{HitPointData}` |

### HitPointData Structure

```lua
type HitPointData = {
    Object: Model | BasePart,  -- The hit target
    Position: Vector3,         -- World position of hit
    Normal: Vector3,           -- Surface normal at hit point
    Material: Enum.Material,   -- Material of hit surface
}
```

## Hit Point Detection

Hit point detection provides exact collision positions, surface normals, and material information.

### When to Use

- Visual effects at exact hit locations
- Bullet holes, decals, or impact marks
- Location-based damage (headshots, weak points)
- Physics-based knockback using hit normals

### Example

```lua
local hitbox = Hitbox.sphere(5, position, {
    DetectHitPoints = true,
    LookingFor = "Object",
})

hitbox.HitObjectWithPoint:Connect(function(hitData)
    for _, data in hitData do
        -- Create effect at exact hit location
        local effect = Instance.new("Part")
        effect.Size = Vector3.new(0.5, 0.5, 0.5)
        effect.CFrame = CFrame.lookAt(data.Position, data.Position + data.Normal)
        effect.Parent = workspace
        
        game:GetService("Debris"):AddItem(effect, 2)
    end
end)

hitbox:Start()
```

## Advanced Configuration

### Directional Hit Detection

Limit hits to specific directions using dot product:

| DotProduct Value | Cone Angle |
|------------------|------------|
| `1.0` | 0 degrees (exact direction) |
| `0.7` | ~45 degrees |
| `0.5` | ~60 degrees |
| `0.3` | ~70 degrees |
| `0.0` | 90 degrees |
| `-1.0` | 180 degrees (opposite) |

### Spatial Detection Options

| Option | Best For |
|--------|----------|
| `"InBox"` | Rectangular areas (default for Vector3) |
| `"InRadius"` | Spherical areas (default for number) |
| `"InPart"` | Custom part shapes |
| `"Magnitude"` | Simple distance checks |

## Migration from v4.x

Version 5.0 simplifies the API significantly. Here's how to migrate:

### Removed Requirements

- No more `HitboxSettings` folder in ReplicatedStorage
- No more `Alive Folder` to parent characters into
- No more `Ignore Folder` configuration
- No more `NumberValue` for velocity constant

### API Changes

| Old (v4.x) | New (v5.0) |
|------------|------------|
| `SizeOrPart = Vector3.new(...)` | `Size = Vector3.new(...)` |
| `InitialCframe = CFrame.new(...)` | `CFrame = CFrame.new(...)` |
| `LifeTime = 5` | `Lifetime = 5` |
| External velocity constant | `VelocityConstant = 6` parameter |

### Legacy Support

The old parameter names (`SizeOrPart`, `InitialCframe`, `LifeTime`) are still supported for backwards compatibility but are deprecated.

### Before (v4.x)

```lua
-- Required setup
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        char.Parent = workspace["Alive Folder"]
    end)
end)

local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(10, 10, 10),
    InitialCframe = CFrame.new(0, 5, 0),
    LifeTime = 5,
})
```

### After (v5.0)

```lua
-- No setup required
local hitbox = Hitbox.sphere(10, CFrame.new(0, 5, 0), {
    Lifetime = 5,
})
-- Or use factory methods
local hitbox = Hitbox.box(Vector3.new(10, 10, 10), CFrame.new(0, 5, 0))
```

## Tips and Best Practices

### Performance

1. Use factory methods (`sphere`, `box`) for common cases
2. Always call `:Destroy()` when done
3. Use appropriate `Lifetime` values for auto-cleanup
4. Smaller hitboxes perform better than larger ones
5. Use `Tag` filtering to reduce unnecessary checks

## Troubleshooting

### Hits Not Registering

- Ensure `:Start()` was called (or use `AutoStart = true`)
- Check that targets aren't in the `Blacklist`
- Verify `LookingFor` matches your target type
- Enable `Debug = true` to visualize the hitbox
- If using `Tag`, ensure targets have the correct tag

### Performance Issues

- Reduce hitbox sizes
- Use `:Destroy()` on unused hitboxes
- Check `Hitbox.GetHitboxCache()` for leaks
- Use appropriate `Lifetime` values

### Hit Points Not Working

- Ensure `DetectHitPoints = true`
- Connect to `OnHitWithPoint` or `HitObjectWithPoint` events
- Verify targets have collision geometry

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with ❤️ for the Roblox community
