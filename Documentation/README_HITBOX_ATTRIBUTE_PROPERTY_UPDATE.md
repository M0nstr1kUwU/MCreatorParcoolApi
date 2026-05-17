# Hitbox / Attribute / Entity Property Full Update

## Add to `generator.yaml`

```yaml
  - template: hitbox_api_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/hitbox/HitboxApiBridge.java"

  - template: attribute_api_bridge.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/attributes/AttributeApiBridge.java"

  - template: attribute_api_modbus.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/attributes/AttributeApiModBus.java"

```

## New toolboxes

```text
hitbox_tools
attribute_tools
entity_property_tools
```

## Helper templates

```text
src/main/resources/neoforge-1.21.1/templates/hitbox_api_bridge.java.ftl
src/main/resources/neoforge-1.21.1/templates/attribute_api_bridge.java.ftl
src/main/resources/neoforge-1.21.1/templates/attribute_api_modbus.java.ftl
```

## Hitbox blocks

```text
hitbox width of ENTITY
hitbox height of ENTITY
eye height of ENTITY
bounding box x size of ENTITY
bounding box y size of ENTITY
bounding box z size of ENTITY
persistent hitbox width of ENTITY
persistent hitbox height of ENTITY
set temporary hitbox of ENTITY width WIDTH height HEIGHT
set persistent hitbox of ENTITY width WIDTH height HEIGHT
multiply persistent hitbox of ENTITY width xWIDTH_MULTIPLIER height xHEIGHT_MULTIPLIER
clear persistent hitbox of ENTITY
refresh hitbox dimensions of ENTITY
does ENTITY have persistent hitbox
```

## Attribute blocks

```text
base attribute ATTRIBUTE_ID of ENTITY
final attribute ATTRIBUTE_ID of ENTITY
set base attribute ATTRIBUTE_ID of ENTITY to VALUE
add VALUE to base attribute ATTRIBUTE_ID of ENTITY
multiply base attribute ATTRIBUTE_ID of ENTITY by VALUE
does ENTITY have attribute ATTRIBUTE_ID
```

Example attribute ids:

```text
minecraft:max_health
minecraft:movement_speed
minecraft:scale
minecraft:gravity
minecraft:step_height
minecraft:attack_damage
minecraft:attack_speed
minecraft:armor
minecraft:armor_toughness
minecraft:luck
minecraft:block_interaction_range
minecraft:entity_interaction_range
minecraft:safe_fall_distance
minecraft:fall_damage_multiplier
```

## Entity / player property blocks

```text
health of ENTITY
max health of ENTITY
set health of ENTITY to VALUE
heal ENTITY by VALUE
damage ENTITY by VALUE
absorption of ENTITY
set absorption of ENTITY to VALUE
air supply of ENTITY
set air supply of ENTITY to VALUE
fire ticks of ENTITY
set fire ticks of ENTITY to VALUE
freeze ticks of ENTITY
set freeze ticks of ENTITY to VALUE
is ENTITY no gravity
set no gravity of ENTITY to VALUE
is ENTITY glowing
set glowing of ENTITY to VALUE
is ENTITY invulnerable
set invulnerable of ENTITY to VALUE
is ENTITY silent
set silent of ENTITY to VALUE
is custom name visible of ENTITY
set custom name visible of ENTITY to VALUE
food level of ENTITY
set food level of ENTITY to VALUE
saturation of ENTITY
set saturation of ENTITY to VALUE
set exhaustion of ENTITY to VALUE
```

## Why persistent hitboxes are not temporary

`set temporary hitbox` calls `setBoundingBox(...)`, but Minecraft can recalculate the box later.

`set persistent hitbox` saves width and height in world `SavedData` and reapplies it inside `EntityEvent.Size`, then calls `refreshDimensions()`.

## Cleanup after installing

Delete generated files before regenerating:

```text
src/main/java/net/mcreator/<modid>/hitbox/HitboxApiBridge.java
src/main/java/net/mcreator/<modid>/attributes/AttributeApiBridge.java
src/main/java/net/mcreator/<modid>/attributes/AttributeApiModBus.java
```

Then run:

```text
Regenerate code
```

## Note

If one of the constants in `AttributeApiModBus` does not compile in your mappings, remove only that line. The universal attribute blocks still work through registry id for registered attributes.
