# MCreator ParCool API Bridge

Production-oriented MCreator plugin bridge for **ParCool** on **NeoForge 1.21.1**.

This plugin adds MCreator procedure blocks and custom triggers for:

- ParCool movement ability checks and restrictions
- ParCool permission synchronization
- ParCool stamina helpers
- server-to-client camera switching
- client-side wait utilities
- item enchantment stripping
- inventory weight / overload mechanics

The plugin is designed for multiplayer. Gameplay-authoritative logic runs on the server. Client-only logic, such as camera perspective changes, is executed on the target client through packets.

---

## Requirements

Recommended target:

- MCreator 2025.3
- NeoForge 1.21.1
- ParCool NeoForge 1.21.1

The workspace must load ParCool on both sides. In server logs, you should see something similar to:

```text
ParCool! ... (parcool)
```

If ParCool is only present at compile time but not loaded at runtime, movement permission syncing will not work correctly.

---

## Important plugin folders

```text
src/main/resources/plugin.json
src/main/resources/apis/
src/main/resources/procedures/
src/main/resources/triggers/
src/main/resources/neoforge-1.21.1/procedures/
src/main/resources/neoforge-1.21.1/triggers/
src/main/resources/neoforge-1.21.1/templates/
src/main/resources/neoforge-1.21.1/generator.yaml
```

The `generator.yaml` file is required for generating shared helper classes from `base_templates`.

---

## Required generated helper classes

These classes are generated into the target mod workspace:

```text
<mod package>/events/ParCoolApiBridgeEvents.java
<mod package>/parcool/ParCoolApiMovementBridge.java
<mod package>/weight/ParCoolApiWeightSystem.java
<mod package>/network/ParCoolApiCameraNetwork.java
<mod package>/client/ParCoolApiClientScheduler.java
```

They come from:

```text
src/main/resources/neoforge-1.21.1/templates/parcool_api_bridge_events.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_movement_bridge.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_weight_system.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_camera_network.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_client_scheduler.java.ftl
```

---

## `generator.yaml`

Path:

```text
src/main/resources/neoforge-1.21.1/generator.yaml
```

Minimal content used by this plugin:

```yaml
base_templates:
  - template: parcool_api_bridge_events.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/events/ParCoolApiBridgeEvents.java"
  - template: parcool_api_movement_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/parcool/ParCoolApiMovementBridge.java"
  - template: parcool_api_weight_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/weight/ParCoolApiWeightSystem.java"
  - template: parcool_api_camera_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/ParCoolApiCameraNetwork.java"
  - template: parcool_api_client_scheduler.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/ParCoolApiClientScheduler.java"
```

If your MCreator setup does not merge generator overlays and instead treats this as a full generator definition, do not use the minimal YAML directly. In that case, copy these `base_templates` entries into the full `generator.yaml` of the generator overlay you are building.

---

## ParCool movement ability blocks

### Boolean / condition blocks

These return `Boolean`:

- `can [entity] ParCool sprint`
- `can [entity] ParCool climb`
- `can [entity] ParCool wall-run`
- `can [entity] ParCool jump`
- `is [entity] currently ParCool hanging`

Example:

```text
if can Event/target entity ParCool climb:
    send chat message "You can climb"
```

---

### Action blocks

These blocks are server-side and use ParCool server limitations:

- `if [condition] disable ParCool sprint ability for [entity]`
- `if [condition] disable ParCool climb ability for [entity]`
- `if [condition] disable ParCool jump ability for [entity]`
- `if [condition] disable ParCool hang ability for [entity]`
- `if [condition] disable ParCool wall-run ability for [entity]`
- `if [condition] disable all ParCool movement abilities for [entity]`
- `enable all ParCool movement abilities for [entity]`

Recommended usage:

```text
if player enters heavy overload:
    disable ParCool sprint ability
    disable ParCool jump ability
    disable ParCool wall-run ability
```

To restore:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

---

## ParCool permission sync

### Block

```text
force sync ParCool permissions to [entity]
```

Use this when ParCool permissions are not available on the client immediately after joining a dedicated server.

Recommended join procedure:

```text
When player joins world:
    wait 40 ticks
    force sync ParCool permissions to Event/target entity
```

This is useful because some ParCool versions load and sync player limitations after the player has fully joined.

---

## Camera switching

### Block

```text
switch camera perspective of [entity] to [perspective]
```

Available perspectives:

- first person
- third person back
- third person front

This is a server-triggered, client-executed action. The server sends a packet to the target player, and the client changes `Minecraft.options.cameraType`.

Example:

```text
When cutscene starts:
    switch camera perspective of Event/target entity to third person back
```

---

## Client wait

### Block

```text
for client player [entity] wait [ticks] client ticks then:
    do ...
```

This queues delayed work on the physical client of the selected player.

Use it for:

- camera effects
- UI/HUD logic
- local client checks
- visual-only mechanics

Important limitation: a server cannot send arbitrary nested generated Java code to the client. For server-to-client actions, create dedicated packet-backed blocks, as done with the camera switcher.

---

## Item enchantment stripping

### Block

```text
strip all enchantments from item [item]
```

The input uses `MCItem` for MCreator UI compatibility, but the template converts it to `ItemStack` internally using MCreator's `mappedMCItemToItemStackCode(...)` pattern.

It removes:

- normal enchantments
- stored enchantments from enchanted books

Recommended usage:

```text
strip all enchantments from item in main hand of Event/target entity
```

If you pass a plain item type such as `Items.DIAMOND_SWORD`, the code creates a temporary stack. For real inventory changes, pass an actual item stack through `itemstack_to_mcitem`.

---

## Weight system

The weight system gives item types a unit weight and calculates total carried weight.

Included inventory sources:

- main inventory
- armor
- offhand

Formula:

```text
total weight = sum(item unit weight * stack count)
```

---

### Weight setup blocks

#### Set weight for all registered items

```text
set weight of all registered items to [number]
```

Recommended on server start:

```text
set weight of all registered items to 1
```

#### Set specific item weight

```text
set weight of item [item] to [number]
```

Examples:

```text
set weight of item stone to 2
set weight of item iron ingot to 1.5
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5
```

---

### Weight read blocks

#### Weight of item

```text
weight of item [item]
```

Returns stack weight if the input is an item stack, or unit weight for a plain item.

#### Inventory weight

```text
inventory weight of [entity]
```

Returns the player's carried weight.

#### Max carry weight

```text
max carry weight of [entity]
```

#### Load percent

```text
carry load percent of [entity]
```

Examples:

```text
100 = exactly full
125 = heavy overload threshold
150 = critical overload threshold
```

#### Is overloaded

```text
is [entity] overloaded by weight
```

Returns `true` when:

```text
inventory weight > max carry weight
```

---

### Weight control blocks

#### Set max carry weight

```text
set max carry weight of [entity] to [number]
```

Example:

```text
set max carry weight of Event/target entity to 64
```

#### Enable or disable automatic weight system

```text
set automatic weight system for [entity] to [true/false]
```

#### Manual update

```text
update weight overload state for [entity]
```

Forces recalculation and applies or clears overload effects and ParCool limitations.

---

## Overload stages

| Status | Meaning | Threshold |
|---:|---|---|
| 0 | Normal | `<= 100%` |
| 1 | Overloaded | `> 100%` |
| 2 | Heavy overloaded | `> 125%` |
| 3 | Critical overloaded | `> 150%` |

### Status 1

- Slowness I

### Status 2

- Slowness II
- Mining Fatigue I
- disables ParCool sprint
- disables ParCool jump
- disables ParCool wall-run

### Status 3

- stronger Slowness
- Mining Fatigue II
- Weakness I
- disables ParCool sprint
- disables ParCool jump
- disables ParCool wall-run
- disables ParCool climb
- disables ParCool hang

When weight returns to normal, the weight-specific ParCool limitation is cleared.

---

## Custom triggers

The plugin adds custom global triggers.

Custom trigger files live in:

```text
src/main/resources/triggers/
src/main/resources/neoforge-1.21.1/triggers/
```

### ParCool weight status changed

Dependencies:

- `entity`
- `world`
- `old_status`
- `new_status`
- `current_weight`
- `max_weight`
- `load_percent`

Use this for general reactions to all weight status changes.

### ParCool player became overloaded

Dependencies:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool player stopped being overloaded

Dependencies:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool player entered heavy overload

Dependencies:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool player entered critical overload

Dependencies:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool movement ability changed by plugin

Dependencies:

- `entity`
- `world`
- `ability_id`
- `enabled`

Ability IDs:

| ID | Ability |
|---:|---|
| 1 | sprint |
| 2 | climb |
| 3 | jump |
| 4 | hang |
| 5 | wall-run |
| 6 | all movements |

### ParCool permissions force synced

Dependencies:

- `entity`
- `world`

### ParCool camera perspective requested

Dependencies:

- `entity`
- `world`
- `perspective_id`

Perspective IDs:

| ID | Perspective |
|---:|---|
| 0 | first person |
| 1 | third person back |
| 2 | third person front |

### ParCool item enchantments stripped

Dependencies:

- `itemstack`

### ParCool client wait finished

Dependencies:

- `entity`
- `world`

This trigger fires on the physical client.

---

## Recommended setup

### Server start procedure

```text
set weight of all registered items to 1
set weight of item stone to 2
set weight of item cobblestone to 2
set weight of item iron ingot to 1.5
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5
```

### Player join procedure

```text
set max carry weight of Event/target entity to 64
set automatic weight system for Event/target entity to true
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

---

## Multiplayer notes

Server-side systems:

- weight calculation
- overload effects
- ParCool movement limitations
- permission sync requests
- stamina helpers
- enchantment stripping

Client-side systems:

- camera perspective switch
- client wait
- local visual/UI behavior

Camera changes are client-only and must be packet-backed.

---

## Troubleshooting

### ParCool works only after reconnect

Use this on player join:

```text
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

### Movement stays disabled

Run:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

Also check server config folders for ParCool limitations.

### Weight does not update

Make sure automatic weight system is enabled:

```text
set automatic weight system for Event/target entity to true
```

or manually call:

```text
update weight overload state for Event/target entity
```

### Item enchant stripping does not affect inventory

Use an actual item stack, not just a plain item type.

Good:

```text
item in main hand of Event/target entity
```

Bad for inventory mutation:

```text
plain Diamond Sword item type
```

---

## Development notes

The plugin intentionally keeps gameplay logic server-authoritative. Client-only systems are isolated and should not modify server gameplay state directly.

Keep MCreator version, NeoForge version, and ParCool version aligned. ParCool internal packages and methods differ between versions, so compatibility wrappers use reflection for sync methods where needed.
