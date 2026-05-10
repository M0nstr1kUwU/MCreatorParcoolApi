# MCreator ParCool API Bridge

Плагин для **MCreator 2025.3** под **NeoForge 1.21.1**, который добавляет блоки процедур, helper-классы и кастомные триггеры для интеграции с модом **ParCool**.

Плагин добавляет:

- проверки и ограничения движений ParCool;
- синхронизацию ParCool permissions / limitations;
- блоки для работы со стаминой;
- переключение камеры с сервера на клиент через packet;
- отложенное переключение камеры;
- клиентскую задержку выполнения;
- снятие зачарований с предметов;
- систему веса инвентаря и перегруза;
- поддержку веса предметов из других модов по строковому ID;
- кастомные триггеры для ParCool, камеры, предметов и веса.

Плагин проектируется под мультиплеер. Вся игровая авторитетная логика выполняется на сервере. Клиентские действия, например смена камеры, выполняются на клиенте конкретного игрока через сетевой пакет.

---

## Требования

Рекомендуемая связка:

- MCreator 2025.3
- NeoForge 1.21.1
- ParCool для NeoForge 1.21.1

ParCool должен быть загружен и на клиенте, и на сервере.

В server log должна быть строка примерно такого вида:

```text
ParCool! ... (parcool)
```

Если ParCool есть только на этапе компиляции, но не загружается во время запуска сервера, синхронизация permissions и ограничения движений работать нормально не будут.

---

## Важные папки плагина

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

Файл `generator.yaml` нужен для генерации общих helper-классов через `base_templates`.

---

## Генерируемые helper-классы

Эти классы создаются в целевом MCreator workspace:

```text
<mod package>/events/ParCoolApiBridgeEvents.java
<mod package>/parcool/ParCoolApiMovementBridge.java
<mod package>/weight/ParCoolApiWeightSystem.java
<mod package>/network/ParCoolApiCameraNetwork.java
<mod package>/client/ParCoolApiClientScheduler.java
```

Они генерируются из шаблонов:

```text
src/main/resources/neoforge-1.21.1/templates/parcool_api_bridge_events.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_movement_bridge.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_weight_system.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_camera_network.java.ftl
src/main/resources/neoforge-1.21.1/templates/parcool_api_client_scheduler.java.ftl
```

---

## `generator.yaml`

Путь:

```text
src/main/resources/neoforge-1.21.1/generator.yaml
```

Минимальное содержимое:

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

Если твоя сборка MCreator воспринимает этот YAML как полный генератор, а не как overlay, не используй минимальный файл отдельно. В таком случае перенеси эти `base_templates` в полноценный generator overlay.

---

# Блоки движений ParCool

## Проверки

Эти блоки возвращают `Boolean`:

- `can [entity] ParCool sprint`
- `can [entity] ParCool climb`
- `can [entity] ParCool wall-run`
- `can [entity] ParCool jump`
- `is [entity] currently ParCool hanging`

Пример:

```text
если Event/target entity может ParCool climb:
    отправить сообщение "Ты можешь карабкаться"
```

---

## Блоки действия

Эти блоки работают на сервере. Они используют ParCool server limitations и затем синхронизируют обновлённые permissions игроку.

- `if [condition] disable ParCool sprint ability for [entity]`
- `if [condition] disable ParCool climb ability for [entity]`
- `if [condition] disable ParCool jump ability for [entity]`
- `if [condition] disable ParCool hang ability for [entity]`
- `if [condition] disable ParCool wall-run ability for [entity]`
- `if [condition] disable all ParCool movement abilities for [entity]`
- `enable all ParCool movement abilities for [entity]`

Пример:

```text
если игрок вошёл в сильный перегруз:
    disable ParCool sprint ability
    disable ParCool jump ability
    disable ParCool wall-run ability
```

Чтобы восстановить движения:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

---

# Синхронизация ParCool permissions

## Блок

```text
force sync ParCool permissions to [entity]
```

Используй его, если ParCool permissions не появляются у клиента сразу после входа на dedicated server.

Рекомендуемая процедура при входе игрока:

```text
When player joins world:
    wait 40 ticks
    force sync ParCool permissions to Event/target entity
```

Некоторые версии ParCool загружают и отправляют player limitations только после полного входа игрока. Задержка 20-40 серверных тиков помогает избежать проблем первого входа.

---

# Переключение камеры

## Мгновенное переключение камеры

```text
switch camera perspective of [entity] to [perspective]
```

Доступные варианты:

- first person
- third person back
- third person front

Это серверный вызов, который выполняется на клиенте. Сервер отправляет пакет целевому игроку, а клиент меняет локальный тип камеры.

Пример:

```text
Когда начинается катсцена:
    switch camera perspective of Event/target entity to third person back
```

---

## Отложенное переключение камеры

```text
switch camera perspective of [entity] to [perspective] after [ticks] client ticks
```

Используй этот блок вместо вложения camera block внутрь `client wait`.

Правильно:

```text
switch camera perspective of Event/target entity to third person back after 20 client ticks
```

Нежелательный вариант:

```text
client wait 20 ticks:
    switch camera perspective ...
```

Такой вариант может молча ничего не сделать, потому что `client wait` выполняет вложенный код на клиенте, а packet-backed camera block должен запускаться на сервере.

---

# Client wait

## Блок

```text
for client player [entity] wait [ticks] client ticks then:
    do ...
```

Он ставит отложенную задачу на физическом клиенте выбранного игрока.

Подходит для логики, которая уже выполняется на клиенте:

- визуальные эффекты;
- HUD / UI;
- локальные проверки;
- чисто клиентские косметические действия.

Важное ограничение:

Сервер не может отправить произвольный вложенный Java-код на клиент. Если серверная процедура должна вызвать клиентское действие, для этого нужен отдельный packet-backed блок. Переключение камеры реализовано именно так.

---

# Снятие зачарований

## Блок

```text
strip all enchantments from item [item]
```

Вход использует `MCItem` для совместимости с UI MCreator, но внутри шаблон конвертирует его в `ItemStack`.

Удаляет:

- обычные зачарования;
- stored enchantments у enchanted book.

Рекомендуемое использование:

```text
strip all enchantments from item in main hand of Event/target entity
```

Если передать обычный тип предмета, например `Items.DIAMOND_SWORD`, код создаст временный stack. Чтобы изменить реальный предмет в инвентаре, нужно передавать настоящий item stack через `itemstack_to_mcitem`.

---

# Блоки стамины

Плагин включает блоки для чтения и изменения ParCool stamina.

Типичные блоки:

- добавить ParCool stamina;
- потратить ParCool stamina;
- получить текущую ParCool stamina;
- получить максимум ParCool stamina;
- получить процент stamina с округлением до выбранного количества знаков;
- проверить exhaustion;
- задать текущую stamina;
- задать max stamina;
- получить stamina recovery attribute;
- задать stamina recovery attribute.

Не вызывай stamina setters слишком рано при входе игрока. Если нужна настройка при входе, лучше делать задержку на несколько серверных тиков и потом вызывать force sync permissions.

---

# Система веса

Система веса задаёт предметам вес одной единицы и считает общий вес игрока.

Учитываются:

- основной инвентарь;
- броня;
- offhand.

Формула:

```text
общий вес = сумма(вес одной единицы предмета * количество в стаке)
```

Значения игрока сохраняются в persistent data:

- максимальный переносимый вес;
- включена ли автоматическая система веса;
- последний известный статус веса.

Это нужно, чтобы настройки игрока не сбрасывались после перезахода или перезагрузки мира.

---

## Блоки настройки веса

### Задать вес всем зарегистрированным предметам

```text
set weight of all registered items to [number]
```

Рекомендуется вызывать при старте сервера:

```text
set weight of all registered items to 1
```

### Задать вес конкретному предмету

```text
set weight of item [item] to [number]
```

Примеры:

```text
set weight of item stone to 2
set weight of item iron ingot to 1.5
set weight of item diamond sword to 5
set weight of item enchanted book to 1.5
```

### Задать вес предмету по строковому ID

```text
set weight of item with id [string] to [number]
```

Это нужно для предметов из других модов.

Примеры:

```text
set weight of item with id "minecraft:stone" to 2
set weight of item with id "create:andesite_alloy" to 1.5
set weight of item with id "farmersdelight:cabbage" to 0.4
```

Если строка не содержит namespace, плагин считает, что это предмет из `minecraft`.

Пример:

```text
"stone" -> "minecraft:stone"
```

---

## Блоки получения веса

### Вес одной единицы предмета

```text
unit weight of item [item]
```

Возвращает настроенный вес одной единицы предмета.

Это не то же самое, что вес всего stack. Например, если один камень весит `2`, то stack из 64 камней весит `128`.

### Вес всего stack

```text
stack weight of item [item]
```

Возвращает:

```text
unit weight * stack count
```

### Вес одной единицы по строковому ID

```text
unit weight of item with id [string]
```

Удобно для проверки веса предметов из других модов.

### Вес инвентаря

```text
inventory weight of [entity]
```

Возвращает общий переносимый вес игрока.

### Максимальный переносимый вес

```text
max carry weight of [entity]
```

### Процент нагрузки с округлением

```text
carry load percent of [entity] rounded to [decimals] decimals
```

Примеры:

```text
75 = первый порог наказаний
125 = порог сильного перегруза
175 = порог тяжёлого перегруза
200 = критический порог
```

### Проверка перегруза

```text
is [entity] overloaded by weight
```

Возвращает `true`, если нагрузка игрока не меньше `75%`.

---

## Блоки управления весом

### Задать максимальный переносимый вес

```text
set max carry weight of [entity] to [number]
```

Пример:

```text
set max carry weight of Event/target entity to 64
```

Это значение сохраняется в persistent data игрока.

### Включить или выключить автоматическую систему веса

```text
set automatic weight system for [entity] to [true/false]
```

Это значение сохраняется в persistent data игрока.

### Вручную обновить состояние веса

```text
update weight overload state for [entity]
```

Сразу пересчитывает вес и применяет или снимает эффекты и ParCool limitations.

---

# Стадии перегруза

Текущая система начинает наказания с **75%** нагрузки и идёт этапами до **200%**.

| Статус | Название | Порог |
|---:|---|---|
| 0 | Норма | `< 75%` |
| 1 | Лёгкий перегруз | `75% - 124%` |
| 2 | Сильный перегруз | `125% - 174%` |
| 3 | Тяжёлый перегруз | `175% - 199%` |
| 4 | Критический перегруз | `>= 200%` |

## Статус 0 — норма

Наказаний нет.

## Статус 1 — лёгкий перегруз

Эффекты:

- Slowness I

Ограничения ParCool:

- нет

## Статус 2 — сильный перегруз

Эффекты:

- Slowness II
- Mining Fatigue I

Ограничения ParCool:

- FastRun

## Статус 3 — тяжёлый перегруз

Эффекты:

- Slowness III
- Mining Fatigue II
- Weakness I

Ограничения ParCool:

- FastRun
- ChargeJump
- JumpFromBar
- HorizontalWallRun
- VerticalWallRun

## Статус 4 — критический перегруз

Эффекты:

- сильная Slowness
- Mining Fatigue III
- Weakness II
- Darkness

Ограничения ParCool:

- FastRun
- ChargeJump
- JumpFromBar
- HorizontalWallRun
- VerticalWallRun
- ClimbUp
- ClimbPoles
- HangDown
- ClingToCliff

Когда игрок возвращается ниже порога ограничения, weight-specific ParCool limitation очищается.

---

# Кастомные триггеры

Плагин добавляет custom global triggers.

Файлы триггеров лежат здесь:

```text
src/main/resources/triggers/
src/main/resources/neoforge-1.21.1/triggers/
```

Шаблоны триггеров используют MCreator-паттерн `procedureDependenciesCode`, поэтому сгенерированная процедура получает только те зависимости, которые реально используются в процедуре.

---

## Триггеры веса

### ParCool weight status changed

Зависимости:

- `entity`
- `world`
- `old_status`
- `new_status`
- `current_weight`
- `max_weight`
- `load_percent`

Подходит для общей реакции на любые изменения статуса веса.

### ParCool player became overloaded

Зависимости:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool player stopped being overloaded

Зависимости:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool player entered heavy overload

Зависимости:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

### ParCool player entered critical overload

Зависимости:

- `entity`
- `world`
- `current_weight`
- `max_weight`
- `load_percent`

---

## Триггер изменения ParCool movement ability

### ParCool movement ability changed by plugin

Зависимости:

- `entity`
- `world`
- `ability_id`
- `enabled`

ID способностей:

| ID | Способность |
|---:|---|
| 1 | sprint |
| 2 | climb |
| 3 | jump |
| 4 | hang |
| 5 | wall-run |
| 6 | all movements |

---

## Триггер синхронизации permissions

### ParCool permissions force synced

Зависимости:

- `entity`
- `world`

---

## Триггер камеры

### ParCool camera perspective requested

Зависимости:

- `entity`
- `world`
- `perspective_id`

ID камеры:

| ID | Камера |
|---:|---|
| 0 | first person |
| 1 | third person back |
| 2 | third person front |

---

## Триггер предметов

### ParCool item enchantments stripped

Зависимости:

- `itemstack`

---

## Клиентский триггер

### ParCool client wait finished

Зависимости:

- `entity`
- `world`

Этот триггер срабатывает на физическом клиенте.

---

# Рекомендуемая настройка

## Процедура при старте сервера

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

## Процедура при входе игрока

```text
set max carry weight of Event/target entity to 64
set automatic weight system for Event/target entity to true
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

Так как max carry weight и auto-enabled сохраняются, их не обязательно задавать при каждом входе, если ты не хочешь сбросить или обновить настройки игрока.

---

# Что работает на сервере

- расчёт веса;
- эффекты перегруза;
- ParCool movement limitations;
- запросы синхронизации permissions;
- блоки стамины;
- снятие зачарований.

# Что работает на клиенте

- переключение камеры;
- отложенное переключение камеры;
- client wait;
- локальная визуальная/UI-логика.

Камера — клиентская настройка, поэтому она должна работать через packet.

---

# Частые проблемы

## ParCool работает только после перезахода

Добавь при входе игрока:

```text
wait 40 ticks
force sync ParCool permissions to Event/target entity
```

## Движения остались выключенными

Выполни:

```text
enable all ParCool movement abilities for Event/target entity
force sync ParCool permissions to Event/target entity
```

Также проверь serverconfig ParCool на наличие limitations.

## Отложенная камера не работает

Не помещай camera block внутрь client wait. Используй:

```text
switch camera perspective of Event/target entity to third person back after 20 client ticks
```

## Вес не обновляется

Проверь, что автоматическая система веса включена:

```text
set automatic weight system for Event/target entity to true
```

или вручную вызови:

```text
update weight overload state for Event/target entity
```

## Unit weight предмета возвращает 0

Используй обновлённый блок `unit weight of item` для веса типа предмета и `stack weight of item` для веса всего stack.

Если работаешь с предметом из другого мода, лучше использовать string-ID блоки:

```text
unit weight of item with id "modid:item_name"
```

## Снятие зачарований не меняет предмет в инвентаре

Используй настоящий item stack, а не просто тип предмета.

Хорошо:

```text
item in main hand of Event/target entity
```

Плохо для изменения инвентаря:

```text
plain Diamond Sword item type
```

---

# Заметки для разработки

Плагин специально держит игровую логику server-authoritative. Клиентские системы изолированы и не должны напрямую менять серверное игровое состояние.

Версии MCreator, NeoForge и ParCool желательно держать согласованными. Внутренние классы и методы ParCool отличаются между версиями, поэтому для некоторых sync-методов используются compatibility wrappers и reflection.
