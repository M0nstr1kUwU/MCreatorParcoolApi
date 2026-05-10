# MCreator ParCool API Bridge

Production-oriented **MCreator 2025.3** plugin bridge for **ParCool** on **NeoForge 1.21.1**.

The plugin adds MCreator procedure blocks, helper classes, and custom triggers for:

- ParCool movement ability checks and restrictions;
- ParCool permission / limitation synchronization;
- ParCool stamina helpers;
- server-to-client camera perspective switching;
- delayed server-to-client camera switching;
- client-side delayed execution utilities;
- item enchantment stripping;
- inventory weight and overload mechanics;
- weight values for vanilla and modded items;
- custom triggers for ParCool, camera, item, and weight systems.

The plugin is designed for multiplayer. Gameplay-authoritative logic runs on the server. Client-only logic, such as camera perspective switching, is executed on the target client through packets.

---

## Requirements

Recommended target:

- MCreator 2025.3
- NeoForge 1.21.1
- ParCool NeoForge 1.21.1

ParCool must be loaded on both client and server runtime.

In the server log, you should see something like:

```text
ParCool! ... (parcool)
```

If ParCool is available only at compile time but is not loaded at runtime, ParCool permission syncing and movement restriction logic will not work correctly.

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

These helper classes are generated into the target MCreator workspace:

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

Minimal content:

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

If your MCreator setup treats this YAML as a full generator definition instead of merging it as an overlay, copy these `base_templates` entries into your generator overlay configuration instead of using a minimal standalone file.

---

# ParCool movement ability blocks

## Boolean / condition blocks

These blocks return `Boolean`:

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

## Action blocks

These are server-side action blocks. They use ParCool server limitations and then sync the updated permissions to the player.

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

To restore all movement abilities:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

---

# ParCool permission sync

## Block

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

Some ParCool versions load and sync player limitations only after the player has fully joined. Delaying the sync by 20-40 server ticks helps avoid first-join permission issues.

---

# Camera switching

## Immediate camera switch

```text
switch camera perspective of [entity] to [perspective]
```

Available perspectives:

- first person
- third person back
- third person front

This is a server-triggered, client-executed action. The server sends a packet to the target player, and the client changes the local camera type.

Example:

```text
When cutscene starts:
    switch camera perspective of Event/target entity to third person back
```

---

## Delayed camera switch

```text
switch camera perspective of [entity] to [perspective] after [ticks] client ticks
```

Use this instead of nesting the camera block inside `client wait`.

Correct:

```text
switch camera perspective of Event/target entity to third person back after 20 client ticks
```

Avoid this pattern:

```text
client wait 20 ticks:
    switch camera perspective ...
```

That pattern may silently do nothing because `client wait` runs client-side, while the packet-backed camera block expects to be triggered server-side.

---

# Client wait

## Block

```text
for client player [entity] wait [ticks] client ticks then:
    do ...
```

This queues delayed work on the physical client of the selected player.

Use it for logic that is already running on the client, such as:

- visual-only effects;
- HUD / UI logic;
- local checks;
- client-only cosmetic actions.

Important limitation:

A server cannot send arbitrary nested generated Java code to the client. If a server-side procedure needs to cause a client-side action, create a dedicated packet-backed block for that action. The camera switcher is implemented this way.

---

# Item enchantment stripping

## Block

```text
strip all enchantments from item [item]
```

The input uses `MCItem` for MCreator UI compatibility, but the template converts it to `ItemStack` internally using MCreator's item conversion pattern.

It removes:

- normal enchantments;
- stored enchantments from enchanted books.

Recommended usage:

```text
strip all enchantments from item in main hand of Event/target entity
```

If you pass a plain item type such as `Items.DIAMOND_SWORD`, the code creates a temporary stack. For real inventory changes, pass an actual item stack through `itemstack_to_mcitem`.

---

# Stamina blocks

The plugin includes helpers for reading and changing ParCool stamina.

Typical blocks:

- add ParCool stamina;
- consume ParCool stamina;
- get current ParCool stamina;
- get max ParCool stamina;
- get stamina percent rounded to selected decimals;
- check if stamina is exhausted;
- set current stamina;
- set max stamina;
- get stamina recovery attribute;
- set stamina recovery attribute.

Avoid calling stamina setters too early on player join. If you need join-time setup, delay it by a few server ticks and force-sync ParCool permissions afterwards.

---

# Weight system

The weight system assigns unit weight to items and calculates total carried weight.

Included inventory sources:

- main inventory;
- armor inventory;
- offhand inventory.

Formula:

```text
total weight = sum(item unit weight * stack count)
```

Player-specific values are persisted in player persistent data:

- max carry weight;
- automatic weight system enabled/disabled;
- last known weight status.

This prevents the main player weight settings from resetting after reconnecting or reloading the world.

---

## Weight setup blocks

### Set weight for all registered items

```text
set weight of all registered items to [number]
```

Recommended on server start:

```text
set weight of all registered items to 1
```

### Set specific item weight

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

### Set item weight by string ID

```text
set weight of item with id [string] to [number]
```

Use this for items from other mods.

Examples:

```text
set weight of item with id "minecraft:stone" to 2
set weight of item with id "create:andesite_alloy" to 1.5
set weight of item with id "farmersdelight:cabbage" to 0.4
```

If the string does not contain a namespace, the plugin treats it as a Minecraft item ID.

Example:

```text
"stone" -> "minecraft:stone"
```

---

## Weight read blocks

### Unit weight of item

```text
unit weight of item [item]
```

Returns the configured weight of one item unit.

This is different from stack weight. For example, if one stone has weight `2`, a stack of 64 stones has stack weight `128`.

### Stack weight of item

```text
stack weight of item [item]
```

Returns:

```text
unit weight * stack count
```

### Unit weight by string ID

```text
unit weight of item with id [string]
```

Useful for checking configured weight for modded items.

### Inventory weight

```text
inventory weight of [entity]
```

Returns the player's total carried weight.

### Max carry weight

```text
max carry weight of [entity]
```

### Load percent, rounded

```text
carry load percent of [entity] rounded to [decimals] decimals
```

Examples:

```text
75 = first penalty threshold
125 = heavy overload threshold
175 = severe overload threshold
200 = critical overload threshold
```

### Is overloaded by weight

```text
is [entity] overloaded by weight
```

Returns `true` when player load is at least `75%`.

---

## Weight control blocks

### Set max carry weight

```text
set max carry weight of [entity] to [number]
```

Example:

```text
set max carry weight of Event/target entity to 64
```

This value is persisted in the player's persistent data.

### Enable or disable automatic weight system

```text
set automatic weight system for [entity] to [true/false]
```

This value is persisted in the player's persistent data.

### Manual update

```text
update weight overload state for [entity]
```

Forces recalculation and applies or clears overload effects and ParCool limitations.

---

# Weight overload stages

The current overload system starts penalties at **75%** load and uses staged thresholds up to **200%**.

| Status | Meaning | Threshold |
|---:|---|---|
| 0 | Normal | `< 75%` |
| 1 | Light overload | `75% - 124%` |
| 2 | Heavy overload | `125% - 174%` |
| 3 | Severe overload | `175% - 199%` |
| 4 | Critical overload | `>= 200%` |

## Status 0 — normal

No penalties.

## Status 1 — light overload

Effects:

- Slowness I

ParCool restrictions:

- none

## Status 2 — heavy overload

Effects:

- Slowness II
- Mining Fatigue I

ParCool restrictions:

- FastRun

## Status 3 — severe overload

Effects:

- Slowness III
- Mining Fatigue II
- Weakness I

ParCool restrictions:

- FastRun
- ChargeJump
- JumpFromBar
- HorizontalWallRun
- VerticalWallRun

## Status 4 — critical overload

Effects:

- strong Slowness
- Mining Fatigue III
- Weakness II
- Darkness

ParCool restrictions:

- FastRun
- ChargeJump
- JumpFromBar
- HorizontalWallRun
- VerticalWallRun
- ClimbUp
- ClimbPoles
- HangDown
- ClingToCliff

When the player goes below the restriction threshold, the weight-specific ParCool limitation is cleared.

---

# Custom triggers

The plugin adds custom global triggers.

Custom trigger files live in:

```text
src/main/resources/triggers/
src/main/resources/neoforge-1.21.1/triggers/
```

The trigger templates use MCreator's `procedureDependenciesCode` pattern, so the generated procedure receives only the dependencies it actually uses.

---

## Weight triggers

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

---

## ParCool movement trigger

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

---

## Permission sync trigger

### ParCool permissions force synced

Dependencies:

- `entity`
- `world`

---

## Camera trigger

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

---

## Item trigger

### ParCool item enchantments stripped

Dependencies:

- `itemstack`

---

## Client trigger

### ParCool client wait finished

Dependencies:

- `entity`
- `world`

This trigger fires on the physical client.

---

# Recommended setup

## Server start procedure

```text
set weight of all registered items to 1
set weight of item stone to 2
set weight of item cobblestone to 2
set weight of item iron ingot to 1.5
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5

set weight of item with id "create:andesite_alloy" to 1.5
set weight of item with id "farmersdelight:cabbage" to 0.4
```

## Player join procedure

```text
set max carry weight of Event/target entity to 64
set automatic weight system for Event/target entity to true
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

Since max carry weight and auto-enabled state are persistent, you do not need to set them every join unless you want to reset or update player configuration.

---

# Multiplayer notes

Server-side systems:

- weight calculation;
- overload effects;
- ParCool movement limitations;
- permission sync requests;
- stamina helpers;
- enchantment stripping.

Client-side systems:

- camera perspective switch;
- delayed camera switch;
- client wait;
- local visual/UI behavior.

Camera changes are client-only and must be packet-backed.

---

# Troubleshooting

## ParCool works only after reconnect

Use this on player join:

```text
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

## Movement stays disabled

Run:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

Also check server config folders for ParCool limitations.

## Delayed camera switch does not work

Do not put the camera block inside client wait. Use:

```text
switch camera perspective of Event/target entity to third person back after 20 client ticks
```

## Weight does not update

Make sure automatic weight system is enabled:

```text
set automatic weight system for Event/target entity to true
```

or manually call:

```text
update weight overload state for Event/target entity
```

## Unit item weight returns 0

Use the updated `unit weight of item` block for item type weight, and `stack weight of item` for stack total weight.

If you are working with a modded item, prefer string ID blocks:

```text
unit weight of item with id "modid:item_name"
```

## Item enchant stripping does not affect inventory

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

# Development notes

The plugin intentionally keeps gameplay logic server-authoritative. Client-only systems are isolated and should not modify server gameplay state directly.

Keep MCreator version, NeoForge version, and ParCool version aligned. ParCool internal packages and methods differ between versions, so compatibility wrappers use reflection for sync methods where needed.
