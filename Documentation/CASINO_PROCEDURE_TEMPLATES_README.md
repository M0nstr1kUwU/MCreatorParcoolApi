# Casino Procedure Templates for MCreator

This package contains real MCreator procedure templates:

```text
src/main/resources/procedures/*.json
src/main/resources/neoforge-1.21.1/procedures/*.java.ftl
src/main/resources/neoforge-1.21.1/templates/economy_api_casino_templates.java.ftl
```

These are not pseudo-code markdown examples. They are ready-to-use procedure blocks.

## Add to generator.yaml

```yaml
  - template: economy_api_casino_templates.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/economy/EconomyApiCasinoTemplates.java"
```

## Delete generated file after replacing

```text
src/main/java/net/mcreator/<modid>/economy/EconomyApiCasinoTemplates.java
```

Then run:

```text
Regenerate code
```

## New template blocks

All blocks return Boolean:

```text
casino template coin flip: ENTITY bets AMOUNT COIN on CHOICE send messages SEND_MESSAGES
casino template roulette color: ENTITY bets AMOUNT COIN on COLOR send messages SEND_MESSAGES
casino template roulette straight: ENTITY bets AMOUNT COIN on number NUMBER send messages SEND_MESSAGES
casino template slots: ENTITY bets AMOUNT COIN symbols SYMBOLS jackpot xJACKPOT pair xPAIR miss xMISS send messages SEND_MESSAGES
casino template dice: ENTITY bets AMOUNT COIN on CHOICE dice DICE sides SIDES threshold THRESHOLD win xMULTIPLIER push on equal PUSH_ON_EQUAL send messages SEND_MESSAGES
casino template weighted wheel: ENTITY bets AMOUNT COIN weights WEIGHTS multipliers MULTIPLIERS send messages SEND_MESSAGES
casino template crash: ENTITY bets AMOUNT COIN cashout xCASHOUT max xMAX send messages SEND_MESSAGES
casino template blackjack lite: ENTITY bets AMOUNT COIN send messages SEND_MESSAGES
```

## How these templates work

Every template follows the same server-safe pattern:

```text
1. Check player is ServerPlayer
2. Check economy and casino are enabled
3. Convert AMOUNT + COIN to Cooper units
4. Check bet limits
5. Take bet from wallet
6. Generate result server-side
7. If win, pay to wallet with configured house edge
8. Optionally send result messages
```

## Example: using Coin Flip

Create a procedure on button click / NPC interaction / command:

```text
casino template coin flip:
    ENTITY = Event/target entity
    AMOUNT = 1
    COIN = Gold
    CHOICE = Heads
    SEND_MESSAGES = true
```

If the block returns true, player won. If false, player lost or the bet failed.

## Example: using Weighted Wheel

```text
WEIGHTS = "70,20,8,2"
MULTIPLIERS = "0,1.5,3,10"
```

Meaning:

```text
70% -> lose
20% -> x1.5
8%  -> x3
2%  -> x10
```

Use block:

```text
casino template weighted wheel:
    ENTITY = player
    AMOUNT = 1
    COIN = Gold
    WEIGHTS = "70,20,8,2"
    MULTIPLIERS = "0,1.5,3,10"
    SEND_MESSAGES = true
```

## Recommended balancing

Avoid:

```text
50% chance with x3 payout
```

This prints money.

Better:

```text
Coin flip: x2 payout with house edge
Roulette color: x2 payout with zero
Slots: many losses, small pair payout, rare jackpot
Weighted wheel: most outcomes x0
Crash: player picks risk/reward cashout
```
