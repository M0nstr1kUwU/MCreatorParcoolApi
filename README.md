# MCreatorParcoolApi / ParCool API — полная документация плагина

Документация описывает актуальную версию плагина для **MCreator 2025.3**, **NeoForge 1.21.1** и **ParCool 1.21.1-3.4.3.3-NF**.

Плагин добавляет несколько больших систем:

```text
1. ParCool movement API
2. ParCool stamina API
3. Camera / client wait API
4. Vanilla jump control
5. Weight system
6. Party system
7. Party GUI / overlay / invite GUI / admin GUI
8. Party GUI assets
9. Name tag / TAB visibility tools
10. Economy system
11. Casino tools
12. Message tools
13. Hitbox tools
14. Attribute / entity property tools
15. Utility procedure blocks
```

---

# 1. Общая архитектура

Плагин работает через helper-классы и MCreator procedure blocks.

Схема:

```text
MCreator block
    -> .java.ftl template
        -> generated Java procedure code
            -> helper class
                -> Minecraft / NeoForge / ParCool API
```

Это сделано, чтобы сложный Java-код был в одном месте, а в MCreator оставались удобные блоки.

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

# 3. Установка / обновление helper-файлов

После замены `.java.ftl` файлов в плагине лучше удалить generated Java из workspace:

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

Если Java-файлы не удалить, MCreator может продолжить использовать старую сгенерированную версию.

---

# 4. ParCool Movement API

## 4.1. Что делает

Система управляет ParCool abilities через ParCool `Limitation`.

Плагин может:

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

## 4.2. Основные блоки

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

## 4.3. Что отключается

| Блок | Что отключает |
|---|---|
| `disable sprint` | FastRun |
| `disable climb` | ClimbUp, ClimbPoles |
| `disable jump` | ChargeJump, JumpFromBar, WallJump |
| `disable hang` | HangDown, ClingToCliff |
| `disable wall run` | HorizontalWallRun, VerticalWallRun, WallSlide, WallJump |
| `disable all parcool movement abilities` | все actions из ParCool Actions list |

## 4.4. Пример

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

## 5.1. Возможности

```text
get stamina
get max stamina
get stamina percent with rounding
is exhausted
add stamina
consume stamina
set stamina
set max stamina
get stamina recovery
set stamina recovery
trigger: run while stamina is 0 until full
```

## 5.2. Блоки

```text
get parcool stamina
get max parcool stamina
get parcool stamina percent rounded to N decimals
is parcool stamina exhausted
add parcool stamina
consume parcool stamina
set parcool stamina
set max parcool stamina
get stamina recovery
set stamina recovery
if parcool stamina reached 0 run until full
```

## 5.3. Пример exhaustion-механики

```text
Trigger: Player tick update

if parcool stamina reached 0 run until full
    disable all parcool movement abilities
    send actionbar "Вы устали!"
```

Логика блока:

```text
1. Если stamina не упала до 0 — вложенные блоки не запускаются.
2. Если stamina стала 0 — режим включается.
3. Пока stamina не восстановится до максимума — вложенные блоки продолжают выполняться.
4. Когда stamina стала полной — режим выключается.
```

---

# 6. Camera API / Client Wait

## 6.1. Camera

Поддерживаемые режимы:

```text
FIRST_PERSON
THIRD_PERSON_BACK
THIRD_PERSON_FRONT
```

Блоки:

```text
set camera first person
set camera third person back
set camera third person front
set camera perspective with delay
```

Камера меняется через client network payload.

## 6.2. Client wait

Client wait нужен для визуальных задержек:

```text
camera
GUI
локальные эффекты
```

Не используй client wait для:

```text
экономики
веса
party состава
урона
прав
серверной логики
```

---

# 7. Vanilla Jump Bridge

Vanilla jump — это обычный прыжок Minecraft. Он не равен ParCool jump actions.

Блоки:

```text
disable vanilla jump
enable vanilla jump
is vanilla jump disabled
```

Пример:

```text
if weight status >= 2
    disable vanilla jump
else
    enable vanilla jump
```

---

# 8. Weight System

Система веса считает вес инвентаря игрока и применяет наказания.

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

## 8.4. Item ID

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

## 8.5. Стадии веса

| Status | Нагрузка | Смысл |
|---:|---:|---|
| 0 | меньше 75% | нормально |
| 1 | от 75% | тяжело |
| 2 | от 125% | перегруз |
| 3 | от 175% | сильный перегруз |
| 4 | от 200% | критический перегруз |

## 8.6. Default punishments

| Status | Наказания |
|---:|---|
| 1 | Slowness |
| 2 | Slowness + Mining Fatigue + disabled vanilla jump |
| 3 | Slowness + Mining Fatigue + Weakness + больше ParCool restrictions |
| 4 | Slowness + Mining Fatigue + Weakness + Darkness + почти все ParCool actions disabled |

## 8.7. Отключить weight system

```text
set weight system enabled to false
```

Проверить:

```text
is weight system enabled
```

## 8.8. Отключить стандартные наказания, но оставить расчёт

```text
set weight default punishments enabled to false
```

После этого можно строить свои наказания блоками.

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

## 9.3. Admin commands

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

## 9.4. Party GUI screens

Плагин добавляет:

```text
Main Party GUI
Invite GUI
Settings GUI
Admin GUI
Invite Popup
Party Overlay
```

### Main Party GUI

Показывает только участников party:

```text
nickname
leader marker
LVL, если передан через party stat
HP bar
absorption / golden HP
food bar
Pin / Unpin
Kick
```

### Invite GUI

Показывает онлайн-игроков:

```text
search
nickname
status
Invite
Revoke
In party
```

Invite GUI не показывает HP/food/LVL. Это правильно: он нужен для приглашения, а не для просмотра статов союзников.

### Settings GUI

Содержит:

```text
Show self ON/OFF
PvP ON/OFF
Reset overlay position
```

### Admin GUI

Показывает:

```text
online players
party leader
party size
party max members
party membership
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

### Invite Popup

Появляется у приглашённого игрока:

```text
Party Invite
Accept
Decline
```

---

# 10. Party assets — полный список GUI / overlay элементов

## 10.1. Куда класть PNG

Все party assets лежат здесь:

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

---

## 10.2. Overlay assets

| Файл | Размер | Использование |
|---|---:|---|
| `overlay_member_frame.png` | `96x19` | обычная рамка участника overlay |
| `overlay_member_frame_leader.png` | `96x19` | рамка лидера party в overlay |
| `overlay_hp_empty.png` | `88x3` | пустая HP bar |
| `overlay_hp_full.png` | `88x3` | заполненная HP bar |
| `overlay_absorption.png` | `88x3` | golden HP поверх HP |
| `overlay_food_empty.png` | `88x2` | пустая food bar |
| `overlay_food_full.png` | `88x2` | заполненная food bar |
| `overlay_custom_bar_empty.png` | variable / recommended `80x6` | пустая custom bar |
| `overlay_custom_bar_full.png` | variable / recommended `80x6` | заполненная custom bar |
| `overlay_value_frame.png` | variable / recommended `80x12` | рамка custom value text |

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

Схема:

```text
+------------------------------------------------+
| Nickname                              LVL 10   |
|                                                |
| [ HP + absorption ]                            |
| [ Food ]                                      |
+------------------------------------------------+
```

---

## 10.3. Screen backgrounds

Фоны рисуются на весь текущий scaled GUI screen. Авторский PNG рекомендуется делать `320x180`, код растягивает его под текущий размер GUI.

| Файл | Рекомендуемый размер | Экран |
|---|---:|---|
| `gui_background.png` | `320x180` | общий fallback-фон для всех party GUI |
| `gui_main_background.png` | `320x180` | Main Party GUI |
| `gui_invite_background.png` | `320x180` | Invite GUI |
| `gui_settings_background.png` | `320x180` | Settings GUI |
| `gui_admin_background.png` | `320x180` | Admin GUI |
| `gui_invite_popup_background.png` | `220x88` | Invite Popup |

Совет: не делай фон слишком контрастным. Поверх него рисуются строки, кнопки и текст.

---

## 10.4. Row / search / scrollbar assets

| Файл | Размер | Где используется |
|---|---:|---|
| `gui_member_frame.png` | `300x34` | строка участника в Main Party GUI |
| `gui_online_player_row.png` | `300x22` | строка игрока в Invite GUI |
| `gui_admin_player_row.png` | `420x48` | строка игрока в Admin GUI |
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

### `gui_online_player_row.png`

```text
размер: 300x22

nickname:       x=6..120, y=7
status:         x=136..220, y=7
button zone:    справа, 78x20
```

### `gui_admin_player_row.png`

```text
размер: 420x48

player name:    x=6..180, y=6
party info:     x=6..240, y=18
uuid/info:      x=6..260, y=30
buttons:        справа
```

---

# 11. Party button assets — каждый GUI button

## 11.1. Принцип имён

Для каждой кнопки используется схема:

```text
button_<id>.png
button_<id>_hover.png
button_<id>_disabled.png
```

Пример для invite:

```text
button_invite.png
button_invite_hover.png
button_invite_disabled.png
```

Если `hover` отсутствует — используется normal.  
Если `disabled` отсутствует — используется normal.  
Если specific normal отсутствует — используется generic `gui_button.png`.

---

## 11.2. Generic button fallback

| Файл | Размер | Назначение |
|---|---:|---|
| `gui_button.png` | `80x20` | общий fallback normal |
| `gui_button_hover.png` | `80x20` | общий fallback hover |
| `gui_button_disabled.png` | `80x20` | общий fallback disabled |

---

## 11.3. Top tab buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `tab_main` | `button_tab_main.png` | `button_tab_main_hover.png` | `button_tab_main_disabled.png` | `54x20` |
| `tab_invite` | `button_tab_invite.png` | `button_tab_invite_hover.png` | `button_tab_invite_disabled.png` | `58x20` |
| `tab_settings` | `button_tab_settings.png` | `button_tab_settings_hover.png` | `button_tab_settings_disabled.png` | `72x20` |
| `tab_admin` | `button_tab_admin.png` | `button_tab_admin_hover.png` | `button_tab_admin_disabled.png` | `58x20` |

---

## 11.4. Main Party GUI buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `pin` | `button_pin.png` | `button_pin_hover.png` | `button_pin_disabled.png` | `48x18` |
| `unpin` | `button_unpin.png` | `button_unpin_hover.png` | `button_unpin_disabled.png` | `48x18` |
| `kick` | `button_kick.png` | `button_kick_hover.png` | `button_kick_disabled.png` | `48x18` |

---

## 11.5. Invite GUI buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `invite` | `button_invite.png` | `button_invite_hover.png` | `button_invite_disabled.png` | `78x20` |
| `revoke` | `button_revoke.png` | `button_revoke_hover.png` | `button_revoke_disabled.png` | `78x20` |
| `in_party` | `button_in_party.png` | `button_in_party_hover.png` | `button_in_party_disabled.png` | `78x20` |

`in_party` обычно disabled.

---

## 11.6. Settings GUI buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `show_self_on` | `button_show_self_on.png` | `button_show_self_on_hover.png` | `button_show_self_on_disabled.png` | `120x20` |
| `show_self_off` | `button_show_self_off.png` | `button_show_self_off_hover.png` | `button_show_self_off_disabled.png` | `120x20` |
| `pvp_on` | `button_pvp_on.png` | `button_pvp_on_hover.png` | `button_pvp_on_disabled.png` | `120x20` |
| `pvp_off` | `button_pvp_off.png` | `button_pvp_off_hover.png` | `button_pvp_off_disabled.png` | `120x20` |
| `reset_position` | `button_reset_position.png` | `button_reset_position_hover.png` | `button_reset_position_disabled.png` | `180x20` |

---

## 11.7. Admin GUI top buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `admin_system_on` | `button_admin_system_on.png` | `button_admin_system_on_hover.png` | `button_admin_system_on_disabled.png` | `80x20` |
| `admin_system_off` | `button_admin_system_off.png` | `button_admin_system_off_hover.png` | `button_admin_system_off_disabled.png` | `86x20` |
| `admin_refresh` | `button_admin_refresh.png` | `button_admin_refresh_hover.png` | `button_admin_refresh_disabled.png` | `70x20` |

---

## 11.8. Admin GUI row buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `admin_view` | `button_admin_view.png` | `button_admin_view_hover.png` | `button_admin_view_disabled.png` | `46x18` |
| `admin_remove` | `button_admin_remove.png` | `button_admin_remove_hover.png` | `button_admin_remove_disabled.png` | `60x18` |
| `admin_disband` | `button_admin_disband.png` | `button_admin_disband_hover.png` | `button_admin_disband_disabled.png` | `64x18` |
| `admin_pvp_on` | `button_admin_pvp_on.png` | `button_admin_pvp_on_hover.png` | `button_admin_pvp_on_disabled.png` | `62x18` |
| `admin_pvp_off` | `button_admin_pvp_off.png` | `button_admin_pvp_off_hover.png` | `button_admin_pvp_off_disabled.png` | `62x18` |
| `admin_limit_4` | `button_admin_limit_4.png` | `button_admin_limit_4_hover.png` | `button_admin_limit_4_disabled.png` | `30x18` |
| `admin_limit_8` | `button_admin_limit_8.png` | `button_admin_limit_8_hover.png` | `button_admin_limit_8_disabled.png` | `30x18` |
| `admin_limit_16` | `button_admin_limit_16.png` | `button_admin_limit_16_hover.png` | `button_admin_limit_16_disabled.png` | `38x18` |

---

## 11.9. Invite Popup buttons

| ID | Normal | Hover | Disabled | Размер |
|---|---|---|---|---:|
| `accept` | `button_accept.png` | `button_accept_hover.png` | `button_accept_disabled.png` | `70x20` |
| `decline` | `button_decline.png` | `button_decline_hover.png` | `button_decline_disabled.png` | `70x20` |

---

## 11.10. Полный пример папки assets

```text
assets/<modid>/textures/gui/party/
├── overlay_member_frame.png                  96x19
├── overlay_member_frame_leader.png           96x19
├── overlay_hp_empty.png                      88x3
├── overlay_hp_full.png                       88x3
├── overlay_absorption.png                    88x3
├── overlay_food_empty.png                    88x2
├── overlay_food_full.png                     88x2
├── overlay_custom_bar_empty.png              80x6
├── overlay_custom_bar_full.png               80x6
├── overlay_value_frame.png                   80x12
│
├── gui_background.png                        320x180
├── gui_main_background.png                   320x180
├── gui_invite_background.png                 320x180
├── gui_settings_background.png               320x180
├── gui_admin_background.png                  320x180
├── gui_invite_popup_background.png           220x88
│
├── gui_member_frame.png                      300x34
├── gui_online_player_row.png                 300x22
├── gui_admin_player_row.png                  420x48
├── gui_search.png                            180x20 или 200x20
├── gui_scrollbar_track.png                   6x120
├── gui_scrollbar_thumb.png                   6x20
│
├── gui_button.png                            80x20
├── gui_button_hover.png                      80x20
├── gui_button_disabled.png                   80x20
│
├── button_tab_main.png                       54x20
├── button_tab_main_hover.png                 54x20
├── button_tab_main_disabled.png              54x20
├── button_tab_invite.png                     58x20
├── button_tab_invite_hover.png               58x20
├── button_tab_invite_disabled.png            58x20
├── button_tab_settings.png                   72x20
├── button_tab_settings_hover.png             72x20
├── button_tab_settings_disabled.png          72x20
├── button_tab_admin.png                      58x20
├── button_tab_admin_hover.png                58x20
├── button_tab_admin_disabled.png             58x20
│
├── button_pin.png                            48x18
├── button_pin_hover.png                      48x18
├── button_pin_disabled.png                   48x18
├── button_unpin.png                          48x18
├── button_unpin_hover.png                    48x18
├── button_unpin_disabled.png                 48x18
├── button_kick.png                           48x18
├── button_kick_hover.png                     48x18
├── button_kick_disabled.png                  48x18
│
├── button_invite.png                         78x20
├── button_invite_hover.png                   78x20
├── button_invite_disabled.png                78x20
├── button_revoke.png                         78x20
├── button_revoke_hover.png                   78x20
├── button_revoke_disabled.png                78x20
├── button_in_party.png                       78x20
├── button_in_party_hover.png                 78x20
├── button_in_party_disabled.png              78x20
│
├── button_show_self_on.png                   120x20
├── button_show_self_on_hover.png             120x20
├── button_show_self_on_disabled.png          120x20
├── button_show_self_off.png                  120x20
├── button_show_self_off_hover.png            120x20
├── button_show_self_off_disabled.png         120x20
├── button_pvp_on.png                         120x20
├── button_pvp_on_hover.png                   120x20
├── button_pvp_on_disabled.png                120x20
├── button_pvp_off.png                        120x20
├── button_pvp_off_hover.png                  120x20
├── button_pvp_off_disabled.png               120x20
├── button_reset_position.png                 180x20
├── button_reset_position_hover.png           180x20
├── button_reset_position_disabled.png        180x20
│
├── button_admin_system_on.png                80x20
├── button_admin_system_on_hover.png          80x20
├── button_admin_system_on_disabled.png       80x20
├── button_admin_system_off.png               86x20
├── button_admin_system_off_hover.png         86x20
├── button_admin_system_off_disabled.png      86x20
├── button_admin_refresh.png                  70x20
├── button_admin_refresh_hover.png            70x20
├── button_admin_refresh_disabled.png         70x20
│
├── button_admin_view.png                     46x18
├── button_admin_view_hover.png               46x18
├── button_admin_view_disabled.png            46x18
├── button_admin_remove.png                   60x18
├── button_admin_remove_hover.png             60x18
├── button_admin_remove_disabled.png          60x18
├── button_admin_disband.png                  64x18
├── button_admin_disband_hover.png            64x18
├── button_admin_disband_disabled.png         64x18
├── button_admin_pvp_on.png                   62x18
├── button_admin_pvp_on_hover.png             62x18
├── button_admin_pvp_on_disabled.png          62x18
├── button_admin_pvp_off.png                  62x18
├── button_admin_pvp_off_hover.png            62x18
├── button_admin_pvp_off_disabled.png         62x18
├── button_admin_limit_4.png                  30x18
├── button_admin_limit_4_hover.png            30x18
├── button_admin_limit_4_disabled.png         30x18
├── button_admin_limit_8.png                  30x18
├── button_admin_limit_8_hover.png            30x18
├── button_admin_limit_8_disabled.png         30x18
├── button_admin_limit_16.png                 38x18
├── button_admin_limit_16_hover.png           38x18
├── button_admin_limit_16_disabled.png        38x18
│
├── button_accept.png                         70x20
├── button_accept_hover.png                   70x20
├── button_accept_disabled.png                70x20
├── button_decline.png                        70x20
├── button_decline_hover.png                  70x20
└── button_decline_disabled.png               70x20
```

---

# 12. Как рисовать assets

## 12.1. Кнопки

Кнопка должна быть нарисована в точном размере.

Например:

```text
button_kick.png = 48x18
button_kick_hover.png = 48x18
button_kick_disabled.png = 48x18
```

Не делай `96x36`, если хочешь 2x scale. Minecraft будет рисовать её как `48x18`, и результат может замылиться или обрезаться.

## 12.2. Hover

Hover — это состояние при наведении мыши.

Рекомендуется:

```text
normal: тёмная кнопка
hover: чуть светлее / с подсветкой рамки
disabled: серее и менее контрастно
```

## 12.3. Text zone

Текст кнопки рисуется поверх PNG по центру.

Поэтому в центре кнопки не должно быть слишком ярких деталей.

## 12.4. Фоны

Фоны лучше делать приглушёнными.

```text
gui_main_background.png = 320x180
```

Код растягивает фон на текущий scaled GUI size, поэтому избегай мелкого pixel-art паттерна на весь фон — он может растянуться.

---

# 13. Party name visibility

Добавлены блоки:

```text
hide name tag of player
show name tag of player
hide name tags of all players
show name tags of all players
hide player from server tab list
show player in server tab list
```

## 13.1. Hide name tag

Скрывает ник над головой через scoreboard team:

```text
Team.Visibility.NEVER
```

## 13.2. Hide from TAB

Убирает игрока из TAB list через client packets.

Это не кик и не удаление игрока с сервера. Это только визуальное скрытие в списке игроков.

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

## 14.2. Economy config

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

## 14.3. Economy blocks

```text
is economy enabled
set economy enabled
get wallet
get bank
get total
set wallet
set bank
add wallet
add bank
take wallet
take bank
has wallet
has bank
transfer wallet
calculate transfer fee
move wallet to bank
move bank to wallet
deposit coin items to bank
withdraw coin items from bank
set coin item
format money
convert coin to Cooper
```

---

# 15. Casino System

Casino работает поверх Economy.

## 15.1. Общие casino blocks

```text
take casino bet
give casino payout
calculate casino payout
is casino bet allowed
set casino enabled
set casino house edge
set casino bet limits
```

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

Цвет можно писать так:

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

## 17.1. Блоки чтения

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
set party stat of player key "LVL" to persistent LVL as text
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

## 20.4. LVL в party overlay

Вариант A — отдельная строка:

```text
add party overlay value entry
    id = "lvl"
    label = "LVL"
    value = persistent LVL as text
    x = 0
    y = 92
    width = 60
    height = 10
    texture = ""
```

Вариант B — LVL рядом с каждым участником:

```text
set party stat of player key "LVL" to persistent LVL as text
```

---

# 21. Диагностика

## 21.1. GUI texture не видна

Проверь:

```text
assets/<modid>/textures/gui/party/<file>.png
```

Проверь:

```text
имя lowercase
формат PNG
размер соответствует таблице
ресурс попал в build
```

## 21.2. Кнопка не использует свой PNG

Проверь id:

```text
button_<id>.png
button_<id>_hover.png
button_<id>_disabled.png
```

Например, для кнопки `Kick`:

```text
button_kick.png
button_kick_hover.png
button_kick_disabled.png
```

## 21.3. Admin GUI не показывает party info

Нужны актуальные:

```text
PartyApiSystem
PartyApiNetwork
PartyApiClient
```

Потому что Admin GUI требует расширенный `OnlinePlayerSyncData`.

## 21.4. Party PvP не блокирует урон

Проверь:

```text
pvp_protection_enabled=true
игроки в одной party
party pvp false
PartyApiPvpGuard.java сгенерирован
```

## 21.5. Weight max сбрасывается

Проверь:

```text
set max carry weight вызывается на ServerPlayer
нет другой процедуры, которая снова ставит 64
SavedData мира не удаляется
```

---

# 22. Чеклист

```text
[ ] Build проходит
[ ] runServer запускается
[ ] runClient запускается
[ ] /party gui открывает Main GUI
[ ] Main GUI показывает HP/food барами
[ ] /party invitegui показывает online list
[ ] Invite GUI не показывает HP/food/LVL
[ ] Admin GUI показывает party leaders / members / size
[ ] Button PNG подхватываются
[ ] Hover PNG подхватываются
[ ] Disabled PNG подхватываются
[ ] Overlay PNG подхватываются
[ ] Scrollbar PNG подхватывается
[ ] hide name tag работает
[ ] hide from TAB работает
[ ] Economy wallet/bank сохраняются
[ ] Casino bet limits работают
[ ] Weight max сохраняется
[ ] Hitbox persistent работает
[ ] Attribute blocks компилируются
```
