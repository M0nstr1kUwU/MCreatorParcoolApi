# MCreator ParCool API Bridge

Плагин для **MCreator 2025.3** под **NeoForge 1.21.1**, который добавляет блоки процедур и триггеры для интеграции с модом **ParCool**.

Главная цель плагина — дать удобный мост между визуальными процедурами MCreator и возможностями ParCool:

- управление движениями ParCool;
- синхронизация разрешений ParCool между сервером и клиентом;
- работа со стаминой;
- переключение камеры игрока через серверный вызов и клиентский packet;
- клиентская задержка выполнения;
- снятие зачарований с предмета;
- система веса инвентаря и перегруза;
- кастомные триггеры для всех этих механик.

Плагин проектируется с учётом мультиплеера: игровая логика выполняется на сервере, а клиентские действия, например смена камеры, отправляются конкретному игроку через сетевой пакет.

---

## Требования

Рекомендуемая связка:

- MCreator 2025.3;
- NeoForge 1.21.1;
- ParCool для NeoForge 1.21.1.

ParCool должен быть доступен и на клиенте, и на сервере.

Пример зависимости в API-файле плагина:

```gradle
implementation "curse.maven:parcool-482378:<file_id>"
```

---

## Структура плагина

Основные папки:

```text
src/main/resources/apis/
src/main/resources/procedures/
src/main/resources/triggers/
src/main/resources/neoforge-1.21.1/procedures/
src/main/resources/neoforge-1.21.1/triggers/
src/main/resources/neoforge-1.21.1/templates/
```

Важные генерируемые Java-классы:

```text
<package>/events/ParCoolApiBridgeEvents.java
<package>/parcool/ParCoolApiMovementBridge.java
<package>/weight/ParCoolApiWeightSystem.java
<package>/network/ParCoolApiCameraNetwork.java
<package>/client/ParCoolApiClientScheduler.java
```

Они должны генерироваться через `base_templates`.

---

## Настройка base_templates
### *[!] В плагине он уже есть*
Создай файл:

```text
src/main/resources/neoforge-1.21.1/generator.yaml
```

Содержимое:

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

Файлы-шаблоны должны лежать здесь:

```text
src/main/resources/neoforge-1.21.1/templates/parcool_api_bridge_events.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_movement_bridge.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_weight_system.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_camera_network.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_client_scheduler.java.ftl
```

Если MCreator ругается на минимальный `generator.yaml`, значит в твоей структуре нужно не создавать новый YAML, а добавить секцию `base_templates` в уже существующий generator overlay.

---

# Блоки ParCool movement abilities

## Проверки

Эти блоки возвращают `true` или `false`:

- может ли игрок использовать ParCool sprint;
- может ли игрок использовать ParCool climb;
- может ли игрок использовать ParCool wall-run;
- может ли игрок использовать ParCool jump;
- висит ли игрок сейчас на ParCool hanging/cling action.

Пример использования:

```text
если игрок может ParCool climb:
    отправить сообщение "Ты можешь карабкаться"
```

---

## Отключение способностей

Блоки отключения принимают условие и игрока:

```text
if [condition] disable ParCool sprint ability for [entity]
if [condition] disable ParCool climb ability for [entity]
if [condition] disable ParCool jump ability for [entity]
if [condition] disable ParCool hang ability for [entity]
if [condition] disable ParCool wall-run ability for [entity]
if [condition] disable all ParCool movement abilities for [entity]
```

Эти блоки работают серверно. Они создают или изменяют ParCool limitation для игрока и затем синхронизируют разрешения с клиентом.

Пример:

```text
если игрок перегружен:
    disable ParCool sprint ability
    disable ParCool jump ability
    disable ParCool wall-run ability
```

---

## Включение способностей

Блок:

```text
enable all ParCool movement abilities for [entity]
```

Он отключает limitation, созданный bridge-системой, и синхронизирует разрешения игроку.

Используй его, если нужно восстановить движения после перегруза, катсцены или другого ограничения.

---

# Принудительная синхронизация ParCool

Блок:

```text
force sync ParCool permissions to [entity]
```

Он заставляет сервер отправить игроку текущие ParCool permissions/limitations.

Рекомендуемое использование при входе игрока:

```text
When player joins world:
    wait 40 ticks
    force sync ParCool permissions to Event/target entity
```

Это полезно, если ParCool на выделенном сервере начинает нормально обмениваться данными только после небольшой задержки.

---

# Переключение камеры

Блок:

```text
switch camera perspective of [entity] to [perspective]
```

Доступные варианты:

- first person;
- third person back;
- third person front.

Смена камеры — клиентская операция. Поэтому блок вызывается на сервере, но фактическое действие выполняется на клиенте через packet.

Пример:

```text
Когда начинается катсцена:
    switch camera perspective of Event/target entity to third person back
```

---

# Клиентский wait

Блок:

```text
for client player [entity] wait [ticks] client ticks then:
    do ...
```

Он ставит задачу в очередь на физическом клиенте выбранного игрока.

Подходит для:

- клиентских визуальных эффектов;
- HUD/UI-логики;
- задержки перед сменой камеры;
- локальных клиентских проверок.

Важно: этот блок не может передать произвольный вложенный Java-код с сервера на клиент. Если действие должно стартовать на сервере и выполниться на клиенте, для него нужен отдельный packet-блок, как у переключения камеры.

---

# Снятие зачарований с предмета

Блок:

```text
strip all enchantments from item [item]
```

Он удаляет:

- обычные зачарования;
- stored enchantments у enchanted book.

Вход принимает `MCItem`, но внутри конвертируется в `ItemStack`.

Для реального изменения предмета в инвентаре нужно передавать настоящий stack, например:

```text
item in main hand of Event/target entity
```

Если передать просто тип предмета, например Diamond Sword из списка предметов, будет создан временный stack, и реальный предмет в инвентаре не изменится.

---

# Система веса

Система веса считает общий вес игрока по формуле:

```text
общий вес = сумма(вес предмета * количество предметов в стаке)
```

Учитываются:

- основной инвентарь;
- броня;
- offhand.

---

## Блоки настройки веса

### Задать вес всем предметам

```text
set weight of all registered items to [number]
```

Пример:

```text
set weight of all registered items to 1
```

Лучше вызывать один раз при старте сервера, а потом переопределять отдельные предметы.

---

### Задать вес конкретному предмету

```text
set weight of item [item] to [number]
```

Примеры:

```text
set weight of item stone to 2
set weight of item cobblestone to 2
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5
```

---

## Блоки получения веса

### Вес предмета

```text
weight of item [item]
```

Если передан настоящий stack, вернёт вес всего stack.  
Если передан простой тип предмета, вернёт вес одной единицы.

---

### Вес инвентаря игрока

```text
inventory weight of [entity]
```

Возвращает общий вес инвентаря, брони и offhand.

---

### Максимальный переносимый вес

```text
max carry weight of [entity]
```

---

### Процент нагрузки

```text
carry load percent of [entity]
```

Примеры значений:

```text
100 = ровно лимит
125 = перегруз на 25%
150 = критический порог
```

---

### Проверка перегруза

```text
is [entity] overloaded by weight
```

Возвращает `true`, если:

```text
inventory weight > max carry weight
```

---

## Блоки управления системой веса

### Задать лимит веса игроку

```text
set max carry weight of [entity] to [number]
```

Пример:

```text
set max carry weight of Event/target entity to 64
```

---

### Включить или выключить авто-систему веса

```text
set automatic weight system for [entity] to [true/false]
```

Если включено, система сама пересчитывает вес игрока каждые несколько тиков.

---

### Вручную обновить состояние перегруза

```text
update weight overload state for [entity]
```

Сразу пересчитывает вес и применяет или снимает эффекты/ограничения.

---

# Стадии перегруза

| Статус | Название | Порог |
|---|---|---|
| 0 | Норма | `<= 100%` |
| 1 | Перегруз | `> 100%` |
| 2 | Сильный перегруз | `> 125%` |
| 3 | Критический перегруз | `> 150%` |

---

## Статус 1 — перегруз

Эффекты:

- Slowness I.

---

## Статус 2 — сильный перегруз

Эффекты:

- Slowness II;
- Mining Fatigue I.

Ограничения ParCool:

- sprint;
- jump;
- wall-run.

---

## Статус 3 — критический перегруз

Эффекты:

- сильная Slowness;
- Mining Fatigue II;
- Weakness I.

Ограничения ParCool:

- sprint;
- jump;
- wall-run;
- climb;
- hang.

Когда вес возвращается в норму, limitation от системы веса снимается.

---

# Триггеры

Плагин добавляет кастомные global triggers.

---

## ParCool weight status changed

Срабатывает при любом изменении статуса веса.

Зависимости:

- `entity`;
- `world`;
- `old_status`;
- `new_status`;
- `current_weight`;
- `max_weight`;
- `load_percent`.

---

## ParCool player became overloaded

Срабатывает, когда игрок впервые переходит из нормы в перегруз.

Зависимости:

- `entity`;
- `world`;
- `current_weight`;
- `max_weight`;
- `load_percent`.

---

## ParCool player stopped being overloaded

Срабатывает, когда игрок возвращается к нормальному весу.

Зависимости:

- `entity`;
- `world`;
- `current_weight`;
- `max_weight`;
- `load_percent`.

---

## ParCool player entered heavy overload

Срабатывает при входе в сильный перегруз.

Зависимости:

- `entity`;
- `world`;
- `current_weight`;
- `max_weight`;
- `load_percent`.

---

## ParCool player entered critical overload

Срабатывает при входе в критический перегруз.

Зависимости:

- `entity`;
- `world`;
- `current_weight`;
- `max_weight`;
- `load_percent`.

---

## ParCool movement ability changed by plugin

Срабатывает, когда плагин включает или выключает ParCool-движения.

Зависимости:

- `entity`;
- `world`;
- `ability_id`;
- `enabled`.

ID способностей:

| ID | Способность |
|---|---|
| 1 | sprint |
| 2 | climb |
| 3 | jump |
| 4 | hang |
| 5 | wall-run |
| 6 | all movements |

---

## ParCool permissions force synced

Срабатывает после принудительной синхронизации permissions/limitations.

Зависимости:

- `entity`;
- `world`.

---

## ParCool camera perspective requested

Срабатывает, когда сервер запросил смену камеры игрока.

Зависимости:

- `entity`;
- `world`;
- `perspective_id`.

ID камеры:

| ID | Камера |
|---|---|
| 0 | first person |
| 1 | third person back |
| 2 | third person front |

---

## ParCool item enchantments stripped

Срабатывает после снятия зачарований с предмета.

Зависимости:

- `itemstack`.

---

## ParCool client wait finished

Срабатывает на клиенте, когда client wait завершился.

Зависимости:

- `entity`;
- `world`.

---

# Рекомендуемая настройка

## При старте сервера

```text
set weight of all registered items to 1
set weight of item stone to 2
set weight of item cobblestone to 2
set weight of item iron ingot to 1.5
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5
```

---

## При входе игрока

```text
set max carry weight of Event/target entity to 64
set automatic weight system for Event/target entity to true
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

---

# Что выполняется на сервере

- расчёт веса;
- эффекты перегруза;
- ограничения ParCool;
- включение/выключение ParCool abilities;
- force sync permissions;
- работа со stamina/max stamina;
- снятие зачарований с item stack.

---

# Что выполняется на клиенте

- смена камеры;
- client wait;
- клиентские визуальные/HUD-действия.

---

# Частые проблемы

## ParCool начинает работать только после перезахода

Добавь при входе игрока:

```text
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

---

## Движения остались выключенными

Используй:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

Также проверь папки serverconfig ParCool на наличие limitations.

---

## Вес не обновляется

Проверь, включена ли автоматическая система:

```text
set automatic weight system for Event/target entity to true
```

Или вызови вручную:

```text
update weight overload state for Event/target entity
```

---

## Снятие зачарований не меняет предмет

Передавай настоящий stack из инвентаря, например:

```text
item in main hand of Event/target entity
```

Не передавай просто тип предмета из списка, если хочешь изменить предмет игрока.

---

# Рекомендации по production-использованию

- Не вызывай stamina/set max stamina слишком рано при входе игрока.
- Для ParCool permissions используй задержку 20–40 тиков после входа.
- Для перегруза используй серверную weight system, а не клиентские проверки.
- Для камеры используй только packet-backed camera block.
- Проверяй, что ParCool установлен и на клиенте, и на сервере.
