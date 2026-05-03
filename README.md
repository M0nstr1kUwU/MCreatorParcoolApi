# MCreatorParcoolApi

Набор кастомных блоков для MCreator под ParCool и блоки камеры.

## Категории в MCreator

### ParCool API
- ParCool stamina of %1 — получить текущую стамину сущности.
- add %1 ParCool stamina to %2 — добавить стамину сущности.
- consume %1 ParCool stamina from %2 — потратить стамину сущности.
- ParCool max stamina of %1 — получить максимальную стамину сущности.
- set ParCool max stamina of %1 to %2 — установить максимальную стамину.
- set ParCool stamina of %1 to %2 — установить текущую стамину.
- ParCool stamina percent of %1 (0-100) rounded to %2 decimals — получить процент стамины в диапазоне 0–100 с округлением.
- ParCool stamina recovery attribute of %1 — получить значение атрибута восстановления стамины.
- Set ParCool stamina recovery of %1 to %2 — установить восстановление стамины.
- is ParCool stamina of %1 exhausted — проверить, истощена ли стамина.
- cancel jump motion of %1 — отменить прыжковое движение сущности.
- stop sprinting of %1 — остановить спринт сущности.

### Camera
- ParCool camera mode — получить активный режим камеры: 1 = first person, 2 = third person back, 3 = third person front.
- Cycle ParCool camera mode — переключить режим камеры по кругу.
- Set ParCool camera mode to first person — установить вид от первого лица.
- Set ParCool camera mode to third person back — установить вид от третьего лица сзади.
- Set ParCool camera mode to third person front — установить вид от третьего лица спереди.

## Примечания
- Блоки камеры работают только на клиенте.
- Категория ParCool API использует toolbox id `parcool_api`.
- Категория Camera использует toolbox id `camera`.
