# Как пользоваться экономикой и казино

## 1. Валюта

В системе 4 монеты:

```text
100 Cooper = 1 Iron
100 Iron = 1 Gold
1000 Gold = 1 Platine
```

Внутри всё считается в Cooper units. Это как “копейки” в банковской системе: удобно считать без дробей.

Примеры:

```text
1 Iron = 100 Cooper
1 Gold = 10 000 Cooper
1 Platine = 10 000 000 Cooper
```

## 2. Два счёта игрока

У игрока есть:

```text
wallet — личные деньги
bank   — банк
```

При смерти игрок теряет только часть wallet. Bank не трогается.

По умолчанию:

```text
death_wallet_loss_percent = 25
```

## 3. Настройка предметов-монет

Файл:

```text
config/<modid>-economy-server.toml
```

Пример:

```toml
coin_item_cooper="minecraft:copper_ingot"
coin_item_iron="minecraft:iron_ingot"
coin_item_gold="minecraft:gold_ingot"
coin_item_platine="minecraft:netherite_ingot"
```

Эти item id используются блоками:

```text
deposit COIN coin items from ENTITY to bank
withdraw COIN coin items from bank of ENTITY
```

То есть игрок может принести физические предметы-монеты и положить их в банк.

## 4. Команды

Игроки:

```text
/eco balance
/eco wallet
/eco bank
/eco pay <player> <amount> <unit>
/eco bank deposit <amount> <unit>
/eco bank withdraw <amount> <unit>
/eco coins deposit <coin> [items]
/eco coins withdraw <coin> <items>
```

Админы:

```text
/eco admin fee <percent>
/eco admin deathloss <percent>
/eco admin houseedge <percent>
/eco admin betlimits <minCooper> <maxCooper>
/eco admin coinitem <coin> <item_id>
/eco admin casino <true|false>
/eco admin enabled <true|false>
/eco admin reloadconfig
```

## 5. Главный принцип казино

Любая мини-игра должна работать так:

```text
1. Проверить, разрешена ли ставка
2. Забрать ставку
3. Сгенерировать случайный результат на сервере
4. Если игрок выиграл — выдать payout
```

Как автомат:

```text
ставка -> результат -> выплата
```

Нельзя сначала выдавать результат, а потом пытаться забрать ставку: игрок может обойти систему.

## 6. Базовый шаблон казино

```text
if is casino bet AMOUNT COIN allowed:
    if take casino bet AMOUNT COIN from PLAYER:
        RESULT = random/casino logic

        if win:
            PAYOUT = give casino payout to PLAYER bet AMOUNT COIN multiplier MULTIPLIER
            send message "Вы выиграли: " + format money PAYOUT cooper
        else:
            send message "Вы проиграли"
```

`give casino payout` уже применяет house edge из конфига.

## 7. House edge

`casino_house_edge_percent` — преимущество казино.

Пример:

```text
house edge = 5%
payout 100 Cooper превращается примерно в 95 Cooper
```

Это нужно, чтобы казино было реалистичнее и не печатало бесконечные деньги.

## 8. Новые casino blocks

```text
casino random decimal from MIN to MAX
casino roll DICE dice with SIDES sides sum
casino roll DICE dice with SIDES sides as list

casino draw card rank
casino draw card suit
casino card name rank RANK suit SUIT

blackjack value of card rank RANK
blackjack hand value of ranks RANKS
is blackjack hand ranks RANKS bust
should blackjack dealer hit with ranks RANKS

roulette bet type BET_TYPE choice CHOICE wins on number NUMBER
roulette payout multiplier for bet type BET_TYPE

casino slot result RESULT has pair
slot payout multiplier for result RESULT jackpot JACKPOT pair PAIR miss MISS

number from csv CSV at index INDEX fallback FALLBACK
text from csv CSV at index INDEX fallback FALLBACK
weighted multiplier weights WEIGHTS multipliers MULTIPLIERS fallback FALLBACK

casino crash generated multiplier max MAX
crash generated GENERATED cashout CASHOUT wins
```

## 9. CSV — простой способ хранить таблицы

CSV — это строка через запятую:

```text
"70,20,8,2"
```

Для weighted wheel:

```text
WEIGHTS = "70,20,8,2"
MULTIPLIERS = "0,1.5,3,10"
```

Это значит:

```text
70% -> проигрыш
20% -> 1.5x
8%  -> 3x
2%  -> 10x
```

Блок:

```text
weighted multiplier weights WEIGHTS multipliers MULTIPLIERS fallback 0
```

сам выберет результат.

## 10. Реалистичность мини-игр

Хорошее казино — это не просто random 50/50. У каждой игры должен быть:

```text
ставка
шанс
множитель
house edge
лимиты ставки
серверная генерация результата
```

Пример плохого дизайна:

```text
50% шанс выиграть x3
```

Это ломает экономику, потому что средняя выплата слишком высокая.

Пример нормального дизайна:

```text
50% шанс выиграть x1.9
```

или:

```text
слоты:
пара = x1.5
джекпот = x10
много проигрышей
```

## 11. Готовые шаблоны

В архиве есть папка:

```text
docs/procedure_templates/
```

Там заготовки:

```text
01_coin_flip.md
02_roulette_color.md
03_slots.md
04_dice_over_under.md
05_blackjack_lite.md
06_crash.md
07_weighted_wheel.md
```
