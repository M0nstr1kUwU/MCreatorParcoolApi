# MCreatorParcoolApi / ParCool API — полная документация плагина

Документация описывает актуальную архитектуру плагина **ParCool API** для **MCreator 2025.3** и **NeoForge 1.21.1**, включая все добавленные механики: ParCool-интеграцию, stamina, camera, client wait, систему веса, party/GUI/overlay, party assets, экономику, казино, сообщения, хитбоксы, атрибуты и свойства сущностей.

Плагин устроен как набор **helper-классов** и **procedure-блоков**. Проще говоря:

```text
MCreator procedure block
    -> генерирует Java через .java.ftl
        -> вызывает helper-класс
            -> helper работает с Minecraft / NeoForge / ParCool API
```

Такой подход удобен: если в API ParCool или NeoForge что-то меняется, чинится helper, а блоки в MCreator остаются понятными.

---

# 1. Поддерживаемая среда

```text
MCreator: 2025.3
Minecraft: 1.21.1
Loader: NeoForge
ParCool: 1.21.1-3.4.3.3-NF
Plugin id: parcool_api
```

Плагин рассчитан на server-side логику там, где это важно:

```text
вес
экономика
party состав
party PvP
атрибуты
хитбоксы
ParCool limitations
скрытие ников
```

А клиент используется там, где без него нельзя:

```text
GUI
overlay
camera perspective
client wait
визуальные элементы
TAB list packets
```

---

# 2. Главные файлы проекта

## 2.1. Основной plugin file

```text
src/main/resources/plugin.json
```

В нём задаются:

```text
id
supportedversions
name
version
description
author
```

## 2.2. Generator file

```text
src/main/resources/neoforge-1.21.1/generator.yaml
```

Именно он говорит MCreator, какие `.java.ftl` helper-шаблоны должны генерироваться в Java-классы проекта.

Ключевые helper-группы:

```text
parcool/
weight/
party/
network/
client/
economy/
message/
hitbox/
attributes/
events/
```

---

# 3. Как правильно ставить обновления плагина

Когда заменяешь `.java.ftl` helper-шаблоны:

```text
src/main/resources/neoforge-1.21.1/templates/*.java.ftl
```

лучше удалить уже сгенерированные Java-файлы из workspace:

```text
src/main/java/net/mcreator/<modid>/parcool/
src/main/java/net/mcreator/<modid>/weight/
src/main/java/net/mcreator/<modid>/party/
src/main/java/net/mcreator/<modid>/network/
src/main/java/net/mcreator/<modid>/client/
src/main/java/net/mcreator/<modid>/economy/
src/main/java/net/mcreator/<modid>/message/
src/main/java/net/mcreator/<modid>/hitbox/
src/main/java/net/mcreator/<modid>/attributes/
src/main/java/net/mcreator/<modid>/events/
```

Потом:

```text
Regenerate code
Build
```

Если этого не сделать, MCreator иногда продолжает использовать старый generated Java-класс, и кажется, что новый блок “не работает”.

---

# 4. ParCool API

ParCool API часть плагина нужна, чтобы управлять движениями ParCool из MCreator-процедур.

## 4.1. Что умеет ParCool bridge

Плагин может:

```text
отключать sprint / fast run
отключать climb
отключать jump-движения ParCool
отключать hang / cling
отключать wall run / wall slide / wall jump
отключать все движения ParCool
включать все движения обратно
принудительно синхронизировать permissions
чистить повреждённый limitation-файл игрока
делать handshake клиента
```

## 4.2. Как это работает внутри

ParCool использует систему `Limitation`.

Плагин создаёт свой limitation id:

```text
parcool_api:mcreator_bridge
```

и через него запрещает или разрешает ParCool Action-классы.

Примерно так:

```text
игрок
  -> Limitation mcreator_bridge
      -> permit(FastRun, false)
      -> setLeastStaminaConsumption(FastRun, Integer.MAX_VALUE)
      -> apply()
      -> несколько повторных sync через delay
```

Повторная синхронизация нужна потому, что клиент ParCool может получить ограничения не сразу, особенно при первом входе игрока на сервер.

## 4.3. Основные movement blocks

```text
disable sprint for player
disable climb for player
disable jump for player
disable hang for player
disable wall run for player
disable all parcool movement abilities
enable all parcool movement abilities
force sync parcool permissions
```

## 4.4. Что отключает каждый блок

| Блок | Что примерно отключает |
|---|---|
| `disable sprint` | `FastRun` |
| `disable climb` | `ClimbUp`, `ClimbPoles` |
| `disable jump` | `ChargeJump`, `JumpFromBar`, `WallJump` |
| `disable hang` | `HangDown`, `ClingToCliff` |
| `disable wall run` | `HorizontalWallRun`, `VerticalWallRun`, `WallSlide`, `WallJump` |
| `disable all parcool movement abilities` | все actions из `Actions.LIST` |
| `enable all parcool movement abilities` | снимает bridge limitation и возвращает движения |
| `force sync parcool permissions` | повторно применяет limitation и делает handshake |

## 4.5. Пример: отключить все ParCool движения при перегрузе

```text
Trigger: Player tick update

if get weight status of player >= 3
    disable all parcool movement abilities of player
    disable vanilla jump of player
    force sync parcool permissions of player
    send actionbar "Вы перегружены!"
else
    enable all parcool movement abilities of player
    enable vanilla jump of player
    force sync parcool permissions of player
```

Совет: лучше не делать `force sync` каждый тик. Используй его при смене состояния или раз в 20–40 тиков.

---

# 5. Stamina API

Stamina API работает с ParCool stamina игрока.

## 5.1. Что умеет stamina bridge

```text
get stamina
get max stamina
is exhausted
get stamina percent with rounding
add stamina
consume stamina
set stamina
set max stamina
get stamina recovery
set stamina recovery
```

## 5.2. Основные блоки stamina

```text
get parcool stamina of player
get max parcool stamina of player
is parcool stamina exhausted
get parcool stamina percent rounded to N decimals
add parcool stamina
consume parcool stamina
set parcool stamina
set max parcool stamina
get stamina recovery
set stamina recovery
if parcool stamina reached 0 run until full
```

## 5.3. Важный блок: run until full

```text
if parcool stamina reached 0 run until full
```

Логика:

```text
1. Пока stamina не упала до 0 — вложенные блоки не выполняются.
2. Когда stamina стала 0 — включается режим exhausted.
3. Пока stamina не восстановилась до full — вложенные блоки выполняются.
4. Когда stamina восстановилась — режим выключается.
```

Пример:

```text
Trigger: Player tick update

if parcool stamina reached 0 run until full
    disable all parcool movement abilities
    send actionbar "Вы выдохлись!"
```

---

# 6. Camera API и client wait

## 6.1. Camera blocks

```text
set camera first person
set camera third person back
set camera third person front
set camera perspective with delay
```

Камера меняется через network payload на клиенте.

Поддерживаемые значения:

```text
FIRST_PERSON
THIRD_PERSON_BACK
THIRD_PERSON_FRONT
```

## 6.2. Client wait

Client wait нужен для визуальных задержек на стороне клиента:

```text
camera
GUI
маленькие локальные эффекты
```

Пример:

```text
set camera third person front
client wait 60 ticks
set camera first person
```

Не используй client wait для:

```text
экономики
веса
урона
party состава
серверных прав
```

Для этого нужен server-side wait / queueServerWork.

---

# 7. Vanilla Jump Bridge

Отдельная система для отключения обычного ванильного прыжка.

## 7.1. Зачем нужна

ParCool jump и vanilla jump — разные вещи.

Можно отключить ParCool-прыжки, но игрок всё ещё сможет делать обычный прыжок Minecraft. Поэтому добавлен отдельный bridge.

## 7.2. Типовые блоки

```text
disable vanilla jump of player
enable vanilla jump of player
is vanilla jump disabled for player
```

## 7.3. Пример

```text
if weight status >= 2
    disable vanilla jump
else
    enable vanilla jump
```

---

# 8. Weight System

Система веса считает массу предметов в инвентаре игрока и применяет стадии перегруза.

## 8.1. Что хранится

```text
вес каждого item id
default item weight
default max carry weight
max carry weight каждого игрока
auto enabled каждого игрока
last weight status
client sync current weight
client sync load percent
```

Сохраняется через `SavedData`, а также частично мигрирует/дублирует legacy persistent tags игрока.

## 8.2. Как считается вес

У каждого предмета есть вес одной штуки:

```text
unit weight
```

Вес стака:

```text
stack weight = unit weight * count
```

Вес инвентаря:

```text
inventory weight =
    main inventory
  + armor
  + offhand
```

Загрузка:

```text
load percent = inventory weight / max carry weight * 100
```

## 8.3. Основные блоки веса

```text
set default item weight
get default item weight
set all registered items weight
set item weight
set item weight by id
get unit weight of item
get stack weight of item
get unit weight by item id
get stack weight by item id
get inventory weight
set max carry weight
get max carry weight
set default max carry weight
get load percent
get rounded load percent
is overloaded
get weight status
set auto weight enabled
is auto weight enabled
set weight system enabled
is weight system enabled
set default punishments enabled
set weight punishment stage
```

## 8.4. Item id для предметов из других модов

Для модовых предметов используй полный id:

```text
modid:item_name
```

Примеры:

```text
minecraft:stone
minecraft:diamond
irons_spellbooks:arcane_essence
alexsmobs:bear_fur
yourmod:heavy_backpack
```

Если namespace не указан, helper может воспринимать id как `minecraft:<id>`, но лучше всегда писать полностью.

## 8.5. Пример инициализации весов

```text
Trigger: Server started

set default item weight to 0.1

set item weight by id "minecraft:stone" to 1.0
set item weight by id "minecraft:cobblestone" to 1.0
set item weight by id "minecraft:iron_ingot" to 0.5
set item weight by id "minecraft:gold_ingot" to 0.8
set item weight by id "minecraft:diamond" to 0.2
set item weight by id "minecraft:netherite_sword" to 12.0
```

## 8.6. Пример максимального веса игрока

```text
Trigger: Player joins world

set max carry weight of player to 100
set auto weight enabled of player to true
```

Если у тебя есть прокачка силы:

```text
maxWeight = 100 + strengthLevel * 10
set max carry weight to maxWeight
```

## 8.7. Стадии перегруза

В текущей логике weight status:

| Status | Условие | Смысл |
|---:|---:|---|
| 0 | меньше 75% | нормально |
| 1 | от 75% | тяжело |
| 2 | от 125% | перегруз |
| 3 | от 175% | сильный перегруз |
| 4 | от 200% | критический перегруз |

Текущая реализация default punishments:

| Status | Наказание |
|---:|---|
| 1 | Slowness II |
| 2 | Slowness III + Mining Fatigue I + vanilla jump disabled |
| 3 | Slowness IV + Mining Fatigue II + Weakness I + сильнее ParCool restrictions |
| 4 | Slowness V + Mining Fatigue III + Weakness II + Darkness + почти все ParCool actions disabled |

## 8.8. Отключение weight system

Блоки:

```text
set weight system enabled to false
is weight system enabled
```

Если хочешь оставить расчёт веса, но отключить стандартные наказания:

```text
set weight default punishments enabled to false
```

Потом делай свои наказания процедурой.

## 8.9. Свои стадии наказаний

Блок:

```text
set weight punishment stage STAGE percent PERCENT disable jump BOOLEAN darkness BOOLEAN
```

Пример:

```text
set weight punishment stage 1 percent 75 disable jump false darkness false
set weight punishment stage 2 percent 100 disable jump true darkness false
set weight punishment stage 3 percent 150 disable jump true darkness false
set weight punishment stage 4 percent 200 disable jump true darkness true
```

---

# 9. Party System

Party System — система групп игроков с overlay, GUI, приглашениями, PvP, party chat и admin tools.

## 9.1. Что хранится в party

```text
party id
leader uuid
pvp enabled
max members
members
pins by viewer
overlay x/y by viewer
showSelf by viewer
custom overlay entries
extra stats by player
```

## 9.2. Основные возможности

```text
создать party
распустить party
пригласить игрока
отозвать invite
принять invite
отклонить invite
выйти из party
кикнуть игрока
передать лидерство
включить/выключить PvP
задать лимит участников
pin/unpin участников
showSelf per player
overlay x/y per player
custom overlay value/bar entries
party chat
admin управление чужими party
```

## 9.3. Команды

```text
/party create
/party invite <player>
/party revoke <player>
/party accept
/party decline
/party leave
/party kick <player>
/party transfer <player>
/party pvp <true|false>
/party limit <size>
/party showself <true|false>
/party pin <player>
/party unpin <player>
/party position <x> <y>
/party gui
/party invitegui
/party settingsgui
/party chat <message>
/party info
```

Admin:

```text
/party admin enabled <true|false>
/party admin reloadconfig
/party admin gui <player>
/party admin limit <player> <size>
/party admin pvp <player> <true|false>
/party admin add <party_member> <target>
/party admin forceadd <party_member> <target>
/party admin remove <target>
/party admin disband <player>
```

## 9.4. showSelf

`showSelf` определяет, видит ли игрок самого себя в своём overlay.

По умолчанию:

```text
false
```

Блоки:

```text
set party show self of player to true/false
party show self of player
```

## 9.5. Party overlay position

Актуальные default координаты:

```text
x = 8
y = 58
```

Блоки:

```text
set party overlay position of player to x X y Y
initialize party overlay layout of player show self false x 8 y 58
```

## 9.6. Invite GUI

Invite GUI показывает:

```text
онлайн-игроков
поиск по нику
статус игрока
Invite
Revoke
In party
```

Важно: Invite GUI не показывает HP/food/LVL, потому что это не party roster, а список приглашений.

## 9.7. Main Party GUI

Main GUI показывает союзников:

```text
nickname
leader marker
LVL stat, если передан
HP bar
absorption / golden HP
food bar
числовые значения HP/food
Pin / Unpin
Kick
```

## 9.8. Admin GUI

Admin GUI показывает:

```text
список онлайн-игроков
кто находится в party
кто лидер
размер party
лимит party
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

## 9.9. Party stats

Party stats — это key/value данные игрока, которые синхронизируются участникам party.

Блоки:

```text
set party stat of player key KEY to VALUE
clear party stat of player key KEY
```

Пример LVL:

```text
set party stat of player key "LVL" to text from persistent variable LVL
```

После этого LVL может отображаться рядом с ником в overlay и Main Party GUI.

---

# 10. Party assets: GUI и overlay

## 10.1. Папка текстур

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

Пример:

```text
src/main/resources/assets/encorecraftnew/textures/gui/party/
```

Если PNG отсутствует, плагин использует fallback-отрисовку прямоугольниками.

## 10.2. Используемые texture assets

| Файл | Размер | Где используется |
|---|---:|---|
| `overlay_member_frame.png` | `96x19` | рамка одного участника overlay |
| `overlay_hp_empty.png` | `88x3` | пустая HP bar |
| `overlay_hp_full.png` | `88x3` | заполненная HP bar |
| `overlay_absorption.png` | `88x3` | golden HP / absorption поверх HP |
| `overlay_food_empty.png` | `88x2` | пустая food bar |
| `overlay_food_full.png` | `88x2` | заполненная food bar |
| `gui_member_frame.png` | `300x34` | строка союзника в Main Party GUI |
| `gui_background.png` | `320x220` рекомендовано | зарезервировано, сейчас фон стандартный |
| `gui_button.png` | `80x20` рекомендовано | зарезервировано под кастомные кнопки |
| `gui_button_hover.png` | `80x20` рекомендовано | зарезервировано под hover-кнопки |

## 10.3. Overlay member frame

```text
overlay_member_frame.png
размер: 96x19
```

Разметка:

```text
x=0..95
y=0..18

рамка сверху:     y=0
рамка снизу:      y=18
рамка слева:      x=0
рамка справа:     x=95

nickname zone:    x=4..70,  y=2..9
LVL zone:         x=70..92, y=2..9

HP zone:          x=4..91, y=11..13
gap:              y=14
Food zone:        x=4..91, y=15..16
```

Схема:

```text
+------------------------------------------------+
| Nickname                              LVL 10   |
|                                                |
| [ HP + absorption ]                            |
| [ Food ]                                       |
+------------------------------------------------+
```

## 10.4. HP assets

```text
overlay_hp_empty.png  88x3
overlay_hp_full.png   88x3
```

Код обрезает `overlay_hp_full.png` по проценту HP:

```text
hpWidth = 88 * health / maxHealth
```

Если HP = 50%, будет нарисовано 44 px.

## 10.5. Absorption asset

```text
overlay_absorption.png 88x3
```

Рисуется поверх HP.

Лучше делать полупрозрачной золотой полосой, чтобы она не полностью перекрывала красный HP.

## 10.6. Food assets

```text
overlay_food_empty.png 88x2
overlay_food_full.png  88x2
```

Позиция:

```text
x = rowX + 4
y = rowY + 15
```

## 10.7. Main GUI member frame

```text
gui_member_frame.png
размер: 300x34
```

Разметка:

```text
nickname:       x=8..180,  y=4
HP bar:         x=8..167,  y=16..20, width=160, height=5
Food bar:       x=8..167,  y=24..27, width=160, height=4
HP text:        x=174..220, y=14
Food text:      x=174..220, y=23
Pin button:     справа, примерно 48x18
Kick button:    справа, примерно 48x18
```

## 10.8. Зарезервированные assets для будущей стилизации

Эти файлы можно подготовить заранее:

```text
gui_search.png                180x20 или 200x20
gui_scrollbar.png             6x120
gui_member_row.png            300x34
button_pin.png                48x18
button_unpin.png              48x18
button_kick.png               48x18
button_invite.png             78x20
button_revoke.png             78x20
button_accept.png             70x20
button_decline.png            70x20
button_admin_view.png         46x18
button_admin_remove.png       60x18
button_admin_disband.png      64x18
button_admin_pvp.png          62x18
button_admin_limit.png        38x18
```

Сейчас кнопки рендерятся vanilla `Button.builder(...)`. Чтобы эти PNG реально рисовались, нужно будет заменить vanilla Button на custom button render.

---

# 11. Party name visibility

Отдельный helper `PartyApiNameVisibility` управляет никами игроков.

## 11.1. Блоки

```text
hide name tag of player
show name tag of player
hide name tags of all players
show name tags of all players
hide player from server tab list
show player in server tab list
```

## 11.2. Hide name tag

Скрывает ник над головой через scoreboard team:

```text
Team.Visibility.NEVER
```

Helper запоминает прошлую team игрока и пытается вернуть её при `show`.

## 11.3. Hide from TAB

Скрытие из TAB list работает пакетами:

```text
ClientboundPlayerInfoRemovePacket
ClientboundPlayerInfoUpdatePacket
```

Это визуальное скрытие из списка игроков. Игрок остаётся на сервере.

---

# 12. Economy System

Экономика хранит все деньги в Cooper.

## 12.1. Курсы валют

```text
1 Cooper = 1
1 Iron = 100 Cooper
1 Gold = 10 000 Cooper
1 Platine = 10 000 000 Cooper
```

То есть:

```text
100 Cooper = 1 Iron
100 Iron = 1 Gold
1000 Gold = 1 Platine
```

## 12.2. Wallet и Bank

У игрока есть два счёта:

```text
wallet — личные деньги
bank — банковский счёт
```

При смерти:

```text
теряется percentage от wallet
bank не трогается
```

## 12.3. Основные economy blocks

```text
is economy enabled
set economy enabled
is casino enabled
set casino enabled

coin value
convert amount/unit to Cooper
format money

get wallet
get bank
get total money
set wallet
set bank
add wallet
add bank
take wallet
take bank
has wallet
has bank

transfer wallet from player to player
calculate transfer fee
set transfer fee percent

move wallet to bank
move bank to wallet

deposit coin items to bank
withdraw coin items from bank
set coin item id
get coin item id
```

## 12.4. Economy config

Файл:

```text
config/<modid>-economy-server.toml
```

Пример:

```toml
economy_enabled=true
casino_enabled=true
auto_compact_display=true

death_wallet_loss_percent=25.0000
transfer_fee_percent=10.0000

casino_house_edge_percent=5.0000
casino_min_bet_cooper=100
casino_max_bet_cooper=1000000

coin_item_cooper="minecraft:copper_ingot"
coin_item_iron="minecraft:iron_ingot"
coin_item_gold="minecraft:gold_ingot"
coin_item_platine="minecraft:netherite_ingot"
```

## 12.5. Пример: выдать 5 Gold

```text
amount = convert 5 GOLD to Cooper
add wallet of player by amount
send message "Получено: 5 Gold"
```

Внутри:

```text
5 Gold = 5 * 10 000 = 50 000 Cooper
```

## 12.6. Пример: перевод с комиссией

```text
transfer wallet from playerA to playerB amount 1000 Cooper
```

Если комиссия 10%:

```text
playerA теряет 1000 Cooper
playerB получает 900 Cooper
fee = 100 Cooper
```

---

# 13. Casino System

Casino System работает поверх Economy System.

## 13.1. Casino config

```toml
casino_enabled=true
casino_house_edge_percent=5.0000
casino_min_bet_cooper=100
casino_max_bet_cooper=1000000
```

## 13.2. Random blocks

```text
casino roll int min max
casino roll double min max
casino chance percent apply house edge
casino coin flip
casino dice sum dice sides
casino dice csv dice sides
weighted random index
csv value at index
weighted multiplier
```

## 13.3. Roulette blocks

```text
roulette number
roulette color
roulette is win betType choice number
roulette payout multiplier
```

Bet types:

```text
STRAIGHT
COLOR
EVEN_ODD
LOW_HIGH
DOZEN
COLUMN
```

Пример:

```text
number = roulette number
if roulette is win "COLOR" "RED" number
    payout = bet * roulette payout multiplier "COLOR"
```

## 13.4. Slots blocks

```text
slot result symbols
slot all equal
slot has pair
slot payout multiplier
```

Пример:

```text
result = slot result 6

if slot all equal result
    multiplier = 10
else if slot has pair result
    multiplier = 2
else
    multiplier = 0
```

## 13.5. Blackjack helpers

```text
card rank
card suit
card name
blackjack card value
blackjack hand value
blackjack is bust
blackjack dealer should hit
```

Пример hand:

```text
"1,10"
```

где `1` — Ace, `10` — десятая карта / face card value.

## 13.6. Crash helpers

```text
crash multiplier maxMultiplier
crash cashout wins generatedMultiplier cashoutMultiplier
```

Пример:

```text
generated = crash multiplier 20
cashout = 2.5

if crash cashout wins generated cashout
    payout = bet * cashout
else
    player loses bet
```

---

# 14. Message Tools

Message Tools позволяют делать красивые сообщения.

## 14.1. Styled text

Параметры:

```text
text
color
bold
italic
underlined
strikethrough
obfuscated
```

Цвет:

```text
#FFAA00
FFAA00
0xFFAA00
```

## 14.2. Отправка сообщений

```text
send styled message to entity
broadcast styled message
send styled message to operators
send styled message nearby entity radius
prefix message
```

## 14.3. Пример

```text
message = styled text "Вы перегружены!" color "#AA0000" bold true
send message to player as actionbar
```

---

# 15. Hitbox Tools

Hitbox Tools работают с bounding box и persistent hitbox.

## 15.1. Временный hitbox

```text
set temporary hitbox width height
```

Меняет bounding box прямо сейчас, но Minecraft может пересчитать размеры позже.

## 15.2. Persistent hitbox

```text
set persistent hitbox width height
```

Сохраняется через `SavedData` и применяется через `EntityEvent.Size`.

## 15.3. Основные блоки

```text
hitbox width of entity
hitbox height of entity
eye height of entity
bounding box x size
bounding box y size
bounding box z size

set temporary hitbox
set persistent hitbox
multiply persistent hitbox
clear persistent hitbox
refresh hitbox dimensions

does entity have persistent hitbox
persistent hitbox width
persistent hitbox height
```

## 15.4. Пример: большой босс

```text
When entity spawned:
    set persistent hitbox width 2.5 height 4.0
    refresh hitbox dimensions
```

---

# 16. Attribute Tools и Entity Properties

Attribute Tools позволяют работать с registry attributes и прямыми свойствами сущности.

## 16.1. Attribute blocks

```text
get base attribute
get final attribute value
set base attribute
add to base attribute
multiply base attribute
has attribute
```

Attribute id:

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

## 16.2. Health / absorption

```text
get health
get max health
set health
heal
damage
get absorption
set absorption
```

## 16.3. Air / fire / freeze

```text
get air supply
set air supply
get fire ticks
set fire ticks
get freeze ticks
set freeze ticks
```

## 16.4. Boolean properties

```text
set no gravity
is no gravity
set glowing
is glowing
set invulnerable
is invulnerable
set silent
is silent
set custom name visible
is custom name visible
```

## 16.5. Player food

```text
get food level
set food level
get saturation
set saturation
set exhaustion
```

---

# 17. Utility blocks

В plugin-наборе также используются utility-блоки для общих задач.

## 17.1. Spawn item with count/delay/removable

Идея блока:

```text
spawn ITEM at x y z count COUNT delay DELAY removable BOOLEAN
```

Зачем нужен:

```text
стандартный MCreator spawn item часто неудобен для точного количества
можно делать delayed loot
можно делать временные/удаляемые предметы
```

## 17.2. Entity inside cube

Идея блока:

```text
if ENTITY is inside cube x1 y1 z1 x2 y2 z2 do
```

Логика:

```text
minX = min(x1, x2)
maxX = max(x1, x2)
...
entity position внутри диапазона
```

Пример:

```text
if player inside cube 10 60 10 30 80 30
    send "Вы вошли в зону казино"
```

---

# 18. Примеры процедур

## 18.1. Инициализация игрока

```text
Trigger: Player joins world

set max carry weight of player to 100
set auto weight enabled of player to true
initialize party overlay layout of player show self false x 8 y 58
set party stat of player key "LVL" to text from persistent LVL
```

## 18.2. Инициализация веса предметов

```text
Trigger: Server started

set default item weight to 0.1
set item weight by id "minecraft:stone" to 1
set item weight by id "minecraft:iron_ingot" to 0.5
set item weight by id "minecraft:gold_ingot" to 0.8
set item weight by id "minecraft:diamond" to 0.2
set item weight by id "minecraft:netherite_sword" to 12
```

## 18.3. Открыть party invite GUI предметом

```text
Trigger: Right clicked with item

if item = yourmod:party_phone
    open party invite GUI for player
```

## 18.4. Выдать деньги за квест

```text
Trigger: Quest completed

amount = convert 3 GOLD to Cooper
add wallet of player amount
send styled message "Получено: 3 Gold" color "#FFD700"
```

## 18.5. Простая слот-машина

```text
bet = 500 Cooper

if take casino bet player bet
    result = slot result 6
    multiplier = slot payout multiplier result 10 2 0

    if multiplier > 0
        payout = give casino payout player bet multiplier
        send "Слоты: " + result + " Победа: " + format money payout
    else
        send "Слоты: " + result + " Проигрыш"
else
    send "Недостаточно денег или ставка запрещена"
```

## 18.6. LVL в party overlay

### Вариант A: отдельный overlay value

```text
Trigger: Player tick update, every 20 ticks

add party overlay value entry for player
    id = "lvl"
    label = "LVL"
    value = text from persistent variable LVL
    x = 0
    y = 92
    width = 60
    height = 10
    texture = ""
```

### Вариант B: LVL у каждого участника party

```text
Trigger: Player tick update, every 20 ticks

set party stat of player key "LVL" to text from persistent variable LVL
```

---

# 19. Лучшие практики

## 19.1. Что делать server-side

```text
деньги
банк
casino ставки
вес
party состав
party PvP
урон
hitbox
attributes
ParCool limitations
name visibility
```

## 19.2. Что делать client-side

```text
GUI
overlay
camera
client wait
визуальные эффекты
```

## 19.3. Не делай тяжёлое каждый тик

Плохо:

```text
каждый тик пересчитывать всё
каждый тик сохранять config
каждый тик force sync
```

Лучше:

```text
раз в 10–20 тиков
или только при смене состояния
```

---

# 20. Диагностика

## 20.1. Блок есть, но не генерирует код

Проверь:

```text
src/main/resources/procedures/<block>.json
src/main/resources/neoforge-1.21.1/procedures/<block>.java.ftl
```

В JSON должны быть:

```json
"mcreator": {
  "toolbox_id": "...",
  "inputs": [...]
}
```

## 20.2. Helper не появился в generated Java

Проверь `generator.yaml`.

Пример:

```yaml
- template: party_api_name_visibility.java.ftl
  name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiNameVisibility.java"
```

## 20.3. Party assets не отображаются

Проверь путь:

```text
assets/<modid>/textures/gui/party/<file>.png
```

Проверь размер PNG.

## 20.4. Party PvP не блокирует урон

Проверь:

```text
pvp_protection_enabled=true
игроки в одной party
party pvp false
PartyApiPvpGuard.java сгенерирован
```

## 20.5. Weight max сбрасывается

Проверь:

```text
set max carry weight вызывается на ServerPlayer
SavedData не удаляется вместе с миром
нет другой процедуры, которая ставит default 64
```

## 20.6. ParCool движения не отключаются сразу

Используй:

```text
disable all parcool movement abilities
force sync parcool permissions
```

и не забывай, что на первом входе клиенту иногда нужен небольшой burst sync.

---

# 21. Чеклист перед релизом

```text
[ ] runServer compile
[ ] runClient compile
[ ] ParCool 1.21.1-3.4.3.3-NF установлен
[ ] /party create работает
[ ] /party invitegui открывается
[ ] invite / accept / decline / revoke работают
[ ] Main Party GUI показывает HP/food барами
[ ] Invite GUI не показывает HP/food
[ ] Admin GUI показывает party leader / size / members
[ ] /party pvp false блокирует урон союзникам
[ ] hide name tag скрывает ник над игроком
[ ] hide from tab убирает игрока из TAB list
[ ] weight max сохраняется после перезахода
[ ] economy wallet/bank сохраняются
[ ] death wallet loss работает
[ ] casino bet limits работают
[ ] hitbox persistent переживает refreshDimensions
[ ] attribute blocks компилируются на текущих mappings
[ ] GUI assets лежат по правильному пути и правильного размера
```

---

# 22. Карта helper-файлов

```text
events/
  ParCoolApiBridgeEvents.java

parcool/
  ParCoolApiRuntime.java
  ParCoolApiMovementBridge.java
  ParCoolApiStaminaBridge.java
  ParCoolApiStaminaMonitor.java
  ParCoolApiVanillaJumpBridge.java

weight/
  ParCoolApiWeightSystem.java
  ParCoolApiWeightConfig.java

network/
  ParCoolApiCameraNetwork.java
  ParCoolApiWeightNetwork.java
  PartyApiNetwork.java

client/
  ParCoolApiClientScheduler.java
  PartyApiClient.java

party/
  PartyApiSystem.java
  PartyApiCommands.java
  PartyApiServerConfig.java
  PartyApiPvpGuard.java
  PartyApiChatGuard.java
  PartyApiNameVisibility.java

economy/
  EconomyApiServerConfig.java
  EconomyApiSystem.java
  EconomyApiEvents.java
  EconomyApiCommands.java
  EconomyApiCasino.java
  EconomyApiCasinoTemplates.java

message/
  MessageApiHelper.java

hitbox/
  HitboxApiBridge.java

attributes/
  AttributeApiBridge.java
  AttributeApiModBus.java
```
