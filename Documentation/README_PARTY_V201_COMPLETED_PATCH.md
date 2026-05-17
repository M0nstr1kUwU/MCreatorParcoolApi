# MCreatorParcoolApi v2.0.1 — completed Party GUI / Overlay / Weight patch

This patch is based on the current `v2.0.1` layout and contains complete replacement templates, not only snippets.

## Add / verify in `generator.yaml`

```yaml
  - template: party_api_server_config.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiServerConfig.java"

  - template: party_api_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiSystem.java"

  - template: party_api_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/PartyApiNetwork.java"

  - template: party_api_client.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/PartyApiClient.java"

  - template: party_api_commands.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiCommands.java"

  - template: parcool_api_weight_config.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/weight/ParCoolApiWeightConfig.java"

```

If these entries already exist, do not duplicate them; just replace the template files.

## Full replacement files

```text
src/main/resources/neoforge-1.21.1/templates/party_api_server_config.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_system.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_network.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_client.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_commands.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_weight_config.java.ftl
```

## Delete generated Java before regenerating

```text
src/main/java/net/mcreator/<modid>/party/PartyApiServerConfig.java
src/main/java/net/mcreator/<modid>/party/PartyApiSystem.java
src/main/java/net/mcreator/<modid>/network/PartyApiNetwork.java
src/main/java/net/mcreator/<modid>/client/PartyApiClient.java
src/main/java/net/mcreator/<modid>/party/PartyApiCommands.java
src/main/java/net/mcreator/<modid>/weight/ParCoolApiWeightConfig.java
```

Then run:

```text
Regenerate code
```

## Added / changed party behavior

- `showSelf` is per-player and defaults to `false`.
- Overlay position is now synced as absolute `x/y`.
- Default overlay position is `x=8`, `y=74`, about 50 px higher than old left-center placement.
- Overlay nickname scale defaults to `80%`.
- Overlay food bar is moved 1 px higher.
- Invite GUI has online player list, search field, Invite/Revoke buttons.
- Invite popup has Accept / Decline.
- Pending invite blocks repeated invite to same target until accepted, declined, revoked, or expired.
- Main GUI has Pin/Unpin and Kick buttons.
- Settings GUI has show-self, PvP, reset position.
- Admin GUI opens only for players with configured admin permission.
- Party chat no longer sends "Party message sent" after every message.
- Only online party members are rendered/synced to GUI/overlay.

## New / updated commands

```text
/party gui
/party invitegui
/party settingsgui
/party position <x> <y>
/party showself <true|false>
/party revoke <player>
/party chat <message>
/party admin ...
```

## New procedure blocks

Party blocks:

```text
set party show self of ENTITY to VALUE
party show self of ENTITY
set party overlay position of ENTITY to x X y Y
reset party overlay position of ENTITY
set party overlay element ELEMENT_ID of ENTITY to x X y Y
add party overlay value entry ...
add party overlay bar entry ...
clear custom party overlay entries of ENTITY
open party invite GUI for ENTITY
open party settings GUI for ENTITY
open party admin GUI for ENTITY
```

Weight blocks:

```text
set weight system enabled to ENABLED
is weight system enabled
set weight default punishments enabled to ENABLED
set weight punishment stage STAGE percent PERCENT disable jump DISABLE_JUMP darkness DARKNESS
```

## Config files

Party config:

```text
config/<modid>-party-server.toml
```

Important values:

```toml
party_enabled=true
default_show_self=false
default_overlay_x=8
default_overlay_y=74
overlay_nickname_font_scale_percent=80
invite_cooldown_seconds=120
invite_gui_enabled=true
default_max_members=4
hard_max_members=200
admin_permission_level=2
```

Weight config:

```text
config/<modid>-weight-server.toml
```

Important values:

```toml
weight_enabled=true
use_default_punishments=true
stage_1_percent=75
stage_2_percent=100
stage_3_percent=150
stage_4_percent=200
stage_4_darkness=true
```

## Assets

Recommended folder:

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

Supported fallback asset names:

```text
overlay_member_frame.png
overlay_hp_empty.png
overlay_hp_full.png
overlay_absorption.png
overlay_food_empty.png
overlay_food_full.png
gui_background.png
gui_member_frame.png
gui_button.png
gui_button_hover.png
```

If a texture is missing, the client uses fallback rectangle rendering.
