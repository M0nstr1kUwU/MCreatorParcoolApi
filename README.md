# MCreatorParcoolApi — полная документация плагина

Документация описывает весь плагин **ParCool API / MCreatorParcoolApi** для **MCreator 2025.3 + NeoForge 1.21.1**. Плагин предназначен для связки MCreator-процедур с ParCool, а также добавляет собственные игровые системы: вес, party, экономику, казино, сообщения, хитбоксы, атрибуты и свойства сущностей.

> Важно: названия блоков в MCreator могут немного отличаться в зависимости от последней версии JSON-блоков, но логика и назначение блоков остаются такими же. Если в документации написано `ENTITY`, это почти всегда игрок или сущность из зависимостей процедуры.

---

## 1. Что добавляет плагин

Плагин условно делится на несколько больших систем:

```text
1. ParCool API
   - включение/отключение движений ParCool
   - принудительная синхронизация ParCool permissions
   - работа со stamina
   - клиентский wait
   - управление камерой
   - отключение ванильного прыжка
   - триггеры ParCool-состояний

2. Weight System
   - вес предметов
   - вес инвентаря
   - максимальный переносимый вес игрока
   - проценты загрузки
   - стадии перегруза
   - наказания за перегруз
   - отключение системы веса через конфиг/блоки

3. Party System
   - создание party
   - приглашения
   - GUI приглашений
   - поиск игроков онлайн
   - pin/unpin участников
   - kick
   - showSelf
   - party overlay
   - party chat
   - party PvP guard
   - admin-команды
   - кастомные overlay elements
   - кастомные GUI/overlay PNG-текстуры

4. Economy System
   - 4 валюты: Cooper, Iron, Gold, Platine
   - личный счёт / wallet
   - банковский счёт / bank
   - перевод денег между игроками
   - комиссия
   - потеря wallet-денег при смерти
   - привязка монет к item id
   - депозит/снятие через предметы
   - команды экономики

5. Casino System
   - честный серверный random
   - шанс с house edge
   - dice
   - roulette
   - slots
   - blackjack helper
   - crash helper
   - weighted random
   - готовые шаблоны логики казино

6. Message Tools
   - styled text
   - цвет, bold, italic, underline, strikethrough, obfuscated
   - отправка игроку
   - broadcast
   - отправка nearby
   - отправка операторам
   - party-сообщения

7. Hitbox Tools
   - чтение размеров хитбокса
   - временное изменение хитбокса
   - постоянное изменение хитбокса через SavedData + EntityEvent.Size
   - сброс persistent hitbox

8. Attribute / Entity Property Tools
   - универсальная работа с атрибутами по registry id
   - здоровье, absorption, воздух, огонь, заморозка
   - no gravity, glowing, invulnerable, silent
   - hunger/saturation/exhaustion для игрока
```

---

## 2. Установка и генерация

### 2.1. Куда копировать файлы

Плагин устроен как обычный MCreator plugin. Основные папки:

```text
src/main/resources/plugin.json
src/main/resources/procedures/
src/main/resources/neoforge-1.21.1/generator.yaml
src/main/resources/neoforge-1.21.1/templates/
src/main/resources/neoforge-1.21.1/procedures/
```

Если добавляешь новые блоки:

```text
src/main/resources/procedures/<block_name>.json
src/main/resources/neoforge-1.21.1/procedures/<block_name>.java.ftl
```

Если добавляешь helper-класс:

```text
src/main/resources/neoforge-1.21.1/templates/<helper_name>.java.ftl
```

И обязательно добавляешь его в:

```text
src/main/resources/neoforge-1.21.1/generator.yaml
```

### 2.2. Что делать после замены шаблонов

После замены helper-шаблонов лучше удалить уже сгенерированные Java-файлы в workspace MCreator:

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
```

Потом в MCreator:

```text
Regenerate code
```

Если не удалить старые generated-файлы, MCreator иногда оставляет старую версию класса, и кажется, что новый блок “не работает”.

---

## 3. Server configs

Плагин создаёт несколько server config-файлов в папке:

```text
<workspace or run folder>/config/
```

Обычно это:

```text
<modid>-party-server.toml
<modid>-economy-server.toml
<modid>-weight-server.toml
```

### 3.1. Party config

Пример:

```toml
party_enabled=true
default_show_self=false
default_overlay_x=8
default_overlay_y=58
overlay_nickname_font_scale_percent=80
invite_cooldown_seconds=120
invite_gui_enabled=true
default_max_members=4
hard_max_members=200
admin_permission_level=2

asset_overlay_panel=""
asset_overlay_member_frame=""
asset_overlay_hp_bar_empty=""
asset_overlay_hp_bar_full=""
asset_overlay_absorption_bar_full=""
asset_overlay_food_bar_empty=""
asset_overlay_food_bar_full=""

asset_gui_background=""
asset_gui_button=""
asset_gui_button_hover=""
asset_gui_search=""
asset_gui_scrollbar=""
asset_gui_member_row=""
asset_gui_button_invite=""
asset_gui_button_revoke=""
asset_gui_button_kick=""
asset_gui_button_pin=""
asset_gui_button_unpin=""
```

Пояснение:

| Параметр | Что делает |
|---|---|
| `party_enabled` | Полностью включает/отключает party-систему на сервере. |
| `default_show_self` | Показывать ли игроку самого себя в party overlay по умолчанию. Рекомендуется `false`. |
| `default_overlay_x` | X-координата overlay по умолчанию. |
| `default_overlay_y` | Y-координата overlay по умолчанию. |
| `overlay_nickname_font_scale_percent` | Размер ника в overlay. `80` = 80% от обычного размера. |
| `invite_cooldown_seconds` | Сколько живёт pending invite. Пока invite активен, повторно пригласить того же игрока нельзя. |
| `invite_gui_enabled` | Открывать ли popup приглашения. |
| `default_max_members` | Стандартный лимит участников party. |
| `hard_max_members` | Максимальный технический лимит участников. |
| `admin_permission_level` | Уровень OP-доступа для admin GUI/команд. |

### 3.2. Economy config

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

coin_item_cooper="minecraft:copper_coin_item"
coin_item_iron="minecraft:iron_coin_item"
coin_item_gold="minecraft:gold_coin_item"
coin_item_platine="minecraft:netherite_coin_item"
```

Пояснение:

| Параметр | Что делает |
|---|---|
| `economy_enabled` | Включает/отключает экономику. |
| `casino_enabled` | Включает/отключает казино. |
| `auto_compact_display` | Показывать деньги компактно: Platine / Gold / Iron / Cooper. |
| `death_wallet_loss_percent` | Сколько процентов личного кошелька теряется при смерти. Bank не трогается. |
| `transfer_fee_percent` | Комиссия при переводе между игроками. |
| `casino_house_edge_percent` | Математическое преимущество казино. Например, 5% уменьшает шанс/выплату. |
| `casino_min_bet_cooper` | Минимальная ставка в Cooper. |
| `casino_max_bet_cooper` | Максимальная ставка в Cooper. |
| `coin_item_*` | Item id монеты для депозитов/снятия через предметы. |

### 3.3. Weight config

Пример:

```toml
weight_enabled=true
use_default_punishments=true

stage_1_percent=75.00
stage_2_percent=100.00
stage_3_percent=150.00
stage_4_percent=200.00

stage_1_disable_jump=false
stage_2_disable_jump=true
stage_3_disable_jump=true
stage_4_disable_jump=true
stage_4_darkness=true
```

Пояснение:

| Параметр | Что делает |
|---|---|
| `weight_enabled` | Полностью включает/отключает систему веса. |
| `use_default_punishments` | Если `false`, система считает вес, но стандартные наказания не применяет. |
| `stage_1_percent` | Первый этап нагрузки. По умолчанию 75%. |
| `stage_2_percent` | Второй этап. По умолчанию 100%. |
| `stage_3_percent` | Третий этап. По умолчанию 150%. |
| `stage_4_percent` | Последний этап. По умолчанию 200%. |
| `stage_*_disable_jump` | Отключать ли ванильный прыжок на этом этапе. |
| `stage_4_darkness` | Давать ли darkness на последнем этапе. |

---

## 4. ParCool API

Эта часть плагина отвечает за управление возможностями ParCool у конкретного игрока.

### 4.1. Основная идея

ParCool хранит ограничения игрока через систему `Limitation`. Плагин создаёт собственный bridge limitation id и через него разрешает или запрещает движения.

Проще говоря:

```text
Игрок
  -> ParCool Limitation
      -> разрешить/запретить конкретные Action
      -> применить limitation
      -> принудительно синхронизировать клиент
```

Это нужно потому, что ParCool — не обычный vanilla sprint/jump. Если просто изменить speed или potion effect, ParCool-движения могут всё равно работать.

### 4.2. Блоки движения

Основные блоки:

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

Что отключает каждый блок:

| Блок | Что примерно отключает |
|---|---|
| `disable sprint` | FastRun / ускоренный бег ParCool |
| `disable climb` | ClimbUp / ClimbPoles |
| `disable jump` | ChargeJump / JumpFromBar / WallJump |
| `disable hang` | HangDown / ClingToCliff |
| `disable wall run` | HorizontalWallRun / VerticalWallRun / WallSlide / WallJump |
| `disable all parcool movement abilities` | Все Action из `Actions.LIST` |
| `enable all parcool movement abilities` | Сбрасывает limitation и снова разрешает движения |
| `force sync parcool permissions` | Делает несколько повторных sync-запросов, чтобы клиент точно получил ограничения |

### 4.3. Пример: отключить все движения при перегрузе

Процедура:

```text
Global trigger: On player tick update

if weight load percent of Event/Target entity >= 150
    disable all parcool movement abilities for Event/Target entity
    disable vanilla jump for Event/Target entity
    force sync parcool permissions for Event/Target entity
    send actionbar "Вы перегружены!"
else
    enable all parcool movement abilities for Event/Target entity
    enable vanilla jump for Event/Target entity
    force sync parcool permissions for Event/Target entity
```

Совет: не вызывай `force sync` каждый тик без причины. Лучше делать это при смене стадии перегруза или раз в несколько тиков.

### 4.4. Stamina blocks

В плагине есть блоки для чтения и изменения stamina ParCool:

```text
get parcool stamina
get parcool max stamina
set parcool stamina
set parcool max stamina
add parcool stamina
take parcool stamina
is parcool stamina empty
is parcool stamina full
if parcool stamina reached 0 run until full
```

Особый блок:

```text
if parcool stamina reached 0 run until full
```

Логика такая:

```text
1. Если stamina не падала до 0 — вложенные блоки не выполняются.
2. Когда stamina достигла 0 — включается режим "exhausted".
3. Пока stamina не восстановилась до полного значения — вложенные блоки выполняются.
4. Когда stamina стала full — режим выключается.
```

Пример:

```text
On player tick update
    if parcool stamina reached 0 run until full
        disable all parcool movement abilities
        send actionbar "Вы выдохлись!"
```

### 4.5. Client wait

Блок client wait нужен для клиентских эффектов: камера, GUI, визуальные задержки.

Пример:

```text
switch camera to third person
client wait 40 ticks
switch camera to first person
```

Важно: client wait не должен использоваться для серверной логики экономики, веса, party или урона. Для серверной логики используй обычный server wait / queueServerWork.

### 4.6. Camera blocks

Типовые сценарии:

```text
set camera first person
set camera third person back
set camera third person front
reset camera
client wait
```

Пример кат-сцены:

```text
set camera third person front
client wait 60 ticks
send player message "Ты чувствуешь тяжесть..."
client wait 40 ticks
reset camera
```

---

## 5. Weight System

Система веса считает общий вес предметов игрока и сравнивает его с максимальным переносимым весом.

### 5.1. Как считается вес

У каждого item id есть вес одной штуки:

```text
minecraft:stone = 1.0
minecraft:diamond = 0.2
modid:big_sword = 15.0
```

Вес стака:

```text
unit_weight * count
```

Вес инвентаря:

```text
main inventory + armor + offhand
```

Процент загрузки:

```text
current_weight / max_weight * 100
```

Пример:

```text
max weight = 100
inventory weight = 75
load percent = 75%
```

### 5.2. Основные блоки веса

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
get inventory weight of player
set max carry weight of player
get max carry weight of player
set default max carry weight
get load percent of player
get rounded load percent
is player overloaded
get weight status
set weight auto enabled
is weight auto enabled
set weight system enabled
is weight system enabled
set weight default punishments enabled
set weight punishment stage
```

### 5.3. Item ID для предметов из других модов

Для предметов из других модов используй блок:

```text
set item weight by id ITEM_ID to WEIGHT
```

Примеры item id:

```text
minecraft:diamond
minecraft:netherite_sword
irons_spellbooks:arcane_essence
alexsmobs:bear_fur
yourmod:heavy_backpack
```

Если namespace не указан, плагин обычно воспринимает id как `minecraft:<id>`. Лучше всегда писать полностью.

### 5.4. Пример: задать вес всем предметам при старте сервера

```text
Global trigger: Server started

set default item weight to 0.1
set item weight by id "minecraft:stone" to 1
set item weight by id "minecraft:cobblestone" to 1
set item weight by id "minecraft:iron_ingot" to 0.5
set item weight by id "minecraft:gold_ingot" to 0.8
set item weight by id "minecraft:diamond" to 0.2
set item weight by id "minecraft:netherite_sword" to 12
```

### 5.5. Пример: максимальный вес игрока

```text
Global trigger: Player joins world

set max carry weight of Event/Target entity to 100
set weight auto enabled of Event/Target entity to true
```

Если у игрока есть прокачка:

```text
max = 100 + player_strength_level * 10
set max carry weight to max
```

### 5.6. Стадии перегруза

По умолчанию:

| Стадия | Процент | Идея |
|---|---:|---|
| 0 | 0–74% | Нормально |
| 1 | 75–99% | Тяжеловато |
| 2 | 100–149% | Перегруз |
| 3 | 150–199% | Сильный перегруз |
| 4 | 200%+ | Критический перегруз + darkness |

Пример наказаний:

```text
if weight status = 1
    slightly slow player

if weight status = 2
    disable vanilla jump
    disable sprint

if weight status = 3
    disable all parcool movement abilities
    heavy effect

if weight status = 4
    disable all parcool movement abilities
    disable vanilla jump
    darkness
```

### 5.7. Как сделать свои наказания

В config:

```toml
use_default_punishments=false
```

Потом процедурой:

```text
On player tick update

if weight system enabled
    if load percent >= 75 and load percent < 100
        send actionbar "Тяжёлый рюкзак"

    if load percent >= 100 and load percent < 150
        disable sprint
        disable vanilla jump

    if load percent >= 150
        disable all parcool movement abilities

    if load percent >= 200
        give darkness
```

---

## 6. Party System

Party System — это система группы игроков с overlay, GUI, приглашениями, PvP-настройками и party chat.

### 6.1. Команды party

Основные команды:

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

Admin-команды:

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

### 6.2. GUI party

Плагин добавляет несколько экранов:

| GUI | Что делает |
|---|---|
| Main GUI | Показывает участников party, HP, еду, кнопки Pin/Unpin и Kick. |
| Invite GUI | Показывает всех онлайн-игроков, поиск по нику, Invite/Revoke. |
| Settings GUI | Show self, PvP, reset overlay position. |
| Admin GUI | Видна только игрокам с OP permission level из конфига. |
| Invite Popup | Всплывающее окно Accept/Decline при приглашении. |

### 6.3. Party overlay

Overlay рисуется поверх игры. По умолчанию:

```text
x = 8
y = 58
```

То есть слева, но примерно на 50 пикселей выше старого положения.

Overlay показывает:

```text
nickname
HP bar
golden HP / absorption поверх HP
food bar
рамку участника
leader marker
```

Если участников больше 4, overlay показывает только 4 закреплённых. Остальные доступны в GUI со скроллом.

### 6.4. showSelf

`showSelf` отвечает за то, видит ли игрок самого себя в своём party overlay.

По умолчанию:

```text
default_show_self=false
```

То есть игрок видит только союзников, а не самого себя.

Изменить командой:

```text
/party showself true
/party showself false
```

Изменить блоком:

```text
set party show self of ENTITY to VALUE
```

### 6.5. Invite cooldown

Логика invite:

```text
1. Leader отправляет invite.
2. Target получает popup.
3. Пока invite pending, повторно кинуть invite тому же target нельзя.
4. Invite пропадает, если:
   - target accepted
   - target declined
   - leader revoked
   - вышло invite_cooldown_seconds
```

В Invite GUI:

```text
если invite ещё не отправлен -> кнопка Invite
если invite уже pending -> кнопка Revoke
если игрок уже в party -> In party
```

### 6.6. Party PvP

Если PvP выключен:

```text
party.pvp=false
```

то урон между участниками одной party должен отменяться через PartyApiPvpGuard.

Команда:

```text
/party pvp false
/party pvp true
```

Admin-команда:

```text
/party admin pvp <player> false
```

### 6.7. Party chat

Команда:

```text
/party chat Привет всем!
```

Сообщение видят только участники party.

Важный момент: команда не должна писать отправителю лишнее сообщение “Party message sent”. Иначе чат засоряется.

---

## 7. Party GUI textures

Это самый важный раздел для кастомизации.

### 7.1. Куда класть текстуры

Путь:

```text
src/main/resources/assets/<modid>/textures/gui/party/
```

Пример для мода `encorecraftnew`:

```text
src/main/resources/assets/encorecraftnew/textures/gui/party/
```

Файлы:

```text
overlay_member_frame.png
overlay_hp_empty.png
overlay_hp_full.png
overlay_absorption.png
overlay_food_empty.png
overlay_food_full.png

gui_background.png
gui_member_frame.png
gui_button.png
gui_button_hover.png
gui_search.png
gui_scrollbar.png
gui_member_row.png
button_pin.png
button_unpin.png
button_invite.png
button_revoke.png
button_kick.png
```

Если файла нет, плагин использует fallback — обычные прямоугольники и полоски.

### 7.2. Рекомендуемые размеры PNG

#### Overlay

| Файл | Размер | Назначение |
|---|---:|---|
| `overlay_member_frame.png` | `96x19` | Рамка одного участника в overlay |
| `overlay_hp_empty.png` | `88x3` | Пустая полоска HP |
| `overlay_hp_full.png` | `88x3` | Заполненная полоска HP |
| `overlay_absorption.png` | `88x3` | Золотые HP поверх обычных |
| `overlay_food_empty.png` | `88x2` | Пустая полоска еды |
| `overlay_food_full.png` | `88x2` | Заполненная полоска еды |

#### Main GUI

| Файл | Размер | Назначение |
|---|---:|---|
| `gui_background.png` | `320x220` | Фон party GUI |
| `gui_member_frame.png` | `280x28` | Рамка участника в GUI |
| `gui_button.png` | `80x20` | Обычная кнопка |
| `gui_button_hover.png` | `80x20` | Кнопка при наведении |
| `gui_search.png` | `180x20` | Поле поиска |
| `gui_scrollbar.png` | `6x120` | Скроллбар |
| `gui_member_row.png` | `280x28` | Строка игрока |

#### Кнопки

| Файл | Размер | Назначение |
|---|---:|---|
| `button_pin.png` | `44x16` | Pin |
| `button_unpin.png` | `44x16` | Unpin |
| `button_invite.png` | `78x20` | Invite |
| `button_revoke.png` | `78x20` | Revoke |
| `button_kick.png` | `48x18` | Kick |

### 7.3. Как рисовать overlay_member_frame.png

Рекомендуемая структура:

```text
96x19 px

0..95   width
0..18   height

верхняя рамка: 1 px
нижняя рамка: 1 px
левая рамка: 1 px
правая рамка: 1 px
фон: полупрозрачный
```

Пример разметки:

```text
+------------------------------------------------+
| Nickname                                       |  y=2
| HP bar                                         |  y=11, height 3
| Food bar                                       |  y=14, height 2
+------------------------------------------------+
```

### 7.4. Как рисовать HP bar

`overlay_hp_empty.png`:

```text
88x3
тёмно-красная/тёмная пустая подложка
```

`overlay_hp_full.png`:

```text
88x3
красная заполненная полоска
```

Плагин сам обрежет `overlay_hp_full.png` по проценту HP.

Например:

```text
health = 10
maxHealth = 20
ratio = 50%
отрисуется 44 px из 88 px
```

### 7.5. Golden HP / absorption

`overlay_absorption.png` рисуется поверх HP bar.

Если у игрока есть absorption:

```text
absorption > 0
```

то поверх красной полосы появится золотая.

Рекомендация:

```text
88x3 px
цвет: #FFD966 или похожий золотой
можно сделать прозрачность 70–90%
```

### 7.6. Food bar

`overlay_food_empty.png` и `overlay_food_full.png`:

```text
88x2 px
```

Food bar специально тоньше HP, чтобы overlay был компактным.

Положение в overlay:

```text
foodY = y + 14
```

То есть на 1 px выше, чем в прошлой версии.

### 7.7. Как сделать новые текстуры

1. Создай PNG нужного размера.
2. Назови файл точно как ожидает плагин.
3. Положи в:

```text
assets/<modid>/textures/gui/party/
```

4. Перезапусти client или сделай resource reload.
5. Если текстура не найдена — плагин молча использует fallback.

### 7.8. Частые ошибки с текстурами

| Проблема | Причина |
|---|---|
| Текстура не отображается | Неверный путь или namespace modid |
| Вместо PNG рисуется прямоугольник | Плагин не нашёл файл |
| Текстура растянута | Размер PNG отличается от ожидаемого |
| HP bar выглядит криво | В full/empty разные размеры |
| Кнопка не совпадает с кликом | PNG больше/меньше размера кнопки в коде |
| Всё слишком крупное | Нужно уменьшить исходный PNG или изменить размеры в client helper |
| GUI слишком тёмный | У фона слишком большая непрозрачность |

---

## 8. Party overlay custom entries

Плагин позволяет добавлять свои элементы в overlay через блоки.

### 8.1. Value entry

Блок:

```text
add party overlay value entry
```

Параметры:

```text
ENTITY     игрок, для которого добавляем элемент
ID         уникальный id элемента
LABEL      подпись
VALUE      значение
X          смещение по X от overlay
Y          смещение по Y от overlay
WIDTH      ширина
HEIGHT     высота
TEXTURE    имя текстуры или пусто
```

Пример:

```text
add party overlay value entry
    entity = Event/Target entity
    id = "coins"
    label = "Coins"
    value = "150"
    x = 0
    y = 90
    width = 80
    height = 10
    texture = ""
```

### 8.2. Bar entry

Блок:

```text
add party overlay bar entry
```

Пример stamina bar:

```text
add party overlay bar entry
    entity = Event/Target entity
    id = "stamina"
    label = "Stamina"
    current = get parcool stamina
    max = get parcool max stamina
    x = 0
    y = 105
    width = 88
    height = 4
    texture = ""
```

### 8.3. Как обновлять custom overlay

Custom overlay entries не должны создаваться каждый тик бесконтрольно. Лучше:

```text
On player tick update
    if tick % 20 == 0
        clear custom party overlay entries
        add value entry coins
        add bar entry stamina
```

---

## 9. Economy System

Экономика хранит все деньги внутри как Cooper.

Курс:

```text
100 Cooper = 1 Iron
100 Iron = 1 Gold
1000 Gold = 1 Platine
```

В Cooper это:

```text
1 Cooper = 1
1 Iron = 100
1 Gold = 10 000
1 Platine = 10 000 000
```

### 9.1. Wallet и Bank

У игрока два счёта:

```text
wallet — личные деньги
bank   — банковский счёт
```

При смерти:

```text
игрок теряет death_wallet_loss_percent от wallet
bank не трогается
```

По умолчанию:

```text
death_wallet_loss_percent = 25
```

### 9.2. Основные блоки экономики

```text
is economy enabled
set economy enabled

coin value
convert amount/unit to cooper
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

deposit wallet to bank
withdraw bank to wallet

deposit coin items
withdraw coin items
set coin item id
get coin item id
```

### 9.3. Пример: выдать игроку 5 Gold

```text
amount = convert 5 GOLD to Cooper
add wallet of Event/Target entity by amount
send message "Вы получили 5 Gold"
```

Внутри:

```text
5 Gold = 5 * 10 000 = 50 000 Cooper
```

### 9.4. Пример: перевод между игроками

```text
if wallet of sender >= 1000 Cooper
    transfer wallet sender -> target amount 1000
else
    send sender "Недостаточно денег"
```

Если комиссия 10%:

```text
sender потеряет 1000 Cooper
target получит 900 Cooper
fee = 100 Cooper
```

### 9.5. Депозит монетами-предметами

В config:

```toml
coin_item_cooper="yourmod:cooper_coin"
coin_item_iron="yourmod:iron_coin"
coin_item_gold="yourmod:gold_coin"
coin_item_platine="yourmod:platine_coin"
```

Логика:

```text
игрок кладёт coin item
блок deposit coin items считает предметы
предметы удаляются
деньги добавляются в wallet/bank
```

### 9.6. Снятие денег предметами

```text
withdraw 10 Gold as item coins
```

Плагин:

```text
проверяет баланс
отнимает деньги
выдаёт item coin из config
```

---

## 10. Casino System

Казино строится поверх экономики. Оно использует серверный random и настройки:

```toml
casino_enabled=true
casino_house_edge_percent=5
casino_min_bet_cooper=100
casino_max_bet_cooper=1000000
```

### 10.1. Блоки random

```text
casino roll int min max
casino roll double min max
casino chance percent apply house edge
casino coin flip
casino dice sum dice sides
casino dice csv dice sides
weighted random index
weighted multiplier
csv value at index
```

### 10.2. Roulette

Блоки/методы:

```text
roulette number
roulette color
roulette is win betType choice number
roulette payout multiplier
```

Типы ставок:

```text
STRAIGHT
COLOR
EVEN_ODD
LOW_HIGH
DOZEN
COLUMN
```

Примеры choice:

```text
COLOR: RED / BLACK / GREEN
EVEN_ODD: EVEN / ODD
LOW_HIGH: LOW / HIGH
DOZEN: FIRST / SECOND / THIRD
COLUMN: FIRST / SECOND / THIRD
STRAIGHT: "17"
```

Пример процедуры рулетки:

```text
bet = 1000 Cooper
if take wallet player bet
    number = roulette number
    if roulette is win "COLOR" "RED" number
        payout = bet * roulette payout multiplier "COLOR"
        add wallet player payout
        send "Выпало RED, победа!"
    else
        send "Вы проиграли. Выпало " + number
```

### 10.3. Slots

Блоки/методы:

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

Шаблон процедуры:

```text
bet = 500 Cooper
if take wallet player bet
    result = slot result 6
    multiplier = slot payout multiplier result 10 2 0

    if multiplier > 0
        payout = bet * multiplier
        add wallet player payout
        send "Слоты: " + result + " Победа: " + format money payout
    else
        send "Слоты: " + result + " Проигрыш"
```

### 10.4. Blackjack helper

Блоки/методы:

```text
card rank
card suit
card name
blackjack card value
blackjack hand value
blackjack is bust
blackjack dealer should hit
```

Пример логики:

```text
playerHand = "1,10"
dealerHand = "9,7"

if blackjack hand value playerHand == 21
    payout = bet * 2.5
```

### 10.5. Crash

Блоки/методы:

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

### 10.6. Weighted random

Пример:

```text
weights = "70,25,5"
multipliers = "0,2,10"
multiplier = weighted multiplier weights multipliers 0
```

Это значит:

```text
70% -> x0
25% -> x2
5%  -> x10
```

---

## 11. Message Tools

Message Tools нужны, чтобы делать красивые сообщения без ручного Java.

### 11.1. Styled text

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

Цвет можно писать:

```text
#FFAA00
FFAA00
0xFFAA00
```

Пример:

```text
styled text:
    text = "Вы перегружены!"
    color = "#AA0000"
    bold = true
    italic = false
    underlined = false
    strikethrough = false
    obfuscated = false
```

### 11.2. Отправка сообщений

```text
send styled message to entity
broadcast styled message
send styled message to operators
send styled message nearby entity radius
prefix message
```

Пример:

```text
message = styled "Вы нашли золото!" color "#FFD700" bold true
send message to player
```

---

## 12. Hitbox Tools

Hitbox Tools позволяют менять размеры хитбокса сущности.

### 12.1. Временный и постоянный хитбокс

Временный:

```text
set temporary hitbox width height
```

Это просто меняет bounding box. Minecraft может пересчитать его позже.

Постоянный:

```text
set persistent hitbox width height
```

Работает через:

```text
SavedData
EntityEvent.Size
event.setNewSize(...)
entity.refreshDimensions()
```

То есть размер будет переустанавливаться при пересчёте размера сущности.

### 12.2. Блоки хитбоксов

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

### 12.3. Пример: большой босс

```text
When entity spawned
    set persistent hitbox of entity width 2.5 height 4.0
    refresh hitbox dimensions
```

### 12.4. Пример: вернуть обычный хитбокс

```text
clear persistent hitbox of entity
refresh hitbox dimensions
```

### 12.5. Важный нюанс

Игроки и некоторые сущности могут иметь клиентскую prediction-логику. Серверный хитбокс будет правильный для логики/коллизий, но визуальный F3+B может обновиться не мгновенно.

---

## 13. Attribute Tools

Attribute Tools дают универсальный доступ к атрибутам через registry id.

### 13.1. Основные блоки

```text
base attribute ATTRIBUTE_ID of ENTITY
final attribute ATTRIBUTE_ID of ENTITY
set base attribute ATTRIBUTE_ID of ENTITY to VALUE
add VALUE to base attribute ATTRIBUTE_ID of ENTITY
multiply base attribute ATTRIBUTE_ID of ENTITY by VALUE
does ENTITY have attribute ATTRIBUTE_ID
```

### 13.2. Примеры attribute id

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

### 13.3. Пример: увеличить scale

```text
set base attribute "minecraft:scale" of entity to 1.5
```

### 13.4. Пример: временно замедлить игрока

```text
oldSpeed = base attribute "minecraft:movement_speed"
set base attribute "minecraft:movement_speed" to oldSpeed * 0.5
wait 100 ticks
set base attribute "minecraft:movement_speed" to oldSpeed
```

---

## 14. Entity / Player Property Tools

Эти блоки работают не с registry attributes, а с прямыми свойствами сущности.

### 14.1. Health

```text
health of ENTITY
max health of ENTITY
set health of ENTITY to VALUE
heal ENTITY by VALUE
damage ENTITY by VALUE
```

### 14.2. Absorption

```text
absorption of ENTITY
set absorption of ENTITY to VALUE
```

### 14.3. Air / fire / freeze

```text
air supply of ENTITY
set air supply of ENTITY to VALUE

fire ticks of ENTITY
set fire ticks of ENTITY to VALUE

freeze ticks of ENTITY
set freeze ticks of ENTITY to VALUE
```

### 14.4. Boolean-свойства

```text
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
```

### 14.5. Player food

```text
food level of ENTITY
set food level of ENTITY to VALUE

saturation of ENTITY
set saturation of ENTITY to VALUE

set exhaustion of ENTITY to VALUE
```

---

## 15. Spawn item block

Плагин добавляет блок, похожий на стандартный MCreator spawn item, но с количеством и задержкой:

```text
spawn item ITEM at x y z count COUNT delay DELAY removable REMOVABLE
```

Параметры:

| Параметр | Значение |
|---|---|
| `ITEM` | ItemStack / предмет |
| `x y z` | координаты |
| `COUNT` | количество предметов |
| `DELAY` | задержка перед появлением |
| `REMOVABLE` | можно ли удалить/убрать позже |

Пример:

```text
spawn minecraft:gold_ingot at x y z count 5 delay 20 removable true
```

---

## 16. Entity in cube block

Блок:

```text
if entity is inside cube x1 y1 z1 x2 y2 z2 do
```

Логика:

```text
minX = min(x1, x2)
maxX = max(x1, x2)
...
entity position внутри диапазона
```

Пример зоны:

```text
if player inside cube 10 60 10 30 80 30
    send "Вы вошли в зону казино"
```

---

## 17. Триггеры

Плагин добавляет/использует несколько типов событий.

### 17.1. ParCool triggers

Примеры:

```text
when ParCool permission force synced
when ParCool movement ability changed
when stamina reached 0
when stamina recovered to full
```

### 17.2. Weight triggers

Примеры:

```text
when weight status changed
when overload started
when overload ended
when critical overload started
```

### 17.3. Party triggers

Полезные события:

```text
party created
player invited
invite accepted
invite declined
invite revoked
party member joined
party member left
party member kicked
party PvP changed
party system enabled/disabled
overlay layout initialized
```

### 17.4. Economy triggers

Полезные события:

```text
wallet changed
bank changed
money transferred
player lost money on death
casino bet placed
casino payout
casino loss
```

Если каких-то событий ещё нет отдельными procedure triggers, их можно имитировать через обычные MCreator triggers + проверки состояния, например `Player tick update`.

---

## 18. Рекомендуемые procedure-шаблоны

### 18.1. Инициализация игрока

```text
Trigger: Player joins world

set max carry weight player to 100
set weight auto enabled player true
set party show self player false
set party overlay position player x 8 y 58
```

### 18.2. Инициализация весов предметов

```text
Trigger: Server started

set default item weight 0.1
set item weight by id "minecraft:stone" 1
set item weight by id "minecraft:iron_ingot" 0.5
set item weight by id "minecraft:gold_ingot" 0.8
set item weight by id "minecraft:netherite_sword" 12
```

### 18.3. Открыть party invite GUI предметом

```text
Trigger: Right click with item

if item = yourmod:party_phone
    open party invite GUI for player
```

### 18.4. Добавить деньги за квест

```text
Trigger: Quest completed

amount = convert 3 GOLD to Cooper
add wallet player amount
send styled message "Получено: 3 Gold" color "#FFD700"
```

### 18.5. Слот-машина

```text
Trigger: Right click slot machine block

bet = 100 Cooper

if take wallet player bet
    result = slot result 6
    multiplier = slot payout multiplier result 10 2 0

    if multiplier > 0
        payout = bet * multiplier
        add wallet player payout
        send "Победа! " + result
    else
        send "Проигрыш. " + result
else
    send "Недостаточно денег"
```

### 18.6. Party overlay stamina

```text
Trigger: Player tick update, every 20 ticks

clear custom party overlay entries player

add party overlay bar entry:
    id = "stamina"
    label = "Stamina"
    current = parcool stamina
    max = parcool max stamina
    x = 0
    y = 105
    width = 88
    height = 4
    texture = ""
```

---

## 19. Лучшие практики

### 19.1. Server side

Делай на сервере:

```text
деньги
вес
party состав
party PvP
урон
hitbox logic
attributes
ParCool limitations
```

На клиенте оставляй:

```text
GUI
overlay
camera
client wait
визуальные эффекты
```

### 19.2. Не делай тяжёлую логику каждый тик

Плохо:

```text
каждый тик пересчитывать всё, писать конфиг, синкать клиента
```

Лучше:

```text
каждые 10–20 тиков
или при изменении состояния
```

### 19.3. Не сохраняй layout каждый кадр

Overlay layout лучше задавать:

```text
при входе игрока
при смене настройки
при открытии GUI настроек
при специальном trigger init layout
```

### 19.4. Используй registry id

Для модовых предметов и атрибутов всегда пиши полный id:

```text
modid:item_name
minecraft:movement_speed
```

Не полагайся на короткое имя.

---

## 20. Диагностика проблем

### 20.1. Блок появился, но не генерирует код

Проверь:

```text
src/main/resources/procedures/block.json
src/main/resources/neoforge-1.21.1/procedures/block.java.ftl
```

В JSON:

```json
"mcreator": {
  "toolbox_id": "...",
  "inputs": [...]
}
```

### 20.2. Helper не создаётся

Проверь `generator.yaml`:

```yaml
- template: helper.java.ftl
  name: "@SRCROOT/@BASEPACKAGEPATH/package/Helper.java"
```

Потом удали старый generated Java и сделай `Regenerate code`.

### 20.3. GUI PNG не отображается

Проверь путь:

```text
assets/<modid>/textures/gui/party/file.png
```

Проверь размер PNG. Если размер другой, Minecraft растянет текстуру.

### 20.4. Party PvP не работает

Проверь:

```text
PartyApiPvpGuard.java создан
generator.yaml содержит party_api_pvp_guard.java.ftl
/party pvp false
игроки реально в одной party
```

### 20.5. Weight max сбрасывается

Проверь:

```text
ParCoolApiWeightSystem SavedData
set max carry weight вызывается на ServerPlayer
не вызывается ли где-то set default max weight обратно на 64
```

### 20.6. ParCool движения не отключаются сразу

Используй:

```text
disable all parcool movement abilities
force sync parcool permissions
```

Иногда клиент ParCool получает sync не мгновенно, поэтому bridge делает несколько повторных sync-запросов.

---

## 21. Мини-чеклист перед релизом

```text
[ ] runServer запускается без compile errors
[ ] runClient запускается без payload mismatch
[ ] /party create работает
[ ] /party invitegui открывает GUI
[ ] invite / accept / decline / revoke работают
[ ] showSelf false не показывает самого игрока
[ ] overlay x/y работает
[ ] PNG fallback работает при отсутствии текстур
[ ] PNG кастомизация работает при наличии текстур
[ ] /party pvp false блокирует урон союзникам
[ ] weight max сохраняется после перезахода
[ ] weight max сохраняется после рестарта сервера
[ ] economy wallet/bank сохраняются
[ ] death wallet loss работает
[ ] casino min/max bet работает
[ ] hitbox persistent переживает refreshDimensions
[ ] attributes compile на текущих mappings
```

---

## 22. Короткая карта файлов

```text
parcool/
  ParCoolApiRuntime.java
  ParCoolApiMovementBridge.java
  ParCoolApiStaminaBridge.java
  ParCoolApiStaminaMonitor.java
  ParCoolApiVanillaJumpBridge.java

weight/
  ParCoolApiWeightSystem.java
  ParCoolApiWeightConfig.java

party/
  PartyApiSystem.java
  PartyApiCommands.java
  PartyApiServerConfig.java
  PartyApiPvpGuard.java
  PartyApiChatGuard.java

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

network/
  ParCoolApiCameraNetwork.java
  ParCoolApiWeightNetwork.java
  PartyApiNetwork.java

client/
  ParCoolApiClientScheduler.java
  PartyApiClient.java
```

---

## 23. Главная идея архитектуры

Плагин лучше воспринимать как “набор мостов”:

```text
MCreator blocks
    -> .java.ftl generation
        -> helper Java class
            -> Minecraft / NeoForge / ParCool API
```

То есть блоки не должны содержать тяжёлую логику напрямую. Они должны вызывать helper:

```java
PartyApiSystem.setShowSelf(player, false);
EconomyApiSystem.addWallet(player, amount);
ParCoolApiWeightSystem.setItemWeightById("minecraft:stone", 1.0);
HitboxApiBridge.setPersistentHitbox(entity, 2.0, 3.0);
```

Так проще чинить баги: меняется helper, а все блоки продолжают работать.
