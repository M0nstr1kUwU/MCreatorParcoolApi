# MCreator ParCool API Bridge

Плагин для **MCreator 2025.3**, который интегрирует **ParCool** с **NeoForge 1.21.1**.

Целевая версия ParCool:

```text
ParCool-1.21.1-3.4.3.3-NF.jar
CurseForge file id: 7760593
Curse Maven: curse.maven:parcool-482378:7760593
```

Плагин рассчитан на мультиплеер: игровая логика выполняется на сервере, а клиентские функции вроде камеры, HUD и GUI работают через packets/client helpers.

---

## Требования

```text
MCreator: 2025.3
Minecraft: 1.21.1
Loader: NeoForge
ParCool: 1.21.1-3.4.3.3-NF
Java: 21
```

Рекомендуемая зависимость:

```gradle
implementation "curse.maven:parcool-482378:7760593"
```

Рекомендуемый API-файл:

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

Включить API:

```text
Workspace settings -> External APIs -> ParCool API
```

---

## Base templates

Добавь в:

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

## Стиль имён

Входы procedure-блоков используют **UPPER_CASE**:

```text
ENTITY, TARGET, LEADER, VALUE, WEIGHT, ENABLED, ITEM, ITEM_ID,
DECIMALS, TICKS, X, Y, Z, X1, Y1, Z1, X2, Y2, Z2,
AMOUNT, DELAY, RADIUS, WIDTH, HEIGHT, KEY, POSITION
```

Dependencies триггеров остаются **lower_case**.

---

# Возможности плагина

## ParCool movement

Проверки:

```text
can ENTITY ParCool sprint
can ENTITY ParCool climb
can ENTITY ParCool wall-run
can ENTITY ParCool jump
is ENTITY currently ParCool hanging
```

Действия:

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

Рекомендуемая синхронизация при входе:

```text
wait 40 ticks
request ParCool client handshake for Event/target entity
force sync ParCool permissions to Event/target entity
```

## Vanilla jump

```text
set vanilla jump disabled for ENTITY to ENABLED
```

Используется системой веса при heavy-перегрузе и выше.

## Stamina

Getter-блоки:

```text
ParCool stamina of ENTITY
ParCool max stamina of ENTITY
ParCool stamina percent of ENTITY rounded to DECIMALS decimals
is ENTITY ParCool exhausted
ParCool stamina recovery attribute of ENTITY
```

Action-блоки:

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

Удаляет обычные зачарования, stored enchantments и glint override.

## Weight system

Хранение:

```text
world/data/<modid>_parcool_api_weight_system_v2.dat
```

Блоки:

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

Стадии:

| Статус | Порог | Значение |
|---:|---|---|
| 0 | `< 75%` | норма |
| 1 | `75% - 124%` | лёгкий перегруз |
| 2 | `125% - 174%` | сильный перегруз, vanilla jump disabled |
| 3 | `175% - 199%` | тяжёлый перегруз |
| 4 | `>= 200%` | критический перегруз, Darkness, all ParCool movements disabled |

## Party tools

Хранение:

```text
world/data/<modid>_party_api_system_v1.dat
```

Команды:

```text
/party create
/party invite <player>
/party accept
/party leave
/party kick <player>
/party pvp <true|false>
/party showself <true|false>
/party pin <player>
/party unpin <player>
/party position <position>
/party gui
```

Блоки:

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

Overlay показывает только online-участников. Отображается до 4 закреплённых участников; если никто не закреплён — первые 4 online-участника.

---

# Кастомизация ассетов Party UI

Party UI поддерживает необязательные PNG-ассеты. Если текстура есть, плагин использует её. Если текстуры нет, используется стандартный минималистичный UI на прямоугольниках.

Папка:

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

В готовом JAR:

```text
assets/<modid>/textures/gui/party/
```

Имена файлов — в нижнем регистре.

## Ассеты overlay

| Файл | Размер | Назначение |
|---|---:|---|
| `overlay_member_frame.png` | `96x19` | фон/рамка участника |
| `overlay_hp_empty.png` | `88x3` | пустая HP-полоска |
| `overlay_hp_full.png` | `88x3` | заполненная HP-полоска |
| `overlay_absorption.png` | `88x3` | golden HP поверх HP |
| `overlay_food_empty.png` | `88x2` | пустая полоска еды |
| `overlay_food_full.png` | `88x2` | заполненная полоска еды |
| `overlay_saturation.png` | `88x2` | saturation поверх еды |

Разметка overlay:

```text
frame: 96x19
никнейм: x + 4, y + 2
HP:      x + 4, y + 11, 88x3
еда:     x + 4, y + 16, 88x2
```

## Ассеты Party GUI

| Файл | Размер | Назначение |
|---|---:|---|
| `gui_background.png` | `320x220` | фон GUI по центру |
| `gui_member_frame.png` | `280x28` | фон/рамка участника |
| `gui_hp_empty.png` | `90x4` | пустая HP-полоска |
| `gui_hp_full.png` | `90x4` | заполненная HP-полоска |
| `gui_absorption.png` | `90x4` | golden HP поверх HP |
| `gui_food_empty.png` | `90x3` | пустая полоска еды |
| `gui_food_full.png` | `90x3` | заполненная полоска еды |
| `gui_saturation.png` | `90x3` | saturation поверх еды |
| `button_pin.png` | `44x16` | кнопка Pin |
| `button_unpin.png` | `44x16` | кнопка Unpin |

Разметка GUI:

```text
background: по центру 320x220
строка: 280x28
никнейм: x + 8, y + 5
HP:      x + 8, y + 17, 90x4
еда:     x + 8, y + 23, 90x3
кнопка:  x + 228, y + 6, 44x16
```

Каждый ассет необязателен. Можно заменить только рамку, только полоски или только фон. Всё отсутствующее автоматически отрисуется стандартно.

Рекомендации:

```text
PNG
прозрачность где нужно
точные размеры из таблиц
lowercase имена
без пробелов
```

Проверочный путь:

```text
assets/<modid>/textures/gui/party/<file>.png
```

## Hitbox tools

```text
hitbox width of ENTITY
hitbox height of ENTITY
set hitbox of ENTITY to width WIDTH height HEIGHT
refresh hitbox dimensions of ENTITY
```

Прямое изменение hitbox может быть временным, потому что Minecraft может обновить dimensions сущности.

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

## Cleanup после изменения templates

Удали generated helper-файлы и сделай Regenerate code:

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

Чистые тестовые данные:

```text
run/world/data/<modid>_parcool_api_weight_system_v2.dat
run/world/data/<modid>_party_api_system_v1.dat
run/world/serverconfig/parcool/limitations/parcool_api/
```
