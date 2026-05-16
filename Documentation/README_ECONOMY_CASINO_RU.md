# Economy & Casino Update

## Что добавлено

Система экономики для MCreator / NeoForge 1.21.1:

```text
4 валюты: Cooper, Iron, Gold, Platine
100 Cooper = 1 Iron
100 Iron = 1 Gold
1000 Gold = 1 Platine
```

Внутри всё хранится в Cooper units (`long`), поэтому конвертация точная и не теряет дроби.

Есть два счёта:

```text
wallet / личный счёт
bank / банковский счёт
```

При смерти игрок теряет процент денег только из wallet. Bank не трогается.

По умолчанию:

```text
death_wallet_loss_percent = 25
transfer_fee_percent = 0
casino_house_edge_percent = 5
```

## generator.yaml

Добавь в `base_templates`:

```yaml
  - template: economy_api_server_config.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/economy/EconomyApiServerConfig.java"

  - template: economy_api_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/economy/EconomyApiSystem.java"

  - template: economy_api_events.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/economy/EconomyApiEvents.java"

  - template: economy_api_commands.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/economy/EconomyApiCommands.java"

  - template: economy_api_casino.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/economy/EconomyApiCasino.java"

```

## Helper files

Класть в:

```text
src/main/resources/neoforge-1.21.1/templates/
```

```text
economy_api_server_config.java.ftl
economy_api_system.java.ftl
economy_api_events.java.ftl
economy_api_commands.java.ftl
economy_api_casino.java.ftl
```

После замены удалить generated-файлы:

```text
src/main/java/net/mcreator/<modid>/economy/EconomyApiServerConfig.java
src/main/java/net/mcreator/<modid>/economy/EconomyApiSystem.java
src/main/java/net/mcreator/<modid>/economy/EconomyApiEvents.java
src/main/java/net/mcreator/<modid>/economy/EconomyApiCommands.java
src/main/java/net/mcreator/<modid>/economy/EconomyApiCasino.java
```

И выполнить:

```text
Regenerate code
```

## Server config

Файл создаётся автоматически:

```text
config/<modid>-economy-server.toml
```

Пример:

```toml
economy_enabled=true
casino_enabled=true
auto_compact_display=true

death_wallet_loss_percent=25.0000
transfer_fee_percent=0.0000

casino_house_edge_percent=5.0000
casino_min_bet_cooper=1
casino_max_bet_cooper=1000000

coin_item_cooper="minecraft:copper_ingot"
coin_item_iron="minecraft:iron_ingot"
coin_item_gold="minecraft:gold_ingot"
coin_item_platine="minecraft:netherite_ingot"
```

`coin_item_*` — предметы, которые используются для пополнения/снятия банка item-монетами.

## Commands

Игроки:

```text
/eco wallet
/eco bank
/eco balance
/eco pay <player> <amount> <unit>
/eco bank deposit <amount> <unit>
/eco bank withdraw <amount> <unit>
/eco coins deposit <coin> [items]
/eco coins withdraw <coin> <items>
```

Примеры:

```text
/eco pay Steve 5 Gold
/eco bank deposit 10 Iron
/eco coins deposit Cooper
/eco coins withdraw Gold 3
```

Админы:

```text
/eco balance <player>
/eco admin reloadconfig
/eco admin enabled <true|false>
/eco admin casino <true|false>
/eco admin setwallet <player> <amount> <unit>
/eco admin setbank <player> <amount> <unit>
/eco admin addwallet <player> <amount> <unit>
/eco admin addbank <player> <amount> <unit>
/eco admin fee <percent>
/eco admin deathloss <percent>
/eco admin houseedge <percent>
/eco admin betlimits <minCooper> <maxCooper>
/eco admin coinitem <coin> <item_id>
```

## economy_tools blocks

```text
wallet balance of ENTITY
bank balance of ENTITY
total money of ENTITY

set wallet of ENTITY to AMOUNT COIN
add AMOUNT COIN to wallet of ENTITY
take AMOUNT COIN from wallet of ENTITY
does ENTITY have AMOUNT COIN in wallet

set bank of ENTITY to AMOUNT COIN
add AMOUNT COIN to bank of ENTITY
take AMOUNT COIN from bank of ENTITY
does ENTITY have AMOUNT COIN in bank

transfer AMOUNT COIN from wallet of FROM to wallet of TO
move AMOUNT COIN from wallet to bank of ENTITY
move AMOUNT COIN from bank to wallet of ENTITY

deposit AMOUNT_ITEMS COIN coin items from ENTITY to bank
withdraw AMOUNT_ITEMS COIN coin items from bank of ENTITY

format money AMOUNT cooper
AMOUNT COIN in cooper

economy transfer fee percent
set economy transfer fee percent to PERCENT
is economy enabled
set economy enabled to ENABLED
```

## casino_tools blocks

```text
take casino bet AMOUNT COIN from ENTITY
give casino payout to ENTITY bet AMOUNT COIN multiplier MULTIPLIER

casino random integer from MIN to MAX
casino chance PERCENT apply house edge? HOUSE_EDGE
casino coin flip heads?
casino roulette number
casino roulette color of number NUMBER
casino slot result with SYMBOLS symbols
casino slot result RESULT all equal
casino weighted random index from weights WEIGHTS
casino payout for bet BET cooper multiplier MULTIPLIER apply house edge? HOUSE_EDGE
is casino bet AMOUNT COIN allowed
```

## Реалистичная логика казино

Рекомендуемая схема:

```text
1. Проверить: is casino bet allowed
2. take casino bet
3. Сгенерировать результат серверным RNG
4. Если игрок выиграл — give casino payout
```

Пример roulette:

```text
take casino bet 10 Gold from player
number = casino roulette number
color = casino roulette color of number number

if color == "RED" and player selected RED:
    give casino payout bet 10 Gold multiplier 2
```

Пример slot:

```text
result = casino slot result with 8 symbols
if casino slot result result all equal:
    give casino payout bet 1 Gold multiplier 10
```

Для weighted loot/casino:

```text
casino weighted random index from weights "60,25,10,4,1"
```

Индекс `0` выпадет чаще всего, индекс `4` — очень редко.

## Важно

- Балансы сохраняются в `world/data/<modid>_economy_system_v1.dat`
- Банк защищён от потери при смерти
- Wallet теряет `death_wallet_loss_percent`
- Переводы используют `transfer_fee_percent`
- Casino payout может учитывать `casino_house_edge_percent`
