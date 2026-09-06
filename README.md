# Hoof & Spud

**A cosy top-down farming game about twelve-minute days.**

You inherit a plot with a pond, five trees, three rocks, a hen pair, one cow and a
neighbour who talks. Hoe the ground, sow it, water it before dusk, and watch the
field turn over at dawn. Chop the trees for wood, mine the rocks for stone, store
the surplus in a chest, and try not to be standing in the open at 2am — the day
ends whether you are ready or not.

Single-player, offline, no accounts, no network code. Built with **Godot 4.7** in
GDScript.

---

## Features

### The farming loop
- **Tilling, watering, sowing and harvesting** on a 64×40 tile field painted at
  boot, with a pre-hoed starter plot so a new save can sow on day one.
- **Two crops with different economics.** Wheat ripens in three watered days and
  is pulled up whole; eggplant takes six and then regrows, paying back the longer
  wait over the rest of the season.
- **Growth is driven by watered days, not real time.** A crop only advances if its
  cell was damp when the day rolled over, so skipping the watering can costs a day.
- **Damp soil is a tile layer, crops are nodes.** Soil saves as a cell list; each
  plant carries its own stage and growth and Y-sorts with everything else.

### The world
- **Trees and rocks** with health, tool gating (an axe is useless on a rock), hit
  shake, impact flash, and drop tables that scatter pickups which pop out, home in
  on the player and land in the satchel.
- **Animals on navigation-mesh paths** with idle / wander / graze behaviour and
  avoidance, so a hen and a cow can want the same spot without shoving.
- **Produce follows the calendar.** Hens lay every morning; the cow only gives milk
  on mornings after a day she was fed.
- **See-through canopies** — walk behind a tree and it fades instead of swallowing
  the character, which is why props can keep a small footprint instead of an
  invisible wall.
- **A farmhouse**, assembled from atlas sprites, whose door is honest about there
  being no interior yet.

### Time, light and the day
- A clock autoload with a 12-minute day, dawn / day / dusk / night phases, an
  interpolated `CanvasModulate` tint, and a forced 2am pass-out that saves and
  puts you to bed.

### Systems and UI
- **Satchel (24 slots) and chests (12 slots)** with click / shift-click transfers,
  stable slot ordering, and stack limits enforced on the way into the bag.
- **HUD** with clock, day, interact prompt, tool bar and toasts; the mouse cursor
  becomes the tool in hand.
- **Dialogue** with typewriter reveal, first-meeting lines that play once per save,
  and a tree that pauses while you read.
- **Pause menu** with save, audio sliders and a way back to the title screen;
  volumes persist between sessions.
- **One save slot** covering the clock, player position and facing, tool selection,
  inventory, soil state, every crop, every prop's health and regrowth timer, chest
  contents, animal state and who you have met. Versioned, so an older file is
  rejected cleanly rather than half-loading.
- **Audio** with Master, SFX and UI buses (labelled *Master* and *Effects* in the menu), twelve effect voices, pitch jitter on
  repeats and one-shot-per-frame dedupe, plus fifteen synthesised sound effects
  parsed straight from their RIFF headers so playback never depends on an import
  cache.

---

## Tech stack

| Layer | Choice |
| --- | --- |
| Engine | Godot 4.7 (Forward Plus), standard build — no .NET, no GDExtension |
| Language | GDScript, statically typed throughout |
| Rendering | 2D pixel art, nearest-neighbour filtering, 2D transform and vertex snapping |
| Resolution | 640×360 viewport, 1280×720 window, `canvas_items` stretch with `expand` aspect |
| Audio | `AudioStreamWAV` decoded in-engine from `.wav`, three buses, settings in `user://settings.cfg` |
| Persistence | Typed `Resource` save (`SaveData`) via `ResourceSaver`, at `user://savegame.tres` |
| Tooling | `tools/make_sfx.py` (deterministic sound-effect bank) |

### Repository layout

```
hoof-&-spud/                 the Godot project (open this folder)
├── project.godot            input map, autoloads, layer names, pixel settings
├── scenes/                  15 scenes: world, player, props, NPCs, UI
├── scripts/                 49 GDScript files
│   ├── systems/             autoloads: clock, inventory, item registry, audio,
│   │                        save game, scene transitions
│   ├── world/               level root and the day/night tint
│   ├── farming/             soil: tilling, watering, planting, overnight growth
│   ├── entities/            crops, chests, harvestable props
│   ├── components/          health, hurtbox, drops, shake, flash, interactable,
│   │                        dialogue, see-through
│   ├── player/              the player and its states
│   ├── npcs/                animals, villager and their states
│   ├── state_machine/       reusable state machine and state base class
│   ├── ui/                  HUD, panels, dialogue box, menus
│   ├── resources/           data classes: item, crop, tool, drop table, save
│   └── lib/                 sprite-sheet slicing helper
├── resources/               data (.tres): items, crops, tools, drop tables,
│                            theme, audio bus layout, sound effects
├── tilesets/                the farm tileset
├── shaders/                 prop shake shader
├── Assets/                  sprite sheets and their licence
└── tools/                   offline sound-effect generator
```

---

## Installation and running locally

1. **Install Godot 4.7.** Download the standard build (not the .NET one) from
   <https://godotengine.org/download> and unpack it anywhere — it is a single
   executable with no installer.

2. **Get the code.**

   ```bash
   git clone https://github.com/Ats123-ac/hoof-spud.git
   cd hoof-spud
   ```

3. **Open the project.** Launch Godot, choose **Import**, and select
   `hoof-&-spud/project.godot`. The first open imports the sprite sheets and
   creates the local `.godot/` cache; it takes a few seconds and nothing is
   downloaded.

4. **Play.** Press **F5** (or the play button). The main scene is
   `scenes/ui/main_menu.tscn`.

   From a terminal, without opening the editor:

   ```bash
   godot --path hoof-&-spud              # run the game
   godot --path hoof-&-spud -e           # run the editor
   ```

5. **Export (optional).** Project → Export → add a preset for your platform. No
   plugins or native dependencies are required; the sound bank is read from its
   `.wav` files at runtime.

### Save files

Both files live in Godot's per-project user directory and are plain text or plain
`.wav`-adjacent resources you can inspect or delete:

| File | Purpose |
| --- | --- |
| `user://savegame.tres` | the farm — delete it to start over |
| `user://settings.cfg` | audio bus volumes |

That resolves to `%APPDATA%\Godot\app_userdata\Hoof & Spud\` on Windows,
`~/.local/share/godot/app_userdata/Hoof & Spud/` on Linux and
`~/Library/Application Support/Godot/app_userdata/Hoof & Spud/` on macOS.

---

## How to play

### Controls

| Input | Action |
| --- | --- |
| `WASD` / arrow keys | move |
| `Space` or left mouse button | use the tool in hand |
| `E` | interact — harvest, talk, open a chest, collect produce, feed |
| `1`–`6` | select a tool directly |
| `Z` / `X` | cycle the tool bar |
| `I` | satchel |
| `Esc` | pause menu (save, audio, quit to title) |

### Your first day

1. **Start a new farm** from the title screen. You wake at 6am on day one with a
   hoed starter plot, eight bags of wheat seed and four of eggplant.
2. **Sow.** Select a seed bag (`5` or `6`), stand on tilled soil and press `Space`.
   Each sow spends one seed.
3. **Water.** Switch to the watering can (`2`) and water every planted cell. Soil
   that is not damp at dawn does not grow.
4. **Gather.** The axe (`3`) fells trees for 2–4 wood, the mallet (`4`) breaks
   rocks for 1–3 stone. The wrong tool bounces off and says so.
5. **Meet the neighbours.** Press `E` on the villager to talk, on a hen to collect
   its egg, on the cow to feed it wheat — she pays that back as milk the next
   morning.
6. **Store the surplus** in the chest: click moves one item, shift-click moves the
   whole stack.
7. **Sleep is automatic.** At 2am you pass out, the day saves and you wake at 6am.
   Saving by hand is in the `Esc` menu.

### Things worth knowing

- Wheat is a three-day crop you replant; eggplant is a six-day crop that keeps
  producing from a half-grown plant.
- Watering is the only thing that advances growth. One dry day is one lost day.
- Props remember their state: a half-chopped tree comes back as a half-chopped
  tree, and a stump with a regrowth timer grows its canopy back.
- Sound effect and master volumes are stored per machine, not per save.

---

## Architecture notes

**Six autoloads** hold everything global, and they hold only that: `GameClock`
(time, calendar, tint), `Inventory` (id → count), `ItemRegistry` (id → `ItemData`,
scanned from `resources/items`), `Audio` (voices and buses), `SaveGame` (the file,
never the farm) and `SceneSwap` (fades and atomic scene changes).

**Entities are compositions, not inheritance trees.** A tree is a `Node2D` with a
`HealthComponent`, a `HurtboxComponent`, a `DropComponent`, a `ShakeComponent`, a
`HitFlashComponent` and a `SeeThroughComponent`. The same components build the
rock, the chest and the crops, and none of them knows what it is attached to.

**One contract connects the player to everything destructible**: the swing fires
`tool_swung`, the hitbox reports overlapping areas, and any area with a `take_hit`
method receives the tool id and damage. `accepted_tools` decides whether it lands.

**Behaviour is a state machine.** The player runs `Idle`, `Walk` and one state per
tool; animals run `Idle`, `Wander` and `Graze`. The same `StateMachine` and `State`
classes drive both, and states reach their owner through `agent`.

**Data lives in resources, not code.** `ItemData`, `CropData`, `ToolData`,
`DropEntry` / `DropTable` and `SaveData` are all `.tres` files, so adding content
is usually a new resource rather than a code change:

| To add… | Do this |
| --- | --- |
| an item | a new `ItemData` in `resources/items/` — the registry picks it up at boot |
| a crop | a new `CropData` with its stage textures, then a `ToolData` of kind `SEED` pointing at it |
| a tool | a new `ToolData` in `resources/tools/` and an entry in the player's `tools` array; the tool bar grows by itself |
| a prop | a `Node2D` with the harvestable script, a health/hurtbox/drop set and a `DropTable` |
| a sound | a `.wav` in `resources/audio/sfx/` named after the sound — routing is by name |

**Collision layers** are named in `project.godot`: 1 world, 2 player, 3 npc,
4 hurtbox, 5 hitbox, 6 collectable, 7 interactable.

### Regenerating the sound bank

Effects are synthesised, not recorded. The bank is deterministic, so regenerating
it never churns the repository:

```bash
python3 hoof-&-spud/tools/make_sfx.py
```

---

## Credits

Art is from the **Sprout Lands** basic pack by **Cup Nooble**, used under its
non-commercial licence; the terms are kept verbatim in
`hoof-&-spud/Assets/farming sprites/read_me.txt`. Everything else — code, systems,
UI, sound synthesis — is original to this repository.
