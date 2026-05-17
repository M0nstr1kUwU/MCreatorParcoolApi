# Party GUI / Overlay / Weight Patch Pack

This zip contains drop-in config helpers, procedure blocks, and integration patch notes for your existing party GUI/network/client code.

## Add to generator.yaml

```yaml
  - template: party_api_server_config.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiServerConfig.java"

  - template: parcool_api_weight_config.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/weight/ParCoolApiWeightConfig.java"

```

## Files included

```text
src/main/resources/neoforge-1.21.1/templates/party_api_server_config.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_weight_config.java.ftl
src/main/resources/procedures/*.json
src/main/resources/neoforge-1.21.1/procedures/*.java.ftl
docs/PARTY_SYSTEM_INTEGRATION_PATCH.md
```

## New party config

Created at:

```text
config/<modid>-party-server.toml
```

Important defaults:

```toml
default_show_self=false
default_overlay_x=8
default_overlay_y=74
overlay_nickname_font_scale_percent=80
invite_cooldown_seconds=120
```

## New weight config

Created at:

```text
config/<modid>-weight-server.toml
```

Includes:

```toml
weight_enabled=true
use_default_punishments=true
stage_1_percent=75
stage_2_percent=100
stage_3_percent=150
stage_4_percent=200
stage_4_darkness=true
```

## New blocks

Party:

```text
set party show self of ENTITY to VALUE
party show self of ENTITY
set party overlay position of ENTITY to x X y Y
reset party overlay position of ENTITY
set party overlay element ELEMENT_ID of ENTITY to x X y Y
add party overlay value entry ...
add party overlay bar entry ...
clear custom party overlay entries of ENTITY
```

Weight:

```text
set weight system enabled to ENABLED
is weight system enabled
set weight default punishments enabled to ENABLED
set weight punishment stage STAGE percent PERCENT disable jump DISABLE_JUMP darkness DARKNESS
```

## GUI implementation notes

Because your current party GUI/client/network files have changed several times, I did not overwrite them blindly in this patch pack. Use:

```text
docs/PARTY_SYSTEM_INTEGRATION_PATCH.md
```

It contains the exact methods and fields to merge into your current PartyApiSystem plus the invite cooldown/showself/XY/custom overlay logic.

## Assets

Recommended path:

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

Suggested sizes:

```text
overlay_panel.png 128x128
overlay_member_frame.png 118x25
overlay_hp_bar_empty.png 92x5
overlay_hp_bar_full.png 92x5
overlay_absorption_bar_full.png 92x5
overlay_food_bar_empty.png 92x4
overlay_food_bar_full.png 92x4
gui_background.png 256x256
gui_button.png 80x20
gui_button_hover.png 80x20
gui_search.png 160x20
gui_scrollbar.png 6x120
gui_member_row.png 220x22
```

Empty config value = fallback rendering.
