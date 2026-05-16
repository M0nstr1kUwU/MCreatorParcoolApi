# MCreator ParCool API

MCreator 2025.3 plugin for integrating **ParCool** with **NeoForge 1.21.1**.

Target ParCool build:

```text
ParCool-1.21.1-3.4.3.3-NF.jar
CurseForge file id: 7760593
Curse Maven: curse.maven:parcool-482378:7760593
```

The plugin adds:

- ParCool movement checks and restrictions;
- ParCool stamina blocks;
- ParCool client/server synchronization helpers;
- packet-backed camera switching;
- inventory weight and overload mechanics;
- item enchantment stripping;
- utility blocks for item spawning, areas, distance checks, inventory operations, and entity motion;
- custom triggers for weight, movement, camera, item, and client events.

The plugin is multiplayer-oriented: gameplay logic runs on the server, while client-only actions are executed through packets.

---

## Requirements

```text
MCreator: 2025.3
Minecraft: 1.21.1
Loader: NeoForge
ParCool: 1.21.1-3.4.3.3-NF
Java: 21
```

ParCool must be installed on both client and server.

Recommended API dependency file:

```text
src/main/resources/apis/parcool_api.yaml
```

```yaml
name: ParCool API

neoforge-1.21.1:
  required_when_enabled: true
  gradle: |
    repositories {
      maven { url "https://cursemaven.com" }
    }

    dependencies {
      implementation "curse.maven:parcool-482378:7760593"
    }
```

Enable it in:

```text
Workspace settings -> External APIs -> ParCool API
```

If you use Nexus Compiler or another dependency helper, point it to the same ParCool build.

---

## Important folders

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

---

## Base templates

`src/main/resources/neoforge-1.21.1/generator.yaml` should include:

```yaml
base_templates:
  - template: parcool_api_runtime.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/parcool/ParCoolApiRuntime.java"

  - template: parcool_api_bridge_events.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/events/ParCoolApiBridgeEvents.java"

  - template: parcool_api_movement_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/parcool/ParCoolApiMovementBridge.java"

  - template: parcool_api_stamina_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/parcool/ParCoolApiStaminaBridge.java"

  - template: parcool_api_stamina_monitor.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/parcool/ParCoolApiStaminaMonitor.java"

  - template: parcool_api_weight_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/weight/ParCoolApiWeightSystem.java"

  - template: parcool_api_camera_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/ParCoolApiCameraNetwork.java"

  - template: parcool_api_client_scheduler.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/ParCoolApiClientScheduler.java"
```

Generated helper classes:

```text
<mod package>/parcool/ParCoolApiRuntime.java
<mod package>/events/ParCoolApiBridgeEvents.java
<mod package>/parcool/ParCoolApiMovementBridge.java
<mod package>/parcool/ParCoolApiStaminaBridge.java
<mod package>/parcool/ParCoolApiStaminaMonitor.java
<mod package>/weight/ParCoolApiWeightSystem.java
<mod package>/network/ParCoolApiCameraNetwork.java
<mod package>/client/ParCoolApiClientScheduler.java
```

---

## Naming convention

All procedure block inputs use **UPPER_CASE**:

```text
ENTITY, VALUE, WEIGHT, ENABLED, ITEM, ITEM_ID, DECIMALS, TICKS,
X, Y, Z, X1, Y1, Z1, X2, Y2, Z2, AMOUNT, DELAY, RADIUS
```

Trigger dependencies stay **lower_case**:

```text
entity, world, current_weight, max_weight, load_percent,
old_status, new_status, ability_id, enabled, perspective_id, itemstack, event
```

---

# ParCool movement blocks

Boolean checks:

```text
can ENTITY ParCool sprint
can ENTITY ParCool climb
can ENTITY ParCool wall-run
can ENTITY ParCool jump
is ENTITY currently ParCool hanging
```

Action blocks:

```text
disable ParCool sprint ability for ENTITY
disable ParCool climb ability for ENTITY
disable ParCool jump ability for ENTITY
disable ParCool hang ability for ENTITY
disable ParCool wall-run ability for ENTITY
disable all ParCool movement abilities for ENTITY
enable all ParCool movement abilities for ENTITY
force sync ParCool permissions to ENTITY
request ParCool client handshake for ENTITY
```

Movement restrictions use the newer ParCool API:

```java
com.alrex.parcool.api.unstable.Limitation
```

The bridge applies runtime restrictions by calling:

```text
Limitation.get(player, id)
enable / disable
permit(action, true/false)
apply
```

`disable all ParCool movement abilities` iterates through:

```java
com.alrex.parcool.common.action.Actions.LIST
```

so all registered ParCool actions are affected.

---

# ParCool client/server sync

ParCool needs the client to send local client settings to the server. The bridge sends a repeated client handshake using:

```java
ClientInformationPayload(playerUUID, true, ClientSetting.readFromLocalConfig())
```

Recommended join logic:

```text
When player joins world:
    wait 40 ticks
    request ParCool client handshake for Event/target entity
    force sync ParCool permissions to Event/target entity
```

---

# Stamina blocks

Getter blocks:

```text
ParCool stamina of ENTITY
ParCool max stamina of ENTITY
ParCool stamina percent of ENTITY rounded to DECIMALS decimals
is ENTITY ParCool exhausted
ParCool stamina recovery attribute of ENTITY
```

Setter/action blocks:

```text
add VALUE ParCool stamina to ENTITY
consume VALUE ParCool stamina from ENTITY
set ParCool stamina of ENTITY to VALUE
set ParCool max stamina of ENTITY to VALUE
set ParCool stamina recovery of ENTITY to VALUE
```

Setter blocks are server-side and require `ServerPlayer`.

The bridge uses:

```java
com.alrex.parcool.api.Stamina
com.alrex.parcool.api.Attributes.MAX_STAMINA
com.alrex.parcool.api.Attributes.STAMINA_RECOVERY
```

Stamina monitor block:

```text
for ENTITY if ParCool stamina reached 0 run until full:
    DO
```

Behavior:

```text
stamina above 0  -> does nothing
stamina reaches 0 -> starts nested blocks
stamina recovering -> keeps running nested blocks
stamina full -> stops nested blocks
```

---

# Camera blocks

```text
switch camera perspective of ENTITY to PERSPECTIVE
switch camera perspective of ENTITY to PERSPECTIVE after TICKS client ticks
```

Available perspectives:

```text
first person
third person back
third person front
```

Camera switching is packet-backed because camera control is client-only.

Use the delayed camera block instead of putting the camera block inside client wait.

---

# Client wait

```text
for client player ENTITY wait TICKS client ticks then:
    DO
```

Use this for client-side visual/UI/cosmetic logic. A server cannot send arbitrary nested Java code to the client; for server-triggered client actions, use dedicated packet-backed blocks.

---

# Item enchantment stripping

```text
strip all enchantments from item ITEM
```

Removes:

- normal enchantments;
- stored enchantments;
- enchantment glint override.

Use a real item stack, such as the item in the player's main hand, if you want to modify inventory contents.

---

# Weight system

The weight system calculates:

```text
total weight = sum(unit item weight * stack count)
```

Included sources:

```text
main inventory
armor
offhand
```

Data storage:

```text
world/data/<modid>_parcool_api_weight_system_v2.dat
```

Runtime maps are only cache. Legacy player persistent data is only used for migration/fallback.

Weight setup blocks:

```text
set weight of all registered items to WEIGHT
set weight of item ITEM to WEIGHT
set weight of item with id ITEM_ID to WEIGHT
```

`set weight of all registered items to X` sets the default item weight and clears specific overrides.

For modded items, use registry IDs:

```text
minecraft:stone
create:andesite_alloy
farmersdelight:cabbage
```

Weight getter blocks:

```text
unit weight of item ITEM
stack weight of item ITEM
unit weight of item with id ITEM_ID
inventory weight of ENTITY
max carry weight of ENTITY
carry load percent of ENTITY rounded to DECIMALS decimals
is ENTITY overloaded by weight
```

Weight control blocks:

```text
set max carry weight of ENTITY to WEIGHT
set automatic weight system for ENTITY to ENABLED
update weight overload state for ENTITY
```

---

## Weight stages

| Status | Meaning | Threshold |
|---:|---|---|
| 0 | Normal | `< 75%` |
| 1 | Light overload | `75% - 124%` |
| 2 | Heavy overload | `125% - 174%` |
| 3 | Severe overload | `175% - 199%` |
| 4 | Critical overload | `>= 200%` |

Effects:

```text
Status 1: Slowness I
Status 2: Slowness II, Mining Fatigue I, sprint restriction
Status 3: Slowness III, Mining Fatigue II, Weakness I, sprint/jump/wall-run restrictions
Status 4: strong Slowness, Mining Fatigue III, Weakness II, Darkness, all ParCool movement restrictions
```

---

# Utility blocks

```text
spawn item ITEM at x X y Y z Z amount AMOUNT pickup delay DELAY despawnable? DESPAWNABLE
if entity ENTITY is inside cuboid x1 X1 y1 Y1 z1 Z1 x2 X2 y2 Y2 z2 Z2: DO
count item ITEM in inventory of ENTITY
remove item ITEM amount AMOUNT from inventory of ENTITY
give item ITEM amount AMOUNT to ENTITY drop overflow? DROP_OVERFLOW
if entity ENTITY is within radius RADIUS from x X y Y z Z: DO
distance from entity ENTITY to x X y Y z Z
set motion of entity ENTITY to x X y Y z Z
```

`DELAY` in the spawn item block is pickup delay in ticks.

---

# Custom triggers

Weight triggers:

```text
ParCool weight status changed
ParCool player became overloaded
ParCool player stopped being overloaded
ParCool player entered heavy overload
ParCool player entered critical overload
```

Movement trigger:

```text
ParCool movement ability changed by plugin
```

Permission sync trigger:

```text
ParCool permissions force synced
```

Camera trigger:

```text
ParCool camera perspective requested
```

Item trigger:

```text
ParCool item enchantments stripped
```

Client trigger:

```text
ParCool client wait finished
```

Trigger dependencies remain lower-case and are passed through `procedureDependenciesCode`.

---

# Recommended setup

Server start:

```text
set weight of all registered items to 1
set weight of item stone to 2
set weight of item cobblestone to 2
set weight of item iron ingot to 1.5
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5
set weight of item with id "create:andesite_alloy" to 1.5
```

Player join:

```text
set automatic weight system for Event/target entity to true
wait 40 ticks
request ParCool client handshake for Event/target entity
force sync ParCool permissions to Event/target entity
update weight overload state for Event/target entity
```

Set max carry weight only when you intentionally want to initialize or change it:

```text
set max carry weight of Event/target entity to 200
```

---

# Cleanup before testing

Delete generated files before regenerating after major template changes:

```text
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiMovementBridge.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiStaminaBridge.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiStaminaMonitor.java
src/main/java/net/mcreator/<modid>/client/ParCoolApiClientScheduler.java
src/main/java/net/mcreator/<modid>/network/ParCoolApiCameraNetwork.java
src/main/java/net/mcreator/<modid>/weight/ParCoolApiWeightSystem.java
```

For clean tests, remove old data:

```text
run/world/data/<modid>_parcool_api_weight_system.dat
run/world/data/<modid>_parcool_api_weight_system_v2.dat
run/world/serverconfig/parcool/limitations/parcool_api/mcreator_bridge/
```

---

# Troubleshooting

## ParCool does not work on first join

Make sure the loaded ParCool build is:

```text
1.21.1-3.4.3.3-NF
```

Then call after player join delay:

```text
request ParCool client handshake
force sync ParCool permissions
```

## Disable all movement does nothing

Check generated Java. It should use:

```java
com.alrex.parcool.api.unstable.Limitation
com.alrex.parcool.common.action.Actions.LIST
```

Also check that the procedure block uses `ENTITY`.

## Weight penalties still count from 64

Check that the block uses `ENTITY` and `WEIGHT`, runs server-side, and old weight data was deleted before testing.

## Item weight returns 0

Check that the templates use:

```text
ITEM
ITEM_ID
WEIGHT
```

For modded items, prefer:

```text
unit weight of item with id "modid:item_name"
```
