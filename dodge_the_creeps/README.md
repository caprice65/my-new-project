# Dodge the Creeps

Based on the official Godot tutorial
["Your first 2D game"](https://docs.godotengine.org/en/latest/getting_started/first_2d_game/index.html),
extended for practice (state machine, object pool, pause, virtual joystick, etc.).

- **Engine:** Godot 4.7 (Compatibility renderer)
- **Language:** GDScript
- **Main scene:** `res://scenes/main.tscn`

## Directory layout

```
dodge_the_creeps/
├── project.godot
├── scenes/
│   ├── main.tscn              # game root / orchestration
│   ├── actors/                # gameplay entities
│   │   ├── player.tscn
│   │   └── mob.tscn
│   ├── ui/
│   │   └── hud.tscn
│   └── systems/
│       └── audio_manager.tscn # Autoload scene
├── scripts/
│   ├── core/                  # Autoload logic / shared services
│   │   ├── game_state.gd      # class_name GameState → GameState.instance
│   │   └── audio_manager.gd   # class_name AudioManager → AudioManager.instance
│   ├── game/                  # gameplay
│   │   ├── main.gd
│   │   ├── player.gd
│   │   ├── mob.gd
│   │   └── mob_spawner.gd
│   └── ui/
│       ├── hud.gd
│       └── virtual_joystick.gd
├── art/                       # sprites
├── audio/                     # music / sfx
├── fonts/
└── screenshots/
```

## Architecture (where to change what)

| Concern | Touch these |
|---------|-------------|
| Score / pause / high score / round flow | `scripts/core/game_state.gd`, `scripts/game/main.gd` |
| Player move / hit | `scripts/game/player.gd`, `scenes/actors/player.tscn` |
| Spawn / difficulty / pool | `scripts/game/mob_spawner.gd`, `scripts/game/mob.gd` |
| HUD / pause UI / stick | `scripts/ui/*`, `scenes/ui/hud.tscn` |
| Music / death SFX | `scripts/core/audio_manager.gd`, `scenes/systems/audio_manager.tscn` |
| Input map | `project.godot` → `[input]` |

### Autoloads

Registered in `project.godot` as:

- `GameStateAutoload` → `scripts/core/game_state.gd`
- `AudioManagerAutoload` → `scenes/systems/audio_manager.tscn`

Use **`GameState.instance`** / **`AudioManager.instance`** in code (avoids Autoload name clashes with `class_name`).

## Controls

| Action | Default |
|--------|---------|
| Move | WASD / arrows / stick / on-screen joystick |
| Start | Enter / Space / Start button |
| Pause | Esc / P / Pause button |

## License / assets

`audio/house_in_a_forest_loop.ogg` Copyright © 2012 [HorrorPen](https://opengameart.org/users/horrorpen), [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/).  
Images from kenney.nl “Abstract Platformer”, [CC0](https://creativecommons.org/publicdomain/zero/1.0/).  
Font “Xolonium” — see `fonts/LICENSE.txt`.
