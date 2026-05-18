# MCreatorParcoolApi / ParCool API — полная документация плагина

Документация описывает актуальную версию плагина для **MCreator 2025.3**, **NeoForge 1.21.1** и **ParCool 1.21.1-3.4.3.3-NF**.

Плагин добавляет набор систем для процедур MCreator:

```text
ParCool movement API
ParCool stamina API
Camera / client wait API
Vanilla jump control
Weight system
Party system
Party GUI / overlay / invite GUI / admin GUI
Party GUI assets
Party LVL display gate by mod_id
Name tag / TAB visibility tools
Economy system
Casino tools
Message tools
Hitbox tools
Attribute / entity property tools
Utility procedure blocks
```

---

# 1. Архитектура плагина

Плагин работает по схеме:

```text
MCreator block
  -> procedure .java.ftl
    -> generated procedure Java
      -> helper class
        -> Minecraft / NeoForge / ParCool API
```

Это как панель управления: в MCreator ты нажимаешь понятную кнопку, а сложная Java-логика спрятана в helper-классах.

---

# 2. Основные helper-файлы

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
  ParCoolApiWeightCommands.java

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

---

# 3. Установка обновлений

После замены `.java.ftl` файлов в плагине желательно удалить старые generated Java-файлы из workspace:

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

Если не удалить старые generated Java-файлы, MCreator иногда продолжает использовать старую реализацию, и кажется, что новый блок не работает.

---

# 4. ParCool Movement API

Система управляет ParCool abilities через ParCool `Limitation`.

## 4.1. Что умеет

```text
отключать sprint / fast run
отключать climb
отключать ParCool jump actions
отключать hang / cling
отключать wall run / wall slide / wall jump
отключать все ParCool movements
возвращать все ParCool movements
форсировать синхронизацию permissions
чистить повреждённые limitation-файлы
делать ParCool client handshake
```

## 4.2. Блоки

| Блок | Что делает |
|---|---|
| `disable sprint for player` | Отключает ParCool fast run / sprint ability. |
| `disable climb for player` | Отключает climb actions. |
| `disable jump for player` | Отключает ParCool jump-related actions. |
| `disable hang for player` | Отключает hang / cling actions. |
| `disable wall run for player` | Отключает wall run / wall slide / wall jump. |
| `disable all parcool movement abilities` | Отключает все ParCool actions через limitation. |
| `enable all parcool movement abilities` | Снимает ограничения, поставленные helper-ом. |
| `force sync parcool permissions` | Повторно применяет limitation и синхронизирует клиента. |
| `clear broken parcool limitation data` | Чистит повреждённые limitation данные игрока. |

## 4.3. Пример

```text
Trigger: Player tick update

if player is overloaded
    disable all parcool movement abilities
    force sync parcool permissions
    send actionbar "Вы перегружены!"
else
    enable all parcool movement abilities
```

---

# 5. ParCool Stamina API

## 5.1. Что умеет

```text
читать stamina
читать max stamina
читать stamina percent
округлять stamina percent
прибавлять stamina
тратить stamina
ставить stamina
ставить max stamina
работать с recovery
отслеживать состояние: stamina дошла до 0 и ещё не восстановилась полностью
```

## 5.2. Блоки

| Блок | Что делает |
|---|---|
| `get parcool stamina of player` | Возвращает текущую stamina. |
| `get max parcool stamina of player` | Возвращает max stamina. |
| `get parcool stamina percent rounded to N decimals` | Возвращает процент stamina с округлением. |
| `is parcool stamina exhausted` | Проверяет, закончилась ли stamina. |
| `add parcool stamina` | Прибавляет stamina. |
| `consume parcool stamina` | Тратит stamina. |
| `set parcool stamina` | Устанавливает stamina. |
| `set max parcool stamina` | Устанавливает max stamina. |
| `get stamina recovery` | Возвращает recovery. |
| `set stamina recovery` | Устанавливает recovery. |
| `if parcool stamina reached 0 run until full` | Выполняет вложенные блоки после падения stamina до 0 и до полного восстановления. |

## 5.3. Пример exhaustion-механики

```text
Trigger: Player tick update

if parcool stamina reached 0 run until full
    disable all parcool movement abilities
    send actionbar "Вы устали!"
```

---

# 6. Camera API и Client Wait

## 6.1. Camera

Поддерживаемые режимы:

```text
FIRST_PERSON
THIRD_PERSON_BACK
THIRD_PERSON_FRONT
```

Блоки:

| Блок | Что делает |
|---|---|
| `set camera first person` | Переключает камеру в first person. |
| `set camera third person back` | Переключает камеру в third person back. |
| `set camera third person front` | Переключает камеру в third person front. |
| `set camera perspective with delay` | Меняет камеру после задержки. |

## 6.2. Client wait

Client wait нужен для визуальных задержек:

```text
camera
GUI
локальные эффекты
```

Не используй client wait для server-side логики:

```text
экономика
вес
party состав
урон
права
банк
казино ставки
```

---

# 7. Vanilla Jump Bridge

Vanilla jump — обычный Minecraft-прыжок. Он не равен ParCool jump actions.

Блоки:

| Блок | Что делает |
|---|---|
| `disable vanilla jump` | Запрещает обычный прыжок. |
| `enable vanilla jump` | Возвращает обычный прыжок. |
| `is vanilla jump disabled` | Проверяет, отключён ли vanilla jump. |

Пример:

```text
if weight status >= 2
    disable vanilla jump
else
    enable vanilla jump
```

---

# 8. Weight System

Система веса считает массу предметов в инвентаре игрока и применяет наказания.

## 8.1. Что хранится

```text
default item weight
weight каждого item id
default max carry weight
max carry weight каждого игрока
auto weight enabled каждого игрока
last status каждого игрока
client current weight sync
client load percent sync
```

## 8.2. Расчёт

```text
unit weight = вес одной штуки предмета
stack weight = unit weight * stack count
inventory weight = main inventory + armor + offhand
load percent = inventory weight / max carry weight * 100
```

## 8.3. Блоки веса

| Блок | Что делает |
|---|---|
| `set default item weight` | Устанавливает вес предмета по умолчанию. |
| `get default item weight` | Возвращает вес по умолчанию. |
| `set all registered items weight` | Сбрасывает все веса и задаёт общий вес. |
| `set item weight` | Задаёт вес itemstack. |
| `set item weight by id` | Задаёт вес по строковому item id. |
| `get unit weight of item` | Возвращает вес одной штуки itemstack. |
| `get stack weight of item` | Возвращает вес всего стака. |
| `get unit weight by item id` | Возвращает вес одной штуки по id. |
| `get stack weight by item id` | Возвращает вес стака по id и count. |
| `get inventory weight` | Возвращает общий вес инвентаря. |
| `set max carry weight` | Устанавливает максимальный вес игрока. |
| `get max carry weight` | Возвращает максимальный вес игрока. |
| `set default max carry weight` | Устанавливает дефолтный max weight. |
| `get load percent` | Возвращает процент загрузки. |
| `get rounded load percent` | Возвращает процент с округлением. |
| `is overloaded` | Проверяет, есть ли перегруз. |
| `get weight status` | Возвращает статус веса 0–4. |
| `set auto weight enabled` | Включает/выключает автообновление веса для игрока. |
| `is auto weight enabled` | Проверяет автообновление веса. |
| `set weight system enabled` | Глобально включает/выключает систему веса. |
| `is weight system enabled` | Проверяет, включена ли система веса. |
| `set weight default punishments enabled` | Включает/выключает встроенные наказания. |
| `set weight punishment stage` | Настраивает стадию наказания. |

## 8.4. Admin-команды веса

```text
/weight admin enabled false
/weight admin enabled true
/weight admin reloadconfig
/weight admin status
/weight admin status <player>
```

Короткий alias:

```text
/parcoolweight enabled false
/parcoolweight enabled true
/parcoolweight reloadconfig
/parcoolweight status <player>
```

Когда `weight_enabled=false`:

```text
inventory weight -> 0
load percent -> 0
weight status -> 0
is overloaded -> false
наказания снимаются
ParCool weight limitation снимается
vanilla jump возвращается
```

## 8.5. Item id

Для предметов из других модов используй полный id:

```text
modid:item_name
```

Примеры:

```text
minecraft:stone
minecraft:iron_ingot
minecraft:gold_ingot
minecraft:diamond
irons_spellbooks:arcane_essence
yourmod:heavy_backpack
```

---

# 9. Party System

Party System добавляет группы игроков, overlay, GUI, приглашения, PvP, chat и admin tools.

## 9.1. Что хранится в party

```text
party id
leader uuid
members
pvp enabled
max members
pins by viewer
showSelf by viewer
overlay x/y by viewer
custom overlay entries
extra player stats
LVL display required mod id
```

## 9.2. Команды игрока

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

## 9.3. Admin-команды party

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

## 9.4. Party procedure blocks

| Блок | Что делает |
|---|---|
| `create party` | Создаёт party для игрока. |
| `disband party` | Распускает party, если игрок лидер. |
| `invite player to party` | Отправляет invite. |
| `revoke party invite` | Отзывает invite. |
| `accept party invite` | Принимает invite. |
| `decline party invite` | Отклоняет invite. |
| `leave party` | Выход из party. |
| `kick player from party` | Кикает участника, если actor лидер. |
| `set party pvp` | Включает/выключает PvP в party. |
| `is party pvp enabled` | Проверяет PvP party. |
| `set party max members` | Устанавливает лимит party. |
| `get party max members` | Возвращает лимит party. |
| `is in party` | Проверяет, находится ли игрок в party. |
| `are in same party` | Проверяет, в одной ли party два игрока. |
| `is party leader` | Проверяет, является ли игрок лидером party. |
| `get party size` | Возвращает размер party. |
| `get online party size` | Возвращает число онлайн-участников. |
| `set party show self` | Включает/выключает отображение себя в overlay. |
| `get party show self` | Проверяет showSelf. |
| `set party overlay position x y` | Задаёт позицию overlay. |
| `initialize party overlay layout` | Инициализирует overlay layout. |
| `set party overlay element position` | Двигает отдельный overlay element. |
| `add party overlay value entry` | Добавляет кастомный текстовый value в overlay. |
| `add party overlay bar entry` | Добавляет кастомную bar-полоску в overlay. |
| `set party stat` | Задаёт key/value stat игрока для отображения союзникам. |
| `clear party stat` | Удаляет stat. |
| `open party GUI` | Открывает main party GUI. |
| `open party invite GUI` | Открывает invite GUI. |
| `open party admin GUI` | Открывает admin GUI, если есть права. |
| `send party chat` | Отправляет party chat. |
| `send message to party` | Отправляет системное сообщение party. |

---

# 10. Party LVL display by mod_id

Эта механика нужна, если LVL должен отображаться только когда на сервере загружен определённый мод.

Пример: у тебя есть отдельный RPG/leveling mod, который добавляет persistent-переменную `LVL`. Если этот мод есть — party показывает LVL. Если его нет — LVL вообще не отображается.

## 10.1. Новые блоки

| Блок | Что делает |
|---|---|
| `set party LVL display required mod id to MOD_ID` | Запоминает mod id, который должен быть загружен для отображения LVL. |
| `party LVL display required mod id` | Возвращает текущий mod id. |
| `is party LVL display enabled` | True, если mod id задан и этот мод реально загружен. |
| `round VALUE to no decimals text` | Округляет число и возвращает текст без дробной части. |
| `set party LVL stat of PLAYER to rounded VALUE` | Сохраняет LVL игрока как округлённый текст. |

## 10.2. Как включить

На старте сервера или при инициализации:

```text
set party LVL display required mod id to "your_level_mod"
```

Если мод `your_level_mod` загружен, LVL начнёт отображаться.

Если мод не загружен:

```text
LVL не показывается в overlay
LVL не показывается в Main Party GUI
LVL не показывается в Admin GUI
LVL не показывается в Invite GUI
```

## 10.3. Как записать LVL игрока

Создай persistent player variable в MCreator:

```text
Name: LVL
Type: Number
Scope: Player persistent
Default: 1
```

На player tick, например раз в 20 тиков:

```text
set party LVL stat of Event/Target entity to rounded persistent LVL
```

Или вручную:

```text
set party stat of player key "LVL" to round persistent LVL to no decimals text
```

## 10.4. Как округляется

```text
1.2 -> 1
1.5 -> 2
10.9 -> 11
```

То есть в GUI будет красиво:

```text
LVL 12
```

а не:

```text
LVL 12.0
LVL 12.532421
```

---

# 11. Party GUI screens

## 11.1. Main Party GUI

Показывает участников party:

```text
nickname
leader marker
LVL, если включён LVL mod gate
HP bar
absorption / golden HP
food bar
Pin / Unpin
Kick
Create party, если игрок не в party
Leave party, если игрок в party, но не лидер
```

## 11.2. Invite GUI

Показывает онлайн-игроков:

```text
search
nickname
LVL, если включён LVL mod gate
status
Invite
Revoke
In party
```

Invite GUI не показывает HP/food, потому что это список приглашения, а не список союзников.

## 11.3. Settings GUI

Обычный участник видит:

```text
Show self ON/OFF
Reset overlay position
PvP status
```

Лидер видит дополнительно:

```text
PvP ON
PvP OFF
party settings
```

## 11.4. Admin GUI

Admin GUI показывает **только лидеров party**.

```text
одна строка = одна party
```

Кнопка `View` открывает полный состав party, включая самого админа, если он в этой party.

Кнопки:

```text
System ON
System OFF
Refresh
View
Remove
Disband с подтверждением
PvP ON
PvP OFF
L4
L8
L16
```

---

# 12. Party assets — полный список GUI / overlay элементов

## 12.1. Папка assets

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

Пример:

```text
src/main/resources/assets/encorecraftnew/textures/gui/party/
```

Требования:

```text
формат: PNG
имена: lower_case
лучше использовать прозрачность
размеры соблюдать пиксель-в-пиксель для кнопок, баров и row elements
```

Если текстуры нет, код использует fallback:

```text
specific button texture
  -> generic gui_button / gui_button_hover / gui_button_disabled
    -> vanilla Button render
```

Для фонов:

```text
specific screen background
  -> gui_background
    -> тёмная fallback-заливка
```

## 12.2. Overlay assets

| Файл | Размер | Использование |
|---|---:|---|
| `overlay_member_frame.png` | `96x19` | обычная рамка участника overlay |
| `overlay_member_frame_leader.png` | `96x19` | рамка лидера party в overlay |
| `overlay_hp_empty.png` | `88x3` | пустая HP bar |
| `overlay_hp_full.png` | `88x3` | заполненная HP bar |
| `overlay_absorption.png` | `88x3` | golden HP поверх HP |
| `overlay_food_empty.png` | `88x2` | пустая food bar |
| `overlay_food_full.png` | `88x2` | заполненная food bar |
| `overlay_custom_bar_empty.png` | `80x6` recommended | пустая custom bar |
| `overlay_custom_bar_full.png` | `80x6` recommended | заполненная custom bar |
| `overlay_value_frame.png` | `80x12` recommended | рамка custom value text |

### Разметка `overlay_member_frame.png`

```text
размер: 96x19

x=0..95
y=0..18

border top:     y=0
border bottom:  y=18
border left:    x=0
border right:   x=95

nickname zone:  x=4..70,  y=2..9
LVL zone:       x=70..92, y=2..9

HP zone:        x=4..91, y=11..13
gap:            y=14
Food zone:      x=4..91, y=15..16
```

## 12.3. Screen backgrounds

Фоны рекомендуется делать `320x180`; код растягивает их на текущий scaled GUI size без повторов и обрезов.

| Файл | Размер | Экран |
|---|---:|---|
| `gui_background.png` | `320x180` | общий fallback-фон |
| `gui_main_background.png` | `320x180` | Main Party GUI |
| `gui_invite_background.png` | `320x180` | Invite GUI |
| `gui_settings_background.png` | `320x180` | Settings GUI |
| `gui_admin_background.png` | `320x180` | Admin GUI |
| `gui_invite_popup_background.png` | `220x88` | Invite Popup |

## 12.4. Row / search / scrollbar assets

| Файл | Размер | Где используется |
|---|---:|---|
| `gui_member_frame.png` | `300x34` | строка участника в Main Party GUI |
| `gui_online_player_row.png` | `300x22` | строка игрока в Invite GUI |
| `gui_admin_player_row.png` | `420x48` | строка лидера party в Admin GUI |
| `gui_search.png` | `180x20` или `200x20` | фон поля поиска |
| `gui_scrollbar_track.png` | `6x120` | дорожка скроллбара |
| `gui_scrollbar_thumb.png` | `6x20` | ползунок скроллбара |

### `gui_member_frame.png`

```text
размер: 300x34

nickname:       x=8..180,  y=4
HP bar:         x=8..167,  y=16..20, width=160, height=5
Food bar:       x=8..167,  y=24..27, width=160, height=4
HP text:        x=174..220, y=14
Food text:      x=174..220, y=23
Pin button:     примерно x=196..243, y=8..25
Kick button:    примерно x=248..295, y=8..25
```

## 12.5. Button assets

Для каждой кнопки используется схема:

```text
button_<id>.png
button_<id>_hover.png
button_<id>_disabled.png
```

Если specific texture отсутствует:

```text
button_<id>.png отсутствует
  -> gui_button.png
    -> vanilla button
```

### Generic fallback

| Файл | Размер | Назначение |
|---|---:|---|
| `gui_button.png` | `80x20` | общий fallback normal |
| `gui_button_hover.png` | `80x20` | общий fallback hover |
| `gui_button_disabled.png` | `80x20` | общий fallback disabled |

### Top tabs

| ID | Файлы | Размер |
|---|---|---:|
| `tab_main` | `button_tab_main.png`, `_hover`, `_disabled` | `54x20` |
| `tab_invite` | `button_tab_invite.png`, `_hover`, `_disabled` | `58x20` |
| `tab_settings` | `button_tab_settings.png`, `_hover`, `_disabled` | `72x20` |
| `tab_admin` | `button_tab_admin.png`, `_hover`, `_disabled` | `58x20` |

### Main Party GUI

| ID | Файлы | Размер |
|---|---|---:|
| `pin` | `button_pin.png`, `_hover`, `_disabled` | `48x18` |
| `unpin` | `button_unpin.png`, `_hover`, `_disabled` | `48x18` |
| `kick` | `button_kick.png`, `_hover`, `_disabled` | `48x18` |
| `create_party` | `button_create_party.png`, `_hover`, `_disabled` | `110x20` |
| `leave_party` | `button_leave_party.png`, `_hover`, `_disabled` | `90x20` |

### Invite GUI

| ID | Файлы | Размер |
|---|---|---:|
| `invite` | `button_invite.png`, `_hover`, `_disabled` | `78x20` |
| `revoke` | `button_revoke.png`, `_hover`, `_disabled` | `78x20` |
| `in_party` | `button_in_party.png`, `_hover`, `_disabled` | `78x20` |

### Settings GUI

| ID | Файлы | Размер |
|---|---|---:|
| `show_self_on` | `button_show_self_on.png`, `_hover`, `_disabled` | `120x20` |
| `show_self_off` | `button_show_self_off.png`, `_hover`, `_disabled` | `120x20` |
| `pvp_on` | `button_pvp_on.png`, `_hover`, `_disabled` | `120x20` |
| `pvp_off` | `button_pvp_off.png`, `_hover`, `_disabled` | `120x20` |
| `reset_position` | `button_reset_position.png`, `_hover`, `_disabled` | `180x20` |

### Admin GUI

| ID | Файлы | Размер |
|---|---|---:|
| `admin_system_on` | `button_admin_system_on.png`, `_hover`, `_disabled` | `80x20` |
| `admin_system_off` | `button_admin_system_off.png`, `_hover`, `_disabled` | `86x20` |
| `admin_refresh` | `button_admin_refresh.png`, `_hover`, `_disabled` | `70x20` |
| `admin_view` | `button_admin_view.png`, `_hover`, `_disabled` | `46x18` |
| `admin_remove` | `button_admin_remove.png`, `_hover`, `_disabled` | `60x18` |
| `admin_disband` | `button_admin_disband.png`, `_hover`, `_disabled` | `64x18` |
| `admin_pvp_on` | `button_admin_pvp_on.png`, `_hover`, `_disabled` | `62x18` |
| `admin_pvp_off` | `button_admin_pvp_off.png`, `_hover`, `_disabled` | `62x18` |
| `admin_limit_4` | `button_admin_limit_4.png`, `_hover`, `_disabled` | `30x18` |
| `admin_limit_8` | `button_admin_limit_8.png`, `_hover`, `_disabled` | `30x18` |
| `admin_limit_16` | `button_admin_limit_16.png`, `_hover`, `_disabled` | `38x18` |

### Invite Popup

| ID | Файлы | Размер |
|---|---|---:|
| `accept` | `button_accept.png`, `_hover`, `_disabled` | `70x20` |
| `decline` | `button_decline.png`, `_hover`, `_disabled` | `70x20` |

---

# 13. Party name visibility

Блоки:

| Блок | Что делает |
|---|---|
| `hide name tag of player` | Скрывает ник над головой игрока. |
| `show name tag of player` | Возвращает ник над головой. |
| `hide name tags of all players` | Скрывает ники всем онлайн-игрокам. |
| `show name tags of all players` | Возвращает ники всем онлайн-игрокам. |
| `hide player from server tab list` | Убирает игрока из TAB list. |
| `show player in server tab list` | Возвращает игрока в TAB list. |

Скрытие над головой работает через scoreboard team:

```text
Team.Visibility.NEVER
```

Скрытие из TAB работает через packets.

---

# 14. Economy System

Экономика хранит деньги в Cooper.

Курсы:

```text
100 Cooper = 1 Iron
100 Iron = 1 Gold
1000 Gold = 1 Platine
```

Внутренние значения:

```text
1 Cooper = 1
1 Iron = 100
1 Gold = 10 000
1 Platine = 10 000 000
```

## 14.1. Счета

```text
wallet — личный счёт
bank — банковский счёт
```

При смерти игрок теряет процент от wallet. Bank не трогается.

## 14.2. Economy blocks

| Блок | Что делает |
|---|---|
| `is economy enabled` | Проверяет, включена ли экономика. |
| `set economy enabled` | Включает/выключает экономику. |
| `get wallet` | Возвращает личный счёт. |
| `get bank` | Возвращает банк. |
| `get total money` | Возвращает wallet + bank. |
| `set wallet` | Устанавливает wallet. |
| `set bank` | Устанавливает bank. |
| `add wallet` | Добавляет деньги в wallet. |
| `add bank` | Добавляет деньги в bank. |
| `take wallet` | Забирает деньги из wallet. |
| `take bank` | Забирает деньги из bank. |
| `has wallet` | Проверяет, хватает ли денег в wallet. |
| `has bank` | Проверяет, хватает ли денег в bank. |
| `transfer wallet` | Переводит деньги игроку с комиссией. |
| `calculate transfer fee` | Считает комиссию. |
| `move wallet to bank` | Перекладывает wallet -> bank. |
| `move bank to wallet` | Перекладывает bank -> wallet. |
| `deposit coin items to bank` | Кладёт монетные предметы в банк. |
| `withdraw coin items from bank` | Снимает банк в виде предметов. |
| `set coin item id` | Настраивает item id монеты. |
| `get coin item id` | Возвращает item id монеты. |
| `format money` | Форматирует деньги красиво. |
| `convert coin to Cooper` | Конвертирует валюту в Cooper. |

---

# 15. Casino System

Casino работает поверх Economy.

## 15.1. Общие blocks

| Блок | Что делает |
|---|---|
| `take casino bet` | Забирает ставку, если она допустима. |
| `give casino payout` | Выдаёт выигрыш. |
| `calculate casino payout` | Считает выплату. |
| `is casino bet allowed` | Проверяет лимиты ставки. |
| `set casino enabled` | Включает/выключает casino. |
| `set casino house edge` | Настраивает преимущество казино. |
| `set casino bet limits` | Настраивает min/max ставку. |

## 15.2. Random blocks

```text
roll int
roll double
chance percent
coin flip
dice sum
dice csv
weighted index
weighted multiplier
csv value at index
```

## 15.3. Roulette

```text
roulette number
roulette color
roulette is win
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

## 15.4. Slots

```text
slot result
slot all equal
slot has pair
slot payout multiplier
```

## 15.5. Blackjack

```text
card rank
card suit
card name
blackjack card value
blackjack hand value
blackjack is bust
blackjack dealer should hit
```

## 15.6. Crash

```text
crash multiplier
crash cashout wins
```

---

# 16. Message Tools

Message system позволяет отправлять стилизованные сообщения.

## 16.1. Styled component

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

## 16.2. Куда отправлять

```text
send to player
broadcast to server
send to operators
send nearby players
send to party
party chat
actionbar
```

---

# 17. Hitbox Tools

## 17.1. Чтение

```text
get hitbox width
get hitbox height
get eye height
get bounding box X size
get bounding box Y size
get bounding box Z size
```

## 17.2. Временный hitbox

```text
set temporary hitbox width height
```

Работает сразу, но Minecraft может пересчитать bounding box.

## 17.3. Persistent hitbox

```text
set persistent hitbox width height
multiply persistent hitbox
clear persistent hitbox
has persistent hitbox
get persistent hitbox width
get persistent hitbox height
refresh dimensions
```

Persistent hitbox сохраняется через SavedData и применяется через `EntityEvent.Size`.

---

# 18. Attribute / Entity Properties

## 18.1. Attribute blocks

```text
get attribute base
get attribute value
set attribute base
add attribute base
multiply attribute base
has attribute
```

Примеры ids:

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

## 18.2. Health / absorption

```text
get health
set health
heal
damage
get max health
get absorption
set absorption
```

## 18.3. Entity properties

```text
air supply
remaining fire ticks
ticks frozen
no gravity
glowing
invulnerable
silent
custom name visible
```

## 18.4. Player food

```text
food level
saturation
exhaustion
```

---

# 19. Utility blocks

## 19.1. Spawn item with count / delay / removable

```text
spawn item at x y z count delay removable
```

Используется для loot, наград, временных предметов.

## 19.2. Entity inside cube

```text
if entity is inside cube x1 y1 z1 x2 y2 z2
```

Удобно для зон:

```text
casino zone
boss arena
safe zone
quest trigger zone
```

---

# 20. Примеры процедур

## 20.1. Player joins world

```text
set max carry weight of player to 100
set auto weight enabled of player to true
initialize party overlay layout of player show self false x 8 y 58
set party LVL display required mod id to "your_level_mod"
set party LVL stat of player to rounded persistent LVL
```

## 20.2. Выдать деньги за квест

```text
amount = convert 3 GOLD to Cooper
add wallet of player amount
send styled message "Получено: 3 Gold" color "#FFD700"
```

## 20.3. Простая слот-машина

```text
bet = 500 Cooper

if take casino bet player bet
    result = slot result 6
    multiplier = slot payout multiplier result 10 2 0

    if multiplier > 0
        payout = give casino payout player bet multiplier
        send "Победа: " + format money payout
    else
        send "Проигрыш"
else
    send "Недостаточно денег"
```

---

# 21. Диагностика

## 21.1. LVL не показывается

Проверь:

```text
1. set party LVL display required mod id to "modid" вызван на сервере.
2. modid написан правильно.
3. Мод реально загружен.
4. Игроку задан party stat LVL.
5. Используется новый PartyApiSystem + PartyApiNetwork + PartyApiClient.
```

## 21.2. GUI texture не видна

Проверь:

```text
assets/<modid>/textures/gui/party/<file>.png
имя lowercase
формат PNG
размер соответствует таблице
ресурс попал в build
```

## 21.3. Кнопка не использует свой PNG

Проверь схему:

```text
button_<id>.png
button_<id>_hover.png
button_<id>_disabled.png
```

Пример:

```text
button_kick.png
button_kick_hover.png
button_kick_disabled.png
```

## 21.4. Admin GUI не показывает party info

Нужны актуальные:

```text
PartyApiSystem
PartyApiNetwork
PartyApiClient
```

## 21.5. Weight не отключается

Проверь:

```text
/weight admin enabled false
/weight admin status <player>
```

Должно быть:

```text
enabled=false
current=0.0
percent=0.0
status=0
```

---

# 22. Чеклист

```text
[ ] Build проходит
[ ] runServer запускается
[ ] runClient запускается
[ ] /weight admin enabled false реально отключает вес
[ ] /party gui открывает Main GUI
[ ] Main GUI показывает HP/food барами
[ ] LVL показывается только когда нужный mod_id загружен
[ ] LVL округляется без .0
[ ] /party invitegui показывает online list и LVL при включённом gate
[ ] Invite GUI не показывает HP/food
[ ] Admin GUI показывает только лидеров party
[ ] View показывает всех участников party
[ ] Button PNG подхватываются
[ ] Hover PNG подхватываются
[ ] Disabled PNG подхватываются
[ ] Overlay PNG подхватываются
[ ] hide name tag работает
[ ] hide from TAB работает
[ ] Economy wallet/bank сохраняются
[ ] Casino bet limits работают
[ ] Hitbox persistent работает
[ ] Attribute blocks компилируются
```
