# MCreator ParCool API Bridge

A production-oriented **MCreator 2025.3** plugin for integrating **ParCool** with **NeoForge 1.21.1**.

Target ParCool build:

```text
ParCool-1.21.1-3.4.3.3-NF.jar
CurseForge file id: 7760593
Curse Maven: curse.maven:parcool-482378:7760593
```

The plugin is multiplayer-oriented: gameplay logic runs on the server; client-only features such as camera switching, client wait, party HUD and party GUI use packets/client helpers.

---

## Requirements

```text
MCreator: 2025.3
Minecraft: 1.21.1
Loader: NeoForge
ParCool: 1.21.1-3.4.3.3-NF
Java: 21
```

Recommended API dependency:

```gradle
implementation "curse.maven:parcool-482378:7760593"
```

Recommended API file:

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

---

## Base templates

Add these entries to:

```text
src/main/resources/neoforge-1.21.1/generator.yaml
```

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
  - template: parcool_api_vanilla_jump_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/parcool/ParCoolApiVanillaJumpBridge.java"
  - template: parcool_api_weight_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/weight/ParCoolApiWeightSystem.java"
  - template: parcool_api_weight_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/ParCoolApiWeightNetwork.java"
  - template: parcool_api_camera_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/ParCoolApiCameraNetwork.java"
  - template: parcool_api_client_scheduler.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/ParCoolApiClientScheduler.java"
  - template: party_api_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiSystem.java"
  - template: party_api_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/PartyApiNetwork.java"
  - template: party_api_client.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/PartyApiClient.java"
  - template: party_api_commands.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiCommands.java"
  - template: hitbox_api_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/hitbox/HitboxApiBridge.java"
```

---

## Naming convention

All procedure block inputs use **UPPER_CASE**:

```text
ENTITY, TARGET, LEADER, VALUE, WEIGHT, ENABLED, ITEM, ITEM_ID,
DECIMALS, TICKS, X, Y, Z, X1, Y1, Z1, X2, Y2, Z2,
AMOUNT, DELAY, RADIUS, WIDTH, HEIGHT, KEY, POSITION
```

Trigger dependencies remain **lower_case**.

---

# Feature overview

## ParCool movement

Boolean checks:

```text
can ENTITY ParCool sprint
can ENTITY ParCool climb
can ENTITY ParCool wall-run
can ENTITY ParCool jump
is ENTITY currently ParCool hanging
```

Actions:

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

Recommended join sync:

```text
wait 40 ticks
request ParCool client handshake for Event/target entity
force sync ParCool permissions to Event/target entity
```

## Vanilla jump

```text
set vanilla jump disabled for ENTITY to ENABLED
```

Used by weight punishments at heavy overload and above.

## Stamina

Getters:

```text
ParCool stamina of ENTITY
ParCool max stamina of ENTITY
ParCool stamina percent of ENTITY rounded to DECIMALS decimals
is ENTITY ParCool exhausted
ParCool stamina recovery attribute of ENTITY
```

Actions:

```text
add VALUE ParCool stamina to ENTITY
consume VALUE ParCool stamina from ENTITY
set ParCool stamina of ENTITY to VALUE
set ParCool max stamina of ENTITY to VALUE
set ParCool stamina recovery of ENTITY to VALUE
```

Monitor:

```text
for ENTITY if ParCool stamina reached 0 run until full:
    DO
```

## Camera and client wait

```text
switch camera perspective of ENTITY to PERSPECTIVE
switch camera perspective of ENTITY to PERSPECTIVE after TICKS client ticks
for client player ENTITY wait TICKS client ticks then DO
```

## Enchantments

```text
strip all enchantments from item ITEM
```

Removes normal enchantments, stored enchantments and glint override.

## Weight system

Storage:

```text
world/data/<modid>_parcool_api_weight_system_v2.dat
```

Blocks:

```text
set weight of all registered items to WEIGHT
set weight of item ITEM to WEIGHT
set weight of item with id ITEM_ID to WEIGHT
unit weight of item ITEM
stack weight of item ITEM
unit weight of item with id ITEM_ID
inventory weight of ENTITY
max carry weight of ENTITY
carry load percent of ENTITY rounded to DECIMALS decimals
is ENTITY overloaded by weight
set max carry weight of ENTITY to WEIGHT
set automatic weight system for ENTITY to ENABLED
update weight overload state for ENTITY
```

Punishment stages:

| Status | Threshold | Meaning |
|---:|---|---|
| 0 | `< 75%` | normal |
| 1 | `75% - 124%` | light overload |
| 2 | `125% - 174%` | heavy overload, vanilla jump disabled |
| 3 | `175% - 199%` | severe overload |
| 4 | `>= 200%` | critical overload, Darkness, all ParCool movements disabled |

## Party tools

Storage:

```text
world/data/<modid>_party_api_system_v1.dat
```

Commands:

```text
/party create
/party invite <player>
/party accept
/party leave
/party kick <player>
/party pvp <true|false>
/party pin <player>
/party unpin <player>
/party position <position>
/party gui
```

Blocks:

```text
create party with leader ENTITY show self? SHOW_SELF
add player TARGET to party of LEADER
remove player ENTITY from party
set party PvP by ENTITY to ENABLED
open party GUI for ENTITY
set party overlay position for ENTITY to POSITION
set party show self for ENTITY to ENABLED
set party overlay stat KEY of ENTITY to VALUE
```

The overlay shows online party members only. Up to 4 pinned members are displayed; if nobody is pinned, the first 4 online members are shown.

---

# Party UI asset customization

The party UI supports optional PNG assets. If a texture exists, the plugin uses it. If it does not exist, the plugin falls back to the built-in minimal rectangle UI.

Asset folder:

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

In the final JAR:

```text
assets/<modid>/textures/gui/party/
```

Use lowercase file names.

## Overlay assets

Overlay is the small in-game HUD.

| File | Size | Purpose |
|---|---:|---|
| `overlay_member_frame.png` | `96x19` | row background/frame |
| `overlay_hp_empty.png` | `88x3` | empty HP bar |
| `overlay_hp_full.png` | `88x3` | filled HP bar |
| `overlay_absorption.png` | `88x3` | golden HP overlay |
| `overlay_food_empty.png` | `88x2` | empty food bar |
| `overlay_food_full.png` | `88x2` | filled food bar |
| `overlay_saturation.png` | `88x2` | saturation overlay |

Overlay layout:

```text
frame: 96x19
nickname: x + 4, y + 2
HP bar:   x + 4, y + 11, 88x3
food bar: x + 4, y + 16, 88x2
```

## Party GUI assets

| File | Size | Purpose |
|---|---:|---|
| `gui_background.png` | `320x220` | centered GUI background |
| `gui_member_frame.png` | `280x28` | row background/frame |
| `gui_hp_empty.png` | `90x4` | empty HP bar |
| `gui_hp_full.png` | `90x4` | filled HP bar |
| `gui_absorption.png` | `90x4` | golden HP overlay |
| `gui_food_empty.png` | `90x3` | empty food bar |
| `gui_food_full.png` | `90x3` | filled food bar |
| `gui_saturation.png` | `90x3` | saturation overlay |
| `button_pin.png` | `44x16` | Pin button |
| `button_unpin.png` | `44x16` | Unpin button |

GUI layout:

```text
background: centered 320x220
row: 280x28
nickname: x + 8, y + 5
HP bar:   x + 8, y + 17, 90x4
food bar: x + 8, y + 23, 90x3
button:   x + 228, y + 6, 44x16
```

Every asset is optional. You can replace only the frame, only the bars, or only the background. Missing assets fall back to default drawing.

Recommended PNG rules:

```text
use PNG
use transparency where needed
use exact sizes from the tables
use lowercase names
avoid spaces in file names
```

Troubleshooting path:

```text
assets/<modid>/textures/gui/party/<file>.png
```

Make sure `<modid>` matches the generated mod id.

## Hitbox tools

```text
hitbox width of ENTITY
hitbox height of ENTITY
set hitbox of ENTITY to width WIDTH height HEIGHT
refresh hitbox dimensions of ENTITY
```

Direct hitbox changes may be temporary because Minecraft can refresh entity dimensions.

## Utility blocks

```text
spawn item ITEM at x X y Y z Z amount AMOUNT pickup delay DELAY despawnable? DESPAWNABLE
if entity ENTITY is inside cuboid x1 X1 y1 Y1 z1 Z1 x2 X2 y2 Y2 z2 Z2 do DO
count item ITEM in inventory of ENTITY
remove item ITEM amount AMOUNT from inventory of ENTITY
give item ITEM amount AMOUNT to ENTITY drop overflow? DROP_OVERFLOW
if entity ENTITY is within radius RADIUS from x X y Y z Z do DO
distance from entity ENTITY to x X y Y z Z
set motion of entity ENTITY to x X y Y z Z
```

## Custom triggers

```text
ParCool weight status changed
ParCool player became overloaded
ParCool player stopped being overloaded
ParCool player entered heavy overload
ParCool player entered critical overload
ParCool movement ability changed by plugin
ParCool permissions force synced
ParCool camera perspective requested
ParCool item enchantments stripped
ParCool client wait finished
```

## Cleanup after template changes

Delete generated helper files and regenerate code:

```text
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiMovementBridge.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiStaminaBridge.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiStaminaMonitor.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiVanillaJumpBridge.java
src/main/java/net/mcreator/<modid>/weight/ParCoolApiWeightSystem.java
src/main/java/net/mcreator/<modid>/network/ParCoolApiWeightNetwork.java
src/main/java/net/mcreator/<modid>/network/ParCoolApiCameraNetwork.java
src/main/java/net/mcreator/<modid>/client/ParCoolApiClientScheduler.java
src/main/java/net/mcreator/<modid>/party/PartyApiSystem.java
src/main/java/net/mcreator/<modid>/party/PartyApiCommands.java
src/main/java/net/mcreator/<modid>/network/PartyApiNetwork.java
src/main/java/net/mcreator/<modid>/client/PartyApiClient.java
src/main/java/net/mcreator/<modid>/hitbox/HitboxApiBridge.java
```

Clean test data:

```text
run/world/data/<modid>_parcool_api_weight_system_v2.dat
run/world/data/<modid>_party_api_system_v1.dat
run/world/serverconfig/parcool/limitations/parcool_api/
```
