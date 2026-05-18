# Party Admin + Name Visibility + GUI Bars Patch

## Что исправлено

1. Больше нет `snippets/*.txt` как обязательной замены.
   Теперь в архиве лежит полный файл:

```text
src/main/resources/neoforge-1.21.1/templates/party_api_client.java.ftl
```

2. Admin GUI теперь не заглушка.
   Он получает от сервера расширенный список онлайн-игроков с информацией о party:

```text
uuid
name
inMyParty
pendingInvite
partyId
leaderId
leaderName
partySize
partyMaxMembers
partyLeader
```

3. Для этого обновлены полные файлы:

```text
party_api_system.java.ftl
party_api_network.java.ftl
party_api_client.java.ftl
```

4. В Main Party GUI возвращены HP/food bars союзников.
   Invite GUI не показывает боевую статистику союзников — там только онлайн-игроки, поиск, статус и invite/revoke.

5. В overlay food bar возвращён вниз:
```java
int foodY = y + 15;
```
а не `y + 14`, чтобы он не был вплотную к HP bar.

6. Добавлены блоки скрытия ника / TAB list.

---

## Новые / обновлённые replacement files

Скопируй:

```text
src/main/resources/neoforge-1.21.1/templates/party_api_system.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_network.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_client.java.ftl
src/main/resources/neoforge-1.21.1/templates/party_api_name_visibility.java.ftl
```

В `generator.yaml` добавь, если такого entry ещё нет:

```yaml
  - template: party_api_name_visibility.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiNameVisibility.java"
```

Если у тебя уже есть entries для system/network/client — не дублируй, просто замени сами `.ftl`.

После замены удали generated Java:

```text
src/main/java/net/mcreator/<modid>/party/PartyApiSystem.java
src/main/java/net/mcreator/<modid>/network/PartyApiNetwork.java
src/main/java/net/mcreator/<modid>/client/PartyApiClient.java
src/main/java/net/mcreator/<modid>/party/PartyApiNameVisibility.java
```

Потом:

```text
Regenerate code
Build
```

---

## Новые блоки ника

### 1. Hide name tag of player

```text
hide name tag of ENTITY
```

Скрывает ник над игроком через scoreboard team с `NameTagVisibility.NEVER`.

### 2. Show name tag of player

```text
show name tag of ENTITY
```

Возвращает ник над игроком и пытается восстановить прошлую scoreboard team.

### 3. Hide name tags of all players

```text
hide name tags of all players
```

Скрывает ники над всеми онлайн-игроками.

### 4. Show name tags of all players

```text
show name tags of all players
```

Показывает ники всем онлайн-игрокам.

### 5. Hide player from server TAB list

```text
hide ENTITY from server tab list
```

Отправляет клиентам `ClientboundPlayerInfoRemovePacket`.
Это визуально убирает игрока из TAB.

### 6. Show player in server TAB list

```text
show ENTITY in server tab list
```

Отправляет клиентам `ClientboundPlayerInfoUpdatePacket`, чтобы вернуть игрока в TAB.

> Важно: TAB list — это клиентский список. Если другой мод активно синхронизирует player info, он может снова вернуть игрока. В helper добавлен login hook, чтобы новые игроки тоже не видели уже скрытых из TAB игроков.

---

## Как теперь устроен Admin GUI

Admin GUI показывает не просто список игроков, а party-информацию:

```text
Party leader: Axel (3/4)
Axel ★ leader
Party: Axel | Size: 3/4
UUID: ...

Teammate1
Party: Axel | Size: 3/4
UUID: ...
```

Кнопки:

```text
System ON
System OFF
Refresh
View
Remove
Disband
PvP ON
PvP OFF
L4
L8
L16
```

Что делает каждая:

| Кнопка | Действие |
|---|---|
| System ON | включает party system |
| System OFF | отключает party system |
| Refresh | заново запрашивает список онлайн-игроков |
| View | открывает party выбранного игрока |
| Remove | удаляет выбранного игрока из его party |
| Disband | распускает party выбранного игрока |
| PvP ON | включает PvP в party выбранного игрока |
| PvP OFF | выключает PvP в party выбранного игрока |
| L4/L8/L16 | ставит лимит party выбранного игрока |

---

## Почему раньше Admin GUI не мог нормально работать

Старая структура `OnlinePlayerSyncData` была слишком бедная:

```text
uuid
name
inMyParty
pendingInvite
```

Этого хватает для Invite GUI, но не хватает для Admin GUI.

Теперь структура расширена:

```text
partyId
leaderId
leaderName
partySize
partyMaxMembers
partyLeader
```

Именно поэтому обновлены сразу 3 файла:

```text
PartyApiSystem
PartyApiNetwork
PartyApiClient
```

Если заменить только client — кнопки будут рисоваться, но сервер не даст нужных данных.

---

## LVL persistent variable в overlay

Есть два нормальных способа.

---

### Способ A: показать LVL как отдельный overlay value в нужной позиции

Подходит, если хочешь вывести LVL в фиксированном месте overlay.

#### Шаг 1. Создай persistent player variable в MCreator

Например:

```text
Name: LVL
Type: Number
Scope: Player persistent
Default: 1
```

#### Шаг 2. Обновляй её где нужно

Например после прокачки:

```text
set persistent variable LVL of player to current LVL + 1
```

#### Шаг 3. На player tick, например раз в 20 тиков

```text
add party overlay value entry for Event/Target entity
    id: "lvl"
    label: "LVL"
    value: text from number persistent LVL
    x: 0
    y: 92
    width: 60
    height: 10
    texture: ""
```

Смысл как с наклейкой на стекле: `x/y` — это смещение от начала party overlay.

Если overlay стоит в:

```text
x = 8
y = 58
```

а entry:

```text
x = 0
y = 92
```

то итоговая позиция на экране будет:

```text
screenX = 8 + 0
screenY = 58 + 92
```

---

### Способ B: показать LVL рядом с каждым участником party

Для этого добавлен блок:

```text
set party stat of ENTITY key "LVL" to VALUE
```

Пример:

```text
On player tick update, every 20 ticks:
    set party stat of Event/Target entity key "LVL" to text from number persistent LVL
```

После этого:
- в party overlay рядом с ником будет `LVL X`;
- в Main Party GUI рядом с ником тоже будет `LVL X`.

Это лучше, если у каждого союзника свой LVL и ты хочешь видеть LVL именно у союзников, а не просто один общий текст на overlay.

---

## Почему Invite GUI не показывает HP/food/LVL

Так и должно быть.

Invite GUI — это список онлайн-игроков для приглашения:

```text
ник
статус
Invite / Revoke
```

Он не должен показывать HP, еду и LVL, потому что эти данные относятся к party members, а не к любому случайному онлайн-игроку.

HP/food/LVL показываются в:

```text
Main Party GUI
Party Overlay
```

---

## Новые procedure blocks

```text
party_hide_player_name_tag
party_show_player_name_tag
party_hide_all_name_tags
party_show_all_name_tags
party_hide_player_from_tab
party_show_player_in_tab

party_set_player_stat
party_clear_player_stat

party_initialize_overlay_layout
party_set_overlay_position_xy
party_add_overlay_value_entry

weight_set_enabled
weight_is_enabled
```

---

## Замечания по совместимости

### Scoreboard team

Скрытие ника над игроком использует scoreboard team:

```java
team.setNameTagVisibility(Team.Visibility.NEVER)
```

Если другой мод или твои команды активно меняют scoreboard teams, они могут конфликтовать. Helper запоминает прошлую team и пытается вернуть её при `show name tag`.

### TAB list

Скрытие из TAB работает пакетами:

```java
ClientboundPlayerInfoRemovePacket
ClientboundPlayerInfoUpdatePacket
```

Это визуальное client-side скрытие. Оно не удаляет игрока с сервера и не кикает его.

---

## Проверка после установки

```text
[ ] runServer compile
[ ] runClient compile
[ ] /party admin gui <player> открывает не заглушку
[ ] Admin GUI показывает party leader и размер party
[ ] View открывает party выбранного игрока
[ ] Disband распускает party выбранного игрока
[ ] PvP ON/OFF меняет PvP выбранной party
[ ] L4/L8/L16 меняет лимит
[ ] Main Party GUI снова показывает HP/food барами
[ ] Invite GUI НЕ показывает HP/food/LVL
[ ] Food bar в overlay не прилипает к HP
[ ] hide name tag скрывает ник над игроком
[ ] hide from TAB убирает игрока из TAB list
```
