# MCreator ParCool API Bridge

Плагин для **MCreator 2025.3**, который интегрирует **ParCool** с **NeoForge 1.21.1**.

Целевая версия ParCool:

```text
ParCool-1.21.1-3.4.3.3-NF.jar
CurseForge file id: 7760593
Curse Maven: curse.maven:parcool-482378:7760593
```

Плагин добавляет:

- проверки и ограничения движений ParCool;
- блоки ParCool stamina;
- синхронизацию ParCool client/server;
- packet-backed переключение камеры;
- систему веса и перегруза;
- снятие зачарований с предметов;
- utility-блоки для спавна предметов, зон, дистанций, инвентаря и движения сущностей;
- кастомные триггеры для веса, движений, камеры, предметов и клиента.

Плагин рассчитан на мультиплеер: игровая логика выполняется на сервере, а клиентские действия выполняются через packets.

---

## Требования

```text
MCreator: 2025.3
Minecraft: 1.21.1
Loader: NeoForge
ParCool: 1.21.1-3.4.3.3-NF
Java: 21
```

ParCool должен быть установлен и на клиенте, и на сервере.

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

Включить API нужно здесь:

```text
Workspace settings -> External APIs -> ParCool API
```

Если используется Nexus Compiler или другой dependency helper, там тоже должна быть эта же версия ParCool.

---

## Важные папки

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

`src/main/resources/neoforge-1.21.1/generator.yaml`:

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

Генерируемые классы:

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

## Стиль имён

Все входы procedure-блоков используют **UPPER_CASE**:

```text
ENTITY, VALUE, WEIGHT, ENABLED, ITEM, ITEM_ID, DECIMALS, TICKS,
X, Y, Z, X1, Y1, Z1, X2, Y2, Z2, AMOUNT, DELAY, RADIUS
```

Dependencies триггеров остаются **lower_case**:

```text
entity, world, current_weight, max_weight, load_percent,
old_status, new_status, ability_id, enabled, perspective_id, itemstack, event
```

---

# Движения ParCool

Boolean-блоки:

```text
can ENTITY ParCool sprint
can ENTITY ParCool climb
can ENTITY ParCool wall-run
can ENTITY ParCool jump
is ENTITY currently ParCool hanging
```

Action-блоки:

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

Ограничения используют новый API ParCool:

```java
com.alrex.parcool.api.unstable.Limitation
```

Схема runtime-ограничения:

```text
Limitation.get(player, id)
enable / disable
permit(action, true/false)
apply
```

`disable all ParCool movement abilities` проходит по:

```java
com.alrex.parcool.common.action.Actions.LIST
```

и отключает все зарегистрированные ParCool actions.

---

# ParCool client/server sync

ParCool требует, чтобы клиент отправил серверу свои client settings. Bridge повторно отправляет client handshake:

```java
ClientInformationPayload(playerUUID, true, ClientSetting.readFromLocalConfig())
```

Рекомендуемая процедура входа:

```text
When player joins world:
    wait 40 ticks
    request ParCool client handshake for Event/target entity
    force sync ParCool permissions to Event/target entity
```

---

# Stamina

Getter-блоки:

```text
ParCool stamina of ENTITY
ParCool max stamina of ENTITY
ParCool stamina percent of ENTITY rounded to DECIMALS decimals
is ENTITY ParCool exhausted
ParCool stamina recovery attribute of ENTITY
```

Setter/action-блоки:

```text
add VALUE ParCool stamina to ENTITY
consume VALUE ParCool stamina from ENTITY
set ParCool stamina of ENTITY to VALUE
set ParCool max stamina of ENTITY to VALUE
set ParCool stamina recovery of ENTITY to VALUE
```

Setter-блоки работают на сервере и требуют `ServerPlayer`.

Bridge использует:

```java
com.alrex.parcool.api.Stamina
com.alrex.parcool.api.Attributes.MAX_STAMINA
com.alrex.parcool.api.Attributes.STAMINA_RECOVERY
```

Блок stamina monitor:

```text
for ENTITY if ParCool stamina reached 0 run until full:
    DO
```

Поведение:

```text
stamina выше 0 -> ничего не делает
stamina дошла до 0 -> запускает вложенные блоки
stamina восстанавливается -> продолжает выполнять вложенные блоки
stamina полная -> останавливает вложенные блоки
```

---

# Камера

```text
switch camera perspective of ENTITY to PERSPECTIVE
switch camera perspective of ENTITY to PERSPECTIVE after TICKS client ticks
```

Варианты:

```text
first person
third person back
third person front
```

Камера управляется на клиенте, поэтому используется packet-backed логика.

---

# Client wait

```text
for client player ENTITY wait TICKS client ticks then:
    DO
```

Подходит для клиентской визуальной/UI/косметической логики. Сервер не может передавать произвольный вложенный Java-код клиенту, поэтому для server-triggered client actions нужны отдельные packet-backed blocks.

---

# Снятие зачарований

```text
strip all enchantments from item ITEM
```

Удаляет:

- обычные зачарования;
- stored enchantments;
- enchantment glint override.

Для изменения реального предмета в инвентаре передавай настоящий item stack, например предмет в main hand.

---

# Система веса

Формула:

```text
общий вес = сумма(вес одной единицы предмета * количество в стаке)
```

Учитывается:

```text
основной инвентарь
броня
offhand
```

Данные хранятся здесь:

```text
world/data/<modid>_parcool_api_weight_system_v2.dat
```

Runtime maps — только кэш. Старый player persistentData используется только для migration/fallback.

Блоки настройки:

```text
set weight of all registered items to WEIGHT
set weight of item ITEM to WEIGHT
set weight of item with id ITEM_ID to WEIGHT
```

`set weight of all registered items to X` задаёт default item weight и очищает конкретные overrides.

Для предметов из других модов используй registry IDs:

```text
minecraft:stone
create:andesite_alloy
farmersdelight:cabbage
```

Getter-блоки:

```text
unit weight of item ITEM
stack weight of item ITEM
unit weight of item with id ITEM_ID
inventory weight of ENTITY
max carry weight of ENTITY
carry load percent of ENTITY rounded to DECIMALS decimals
is ENTITY overloaded by weight
```

Блоки управления:

```text
set max carry weight of ENTITY to WEIGHT
set automatic weight system for ENTITY to ENABLED
update weight overload state for ENTITY
```

---

## Стадии перегруза

| Статус | Название | Порог |
|---:|---|---|
| 0 | Норма | `< 75%` |
| 1 | Лёгкий перегруз | `75% - 124%` |
| 2 | Сильный перегруз | `125% - 174%` |
| 3 | Тяжёлый перегруз | `175% - 199%` |
| 4 | Критический перегруз | `>= 200%` |

Эффекты:

```text
Статус 1: Slowness I
Статус 2: Slowness II, Mining Fatigue I, запрет sprint
Статус 3: Slowness III, Mining Fatigue II, Weakness I, запрет sprint/jump/wall-run
Статус 4: сильная Slowness, Mining Fatigue III, Weakness II, Darkness, запрет всех ParCool movements
```

---

# Utility-блоки

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

`DELAY` в spawn item block — это задержка подбора в тиках.

---

# Кастомные триггеры

Триггеры веса:

```text
ParCool weight status changed
ParCool player became overloaded
ParCool player stopped being overloaded
ParCool player entered heavy overload
ParCool player entered critical overload
```

Триггер движения:

```text
ParCool movement ability changed by plugin
```

Триггер sync:

```text
ParCool permissions force synced
```

Триггер камеры:

```text
ParCool camera perspective requested
```

Триггер предметов:

```text
ParCool item enchantments stripped
```

Клиентский триггер:

```text
ParCool client wait finished
```

Dependencies триггеров остаются lower-case и передаются через `procedureDependenciesCode`.

---

# Рекомендуемая настройка

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

Max carry weight задавай только если нужно инициализировать или изменить значение:

```text
set max carry weight of Event/target entity to 200
```

---

# Cleanup перед тестом

После крупных изменений шаблонов удали generated-файлы:

```text
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiMovementBridge.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiStaminaBridge.java
src/main/java/net/mcreator/<modid>/parcool/ParCoolApiStaminaMonitor.java
src/main/java/net/mcreator/<modid>/client/ParCoolApiClientScheduler.java
src/main/java/net/mcreator/<modid>/network/ParCoolApiCameraNetwork.java
src/main/java/net/mcreator/<modid>/weight/ParCoolApiWeightSystem.java
```

Для чистого теста удали старые данные:

```text
run/world/data/<modid>_parcool_api_weight_system.dat
run/world/data/<modid>_parcool_api_weight_system_v2.dat
run/world/serverconfig/parcool/limitations/parcool_api/mcreator_bridge/
```

---

# Частые проблемы

## ParCool не работает при первом входе

Проверь, что сервер загрузил:

```text
1.21.1-3.4.3.3-NF
```

После задержки входа вызови:

```text
request ParCool client handshake
force sync ParCool permissions
```

## Disable all movement ничего не делает

Проверь generated Java. Там должны быть:

```java
com.alrex.parcool.api.unstable.Limitation
com.alrex.parcool.common.action.Actions.LIST
```

Также проверь, что procedure-блок использует `ENTITY`.

## Перегруз всё ещё считается от 64

Проверь, что блок использует `ENTITY` и `WEIGHT`, выполняется на сервере, и старые weight data удалены перед тестом.

## Item weight возвращает 0

Проверь, что templates используют:

```text
ITEM
ITEM_ID
WEIGHT
```

Для modded items лучше использовать:

```text
unit weight of item with id "modid:item_name"
```
