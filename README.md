# filo_bolt

Store: [filo-studios.tebex.io](https://filo-studios.tebex.io) · Discord: [discord.gg/gdtBkz9Thj)](https://discord.gg/gdtBkz9Thj)

A standalone wheel bolt minigame for FiveM. Players interact with individual lug nuts on a vehicle wheel using a 3D cursor — rotating each bolt to tighten or loosen it. Designed to be called from any resource via a single export.

---

## Features

- 3D world-space bolt spawning around any wheel bone
- Per-bolt rotation animation with smooth Y-axis interpolation
- Cursor-driven interaction with draw-outline hover feedback
- Configurable lug nut count, direction (tighten/loosen), and cancel behavior
- `OneAtATime` mode — restricts the player to one bolt at a time
- Custom audio via a named script audio bank (`filo_bolt_soundset`)
- Scripted camera that frames the target wheel (optional, toggled in `cl-main`)
- Promise-based blocking call — returns `true` on completion, `false` on cancel
- Safe cleanup on resource stop

---

## Dependencies

- [`ox_lib`](https://github.com/overextended/ox_lib) — used for `cache.ped`

---

## Installation

1. Drop the `filo_bolt` folder into your resources directory.
2. Add `ensure filo_bolt` to your `server.cfg`.

---

## Configuration

Edit `config.lua` (or wherever your `Config` table lives):

| Key | Type | Description |
|---|---|---|
| `Config.OutlineColor` | `{ r, g, b, a }` | RGBA color used for the bolt hover outline |
| `Config.OneAtATime` | `boolean` | If `true`, only one bolt can animate at once |

---

## Export

### `Start(data)` → `boolean`

Starts the bolt minigame for a specific vehicle wheel. Blocks until the player finishes or cancels.

```lua
local success = exports.filo_bolt:Start(data)
```

**Parameters**

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `vehicle` | `integer` | ✅ | — | Entity handle of the vehicle |
| `wheelBone` | `string \| integer` | ✅ | — | Bone name (`"wheel_lf"`) or bone index |
| `lugnutCount` | `integer` | ❌ | `5` | Number of bolts to spawn |
| `isTightening` | `boolean` | ❌ | `false` | `true` = clockwise (tighten), `false` = counter-clockwise (loosen) |
| `canCancel` | `boolean` | ❌ | `true` | Whether the player can exit early with `Escape` / `Backspace` |

**Return value**

| Value | Meaning |
|---|---|
| `true` | All bolts were successfully rotated |
| `false` | Player cancelled before finishing |

**Valid `wheelBone` values**

```
"wheel_lf"   front-left
"wheel_rf"   front-right
"wheel_lr"   rear-left
"wheel_rr"   rear-right
```

---

## Usage Examples

**Basic loosen (e.g. tyre removal)**
```lua
local success = exports.filo_bolt:Start({
    vehicle      = vehicle,
    wheelBone    = "wheel_lf",
    lugnutCount  = 5,
    isTightening = false,
})

if success then
    -- all bolts removed, proceed with tyre removal logic
end
```

**Tighten after fitting a wheel**
```lua
local success = exports.filo_bolt:Start({
    vehicle      = vehicle,
    wheelBone    = "wheel_rr",
    lugnutCount  = 6,
    isTightening = true,
    canCancel    = false,
})
```

**Passing a bone index instead of a name**
```lua
local boneIdx = GetEntityBoneIndexByName(vehicle, "wheel_lr")

local success = exports.filo_bolt:Start({
    vehicle   = vehicle,
    wheelBone = boneIdx,
})
```

---

## File Structure

```
filo_bolt/
├── client/
│   ├── cl-init.lua       -- Global constants (WHEEL_BONES, BOLT_MODEL, etc.)
│   ├── cl-camera.lua     -- Scripted camera create/destroy
│   ├── cl-bolt.lua       -- Bolt spawning, animation, and cleanup
│   ├── cl-raycast.lua    -- Cursor-to-world shape test utility
│   ├── cl-sound.lua      -- Audio bank loading and playback
│   └── cl-main.lua       -- Orchestration, input loop, export
├── config.lua
└── fxmanifest.lua
```

---
