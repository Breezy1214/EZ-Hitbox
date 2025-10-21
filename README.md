# 🎯 EZ Hitbox

[![Wally](https://img.shields.io/badge/Wally-4.1.0-blue)](https://wally.run/package/breezy1214/hitbox?version=4.1.0)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Roblox](https://img.shields.io/badge/Platform-Roblox-00A2FF)](https://create.roblox.com/store/asset/104231461734810/Hitbox)

A flexible, high-performance hitbox system for Roblox games with advanced features like hit point detection, velocity prediction, and comprehensive debugging tools. Works seamlessly on both server and client.

## 📋 Table of Contents

- [🚀 Installation](#-installation)
- [✨ Features](#-features)
- [⚙️ Setup](#️-setup)
- [📚 Usage Examples](#-usage-examples)
- [📖 API Reference](#-api-reference)
- [🎯 Hit Point Detection](#-hit-point-detection)
- [⚡ Advanced Configuration](#-advanced-configuration)
- [💡 Tips and Best Practices](#-tips-and-best-practices)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

## 🚀 Installation

### Wally (Recommended)

```toml
[dependencies]
Hitbox = "breezy1214/hitbox@4.1.0"
```

### Manual Installation

1. Download the latest release from the GitHub repository
2. Place the module in your game's ReplicatedStorage

## ✨ Features

### Core Functionality

- 🎯 **Universal hit detection** - Works identically on server and client
- 🔍 **Precise hit point detection** - Get exact collision positions, normals, and materials
- 📐 **Multiple hitbox shapes** - Support for box, sphere, and custom part shapes
- 👤 **Flexible target detection** - Detect humanoids, objects, or both
- 🚀 **Velocity prediction** - Compensate for fast-moving hitboxes
- 🐛 **Visual debugging** - See your hitboxes in real-time

### Advanced Features

- ⚡ **High performance** - Optimized spatial queries and caching
- ⏱️ **Configurable parameters** - Debounce time, lifetime, and more
- 🚫 **Blacklist support** - Exclude specific instances from detection
- 📡 **Signal-based events** - Clean, reactive hit detection system
- 🔧 **Proper cleanup** - Automatic memory management and resource cleanup
- 🎮 **Easy integration** - Simple API that works with any Roblox game

## ⚙️ Setup

### Required Configuration

To use EZ Hitbox, you need to set up a configuration folder in ReplicatedStorage:

> ⚠️ Warning: If no `HitboxSettings` configuration folder is present in ReplicatedStorage, the module will automatically create configuration folders under `workspace`. You must populate the created folder with the character models (instances containing `Humanoid`) that you want the hitbox system to detect.

1. **Create the Settings Folder**
   - Create a folder named `HitboxSettings` in ReplicatedStorage

2. **Add Required ObjectValues**
   - `Alive Folder`: ObjectValue pointing to the folder containing all alive characters (e.g., workspace.Players)
   - `Ignore Folder`: ObjectValue pointing to the folder where hitboxes should ignore objects (e.g., workspace.Debris)

3. **Optional Configuration**
   - `Velocity Constant`: NumberValue for velocity calculations (default: 6)

### Example Setup Structure

```text
ReplicatedStorage/
└── HitboxSettings/
    ├── Alive Folder (ObjectValue) → workspace.Players
    ├── Ignore Folder (ObjectValue) → workspace.Debris
    └── Velocity Constant (NumberValue) = 6
```

## 📚 Usage Examples

### 🟢 Basic Server-Side Hitbox

Perfect for weapons, abilities, or any server-authoritative hit detection:

```lua
local Hitbox = require(path.to.Hitbox)

-- Create a simple sword slash hitbox
local hitbox = Hitbox.new({
    InitialCframe = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3),
    SizeOrPart = Vector3.new(8, 8, 4),
    LifeTime = 0.5,
    DebounceTime = 1.0,
    Debug = true
})

hitbox.OnHit:Connect(function(hitCharacters)
    for _, character in ipairs(hitCharacters) do
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:TakeDamage(25)
            print("Hit:", character.Name)
        end
    end
end)

hitbox:Start()
```

### 🔵 Basic Client-Side Hitbox

Perfect for responsive visual effects and client-side feedback:

```lua
local Hitbox = require(path.to.Hitbox)

-- Create a client-side hitbox for instant feedback
local hitbox = Hitbox.new({
    SizeOrPart = 6, -- Sphere with radius 6
    SpatialOption = "InRadius",
    LookingFor = "Humanoid",
    DebounceTime = 0.1,
    Debug = true
})

hitbox.OnHit:Connect(function(hitCharacters)
    for _, character in ipairs(hitCharacters) do
        -- Immediate visual feedback
        createHitEffect(character.HumanoidRootPart.Position)
        -- Send to server for validation if needed
        remoteEvents.ValidateHit:FireServer(character)
    end
end)

hitbox:Start()
```

### 🎯 Advanced Hit Point Detection

Get precise hit locations for visual effects, bullet holes, or damage zones:

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(5, 5, 5),
    VelocityPrediction = true,
    DetectHitPoints = true, -- Enable precise hit detection
    LookingFor = "Object",
    LifeTime = 2.0,
    Debug = true
})

-- Handle hits with precise location data
hitbox.HitObjectWithPoint:Connect(function(hitData)
    for _, data in pairs(hitData) do
        print("Hit:", data.Object.Name)
        print("Position:", data.Position)
        print("Surface Normal:", data.Normal)
        print("Material:", data.Material)
        
        -- Create bullet hole decal
        createBulletHole(data.Object, data.Position, data.Normal)
        
        -- Spawn impact particles
        spawnImpactEffect(data.Position, data.Normal, data.Material)
    end
end)

hitbox:Start()
```

### ⚡ Moving Hitbox with Velocity Prediction

For projectiles or fast-moving attacks:

```lua
local Hitbox = require(path.to.Hitbox)

-- Create hitbox for a moving projectile
local hitbox = Hitbox.new({
    InitialCframe = weapon.CFrame,
    SizeOrPart = Vector3.new(2, 2, 6),
    VelocityPrediction = true,
    LifeTime = 3.0,
    LookingFor = "Humanoid",
    Blacklist = {character}, -- Exclude the shooter
    Debug = true
})

-- Attach to projectile
hitbox:WeldTo(projectilePart)

hitbox.OnHit:Connect(function(hitCharacters)
    for _, hitCharacter in ipairs(hitCharacters) do
        -- Apply damage and knockback
        damageCharacter(hitCharacter, 50)
        applyKnockback(hitCharacter, projectilePart.Velocity)
    end
    
    -- Destroy projectile on hit
    projectilePart:Destroy()
    hitbox:Destroy()
end)

hitbox:Start()
```

### 🎪 Directional Hit Detection

Only hit targets in front of the attacker:

```lua
local Hitbox = require(path.to.Hitbox)

local hitbox = Hitbox.new({
    InitialCframe = character.HumanoidRootPart.CFrame,
    SizeOrPart = Vector3.new(10, 6, 8),
    DotProductRequirement = {
        PartForVector = character.HumanoidRootPart,
        VectorType = "LookVector",
        DotProduct = 0.3, -- ~70 degree cone in front
        Negative = false
    },
    Debug = true
})

hitbox.OnHit:Connect(function(hitCharacters)
    for _, hitCharacter in ipairs(hitCharacters) do
        -- Only hits enemies in front of the player
        print("Front hit on:", hitCharacter.Name)
    end
end)

hitbox:Start()
```

## 📖 API Reference

### Constructor

#### `Hitbox.new(params: HitboxParams) -> Hitbox`

Creates a new hitbox instance with the specified configuration.

**Parameters Table:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `SizeOrPart` | `Vector3 \| number \| BasePart` | Required | Hitbox dimensions, radius, or reference part |
| `SpatialOption` | `"InBox" \| "InRadius" \| "InPart"` | Auto-detected | Detection method |
| `InitialCframe` | `CFrame` | `CFrame.new()` | Starting position and orientation |
| `Blacklist` | `{ Model }` | `{}` | Model instances to exclude |
| `DebounceTime` | `number` | `0` | Cooldown between hitting same target |
| `DotProductRequirement` | `DotProductRequirement` | `nil` | Directional hit filtering |
| `ID` | `string \| number` | `nil` | Unique identifier for grouping hitboxes |
| `VelocityPrediction` | `boolean` | `false` | Compensate for movement |
| `Debug` | `boolean` | `false` | Show visual debug representation |
| `LifeTime` | `number` | `math.huge` | Auto-destroy after seconds |
| `LookingFor` | `"Humanoid" \| "Object"` | `"Humanoid"` | Target detection type |
| `DetectHitPoints` | `boolean` | `false` | Enable precise hit locations |

**Example:**

```lua
local hitbox = Hitbox.new({
    InitialCframe = workspace.Part.CFrame,
    SizeOrPart = Vector3.new(10, 10, 10),
    LifeTime = 5,
    Debug = true
})
```

### Instance Methods

#### `Hitbox:Start() -> void`

Activates the hitbox for hit detection.

#### `Hitbox:Stop() -> void`

Temporarily pauses hit detection without destroying the hitbox.

#### `Hitbox:SetCFrame(newCFrame: CFrame) -> void`

Updates the hitbox position and orientation.

#### `Hitbox:WeldTo(part: BasePart, offset: CFrame?) -> void`

Attaches the hitbox to a part with optional offset. The hitbox will follow the part's movement.

**Parameters:**

- `part`: The part to attach to
- `offset`: Optional CFrame offset from the part

#### `Hitbox:Unweld() -> void`

Detaches the hitbox from any welded part.

#### `Hitbox:SetWeldOffset(offset: CFrame) -> void`

Updates the offset for a welded hitbox.

#### `Hitbox:EnableVelocityPrediction(enabled: boolean) -> void`

Toggles velocity-based position prediction for moving hitboxes.

#### `Hitbox:EnableDebug(enabled: boolean) -> void`

Toggles visual debug representation.

#### `Hitbox:ClearTaggedCharacters() -> void`

Clears the internal list of recently hit characters, allowing them to be hit again immediately.

#### `Hitbox:GetParts() -> {Model | BasePart}`

Returns what's currently inside the hitbox. This method provides an immediate snapshot of all detected targets based on the hitbox's `LookingFor` setting.

**Returns:**

- Array of `Model` instances (characters) if `LookingFor = "Humanoid"`
- Array of `BasePart` instances if `LookingFor = "Object"`

**Example:**

```lua
local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(10, 10, 10),
    LookingFor = "Humanoid",
    Debug = true
})

-- Get immediate results
local hitTargets = hitbox:GetParts()
for _, character in ipairs(hitTargets) do
    print("Currently detecting:", character.Name)
end
```

#### `Hitbox:Destroy() -> void`

Destroys the hitbox and cleans up all resources. Always call this when done!

### Static Methods

#### `Hitbox.ClearHitboxesByID(id: number | string) -> void`

Destroys all hitboxes with the specified ID. Useful for cleaning up multiple hitboxes at once.

#### `Hitbox.GetHitboxCache() -> {Hitbox}`

Returns the current cache of active hitboxes for debugging purposes.

### Events

#### `Hitbox.OnHit: Signal<{Model}>`

Fires when the hitbox detects characters. Provides an array of hit character models.

#### `Hitbox.HitObject: Signal<{Instance}>`

Fires when the hitbox detects objects. Provides an array of hit instances.

#### `Hitbox.OnHitWithPoint: Signal<{HitPointData}>`

Fires when the hitbox detects characters with precise hit data (requires `DetectHitPoints = true`).

#### `Hitbox.HitObjectWithPoint: Signal<{HitPointData}>`

Fires when the hitbox detects objects with precise hit data (requires `DetectHitPoints = true`).

## 🎯 Hit Point Detection

Hit point detection provides exact collision positions, surface normals, and material information. This feature is optional and works on both server and client-side hitboxes.

### When to Use Hit Point Detection

- **Visual Effects**: Spawn particles, decals, or attachments at exact hit locations
- **Realistic Physics**: Apply forces based on hit normals and positions
- **Damage Systems**: Create location-based damage (headshots, weak points)
- **Environmental Interaction**: Leave marks, holes, or effects on surfaces

### HitPointData Structure

```lua
type HitPointData = {
    Object: Model | BasePart,    -- The hit object/character
    Position: Vector3,           -- World position of the hit
    Normal: Vector3,            -- Surface normal at hit point
    Material: Enum.Material,    -- Material of the hit surface
}
```

### Implementation Example

```lua
local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(5, 5, 5),
    DetectHitPoints = true, -- Enable hit point detection
    LookingFor = "Object",
    Debug = true
})

-- Both regular and hit point events fire simultaneously
hitbox.HitObject:Connect(function(hitObjects)
    -- Basic hit logic (backwards compatible)
    print("Hit", #hitObjects, "objects")
end)

hitbox.HitObjectWithPoint:Connect(function(hitData)
    for _, data in pairs(hitData) do
        -- Advanced hit logic with position data
        createImpactEffect(data.Position, data.Normal)
        playMaterialSound(data.Material)
        
        -- Create decal on the surface
        local decal = Instance.new("Decal")
        decal.Texture = "rbxasset://textures/bulletHole.png"        decal.Face = getNearestFace(data.Object, data.Normal)
        decal.Parent = data.Object
    end
end)
```

### Performance Considerations

- **Computational Cost**: Hit point detection uses raycasting, which has a small performance impact
- **Selective Usage**: Only enable `DetectHitPoints = true` when you actually need position data
- **Simultaneous Events**: Both regular and hit-point events fire at the same time when enabled

### Common Use Cases

1. **Bullet Holes**: Place decals at exact hit positions with proper orientation
2. **Particle Effects**: Spawn effects at hit points with surface-aligned normals  
3. **Damage Indicators**: Show floating damage numbers at precise hit locations
4. **Environmental Interaction**: Create destruction, marks, or attachments at impact points

## ⚡ Advanced Configuration

### Directional Hit Detection

Use dot product requirements to limit hits to specific directions (e.g., only hitting enemies in front):

```lua
local hitbox = Hitbox.new({
    InitialCframe = character.HumanoidRootPart.CFrame,
    SizeOrPart = Vector3.new(10, 6, 8),
    DotProductRequirement = {
        PartForVector = character.HumanoidRootPart,
        VectorType = "LookVector", -- "LookVector", "UpVector", or "RightVector"
        DotProduct = 0.5, -- Minimum dot product (0.0 to 1.0)
        Negative = false -- Whether to negate the vector
    },
    Debug = true
})
```

**Dot Product Values:**

- `1.0` = Exactly the same direction (0° angle)
- `0.7` = ~45° cone
- `0.5` = ~60° cone  
- `0.0` = 90° cone (perpendicular)
- `-1.0` = Exactly opposite direction (180°)

### Spatial Detection Options

Choose the best detection method for your hitbox shape:

| SpatialOption | Best For | Description |
|---------------|----------|-------------|
| `"InBox"` | Rectangular areas | Uses Region3 for box-shaped detection |
| `"InRadius"` | Circular areas | Spherical detection with radius |
| `"InPart"` | Custom shapes | Uses the geometry of a reference part |
| `"Magnitude"` | Simple distance | Basic distance-based detection |

### Advanced Blacklist Usage

```lua
-- Exclude multiple types of objects
local blacklist = {
    attacker,                    -- The attacker themselves
    attacker.Weapon,            -- Their weapon
    workspace.Debris,           -- Debris folder
    workspace.Effects           -- Effects folder
}

local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(5, 5, 5),
    Blacklist = blacklist,
    -- ...other parameters
})
```

### Velocity Prediction Configuration

Compensate for fast-moving hitboxes or targets:

```lua
local hitbox = Hitbox.new({
    SizeOrPart = Vector3.new(3, 3, 8),
    VelocityPrediction = true,
    -- The system uses the Velocity Constant from HitboxSettings
    -- Default is 6, but you can adjust it based on your game's needs
})

-- Enable/disable at runtime
hitbox:EnableVelocityPrediction(true)
```

## 💡 Tips and Best Practices

### Performance Optimization

1. **🎯 Choose the Right Implementation**
   - Use server-side hitboxes for authoritative hit detection
   - Use client-side hitboxes for responsive visual feedback and validation

2. **🚫 Use Blacklists Effectively**
   - Always exclude the attacker from their own hitboxes
   - Blacklist debris, effects, and other non-target objects

3. **📏 Size Your Hitboxes Appropriately**
   - Smaller hitboxes = higher performance
   - Larger hitboxes = lower performance

### Combat System Design

1. **⚡ Implement Proper Debouncing**
   - Use debounce times to prevent hit spamming

2. **🔄 Memory Management**
   - Always call `:Destroy()` when hitboxes are no longer needed
   - Use `ClearHitboxesByID()` for bulk cleanup

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### ❌ Hits Not Registering

**Problem**: Hitbox isn't detecting any targets

**Solutions**:

- ✅ Verify targets are in the correct `Alive Folder` (check HitboxSettings)
- ✅ Ensure the hitbox is started with `:Start()`
- ✅ Check that `SpatialOption` matches your `SizeOrPart` type
- ✅ Confirm targets aren't in the `Blacklist`
- ✅ Enable `Debug = true` to visualize the hitbox

#### ❌ Performance Issues

**Problem**: Game lagging when using hitboxes

**Solutions**:

- ✅ Reduce hitbox sizes or use more efficient `SpatialOption`
- ✅ Implement proper cleanup with `:Destroy()`
- ✅ Monitor hitbox cache with `GetHitboxCache()`
- ✅ Avoid creating too many hitboxes simultaneously
- ✅ Use appropriate `LifeTime` values

#### ❌ Hit Point Detection Not Working

**Problem**: `OnHitWithPoint` events not firing

**Solutions**:

- ✅ Ensure `DetectHitPoints = true` is set in hitbox parameters
- ✅ Verify you're connecting to the correct event (`OnHitWithPoint` vs `OnHit`)
- ✅ Check that targets have proper collision geometry
- ✅ Test with `Debug = true` to see if basic detection works first

#### ❌ Directional Detection Issues

**Problem**: Dot product requirements not working as expected

**Solutions**:

- ✅ Verify `PartForVector` is pointing in the correct direction
- ✅ Adjust `DotProduct` value (try 0.5 for ~60° cone)
- ✅ Check if `Negative` parameter needs to be toggled
- ✅ Use debug mode to visualize hitbox orientation

### Reporting Bugs

When reporting issues, please include:

- Expected vs actual behavior
- Any error messages from the console
- Steps to reproduce the issue

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

1. Clone the repository
2. Install dependencies with Wally: `wally install`
3. Use Rojo for syncing: `rojo serve`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with ❤️ for the Roblox community
