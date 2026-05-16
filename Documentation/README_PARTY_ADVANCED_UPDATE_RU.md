# Party Advanced Update

Это обновление добавляет в party-систему четыре крупных вещи:

```text
1. Реальное отключение PvP-урона между участниками пати
2. Invite GUI
3. Server config
4. Party-only chat
5. Дополнительные полезные party_tools blocks
```

---

## 1. Реальное отключение PvP

Раньше `/party pvp false` только сохранял состояние `pvpEnabled`, но не отменял урон.

Теперь добавлен helper:

```text
src/main/resources/neoforge-1.21.1/templates/party_api_pvp_guard.java.ftl
```

Он генерирует:

```text
src/main/java/net/mcreator/<modid>/party/PartyApiPvpGuard.java
```

Логика:

```text
LivingIncomingDamageEvent
    -> если цель ServerPlayer
    -> найти атакующего ServerPlayer
    -> если атакующий и цель в одной пати
    -> если PvP в пати выключен
    -> event.setCanceled(true)
```

Поддерживается обычный melee-урон и projectile-урон, если projectile owner — игрок.

Команды:

```text
/party pvp false
/party pvp true
/party admin pvp <player> false
/party admin pvp <player> true
```

---

## 2. Server-wide party enable/disable

Добавлена возможность отключить party-систему для обычных игроков.

Команды:

```text
/party admin enabled false
/party admin enabled true
```

Когда party-система выключена:

```text
игроки не могут создавать пати
игроки не могут приглашать / принимать приглашения
игроки не могут открывать party GUI
игроки не могут pin/unpin/change position/showself
overlay очищается у online игроков
данные пати НЕ удаляются
админы всё ещё могут смотреть / менять / расформировывать пати
```

---

## 3. Server config

Добавлен helper:

```text
src/main/resources/neoforge-1.21.1/templates/party_api_server_config.java.ftl
```

Он создаёт конфиг:

```text
config/<modid>-party-server.toml
```

Пример файла:

```toml
default_party_system_enabled = true
invite_gui_enabled = true
pvp_protection_enabled = true
party_chat_enabled = true

default_max_members = 4
hard_max_members = 200
admin_permission_level = 2
invite_lifetime_seconds = 120

party_chat_prefix = "!"
```

Перезагрузить конфиг без перезапуска сервера:

```text
/party admin reloadconfig
```

### Параметры

#### `default_party_system_enabled`

Стартовое состояние party-системы при создании новых party data.

```toml
default_party_system_enabled = true
```

#### `invite_gui_enabled`

Включает GUI приглашения.

```toml
invite_gui_enabled = true
```

#### `pvp_protection_enabled`

Включает реальную отмену урона между участниками пати при `/party pvp false`.

```toml
pvp_protection_enabled = true
```

#### `party_chat_enabled`

Включает party-only chat через prefix.

```toml
party_chat_enabled = true
```

#### `default_max_members`

Стандартный лимит участников новой пати.

```toml
default_max_members = 4
```

#### `hard_max_members`

Жёсткий максимум участников пати.

```toml
hard_max_members = 200
```

#### `admin_permission_level`

Уровень прав для `/party admin ...`.

```toml
admin_permission_level = 2
```

#### `invite_lifetime_seconds`

Время жизни invite.

```toml
invite_lifetime_seconds = 120
```

#### `party_chat_prefix`

Префикс party-only chat.

```toml
party_chat_prefix = "!"
```

---

## 4. Invite GUI

Теперь при invite игрок получает GUI с кнопками:

```text
Accept
Decline
```

Команда invite:

```text
/party invite <player>
```

Если `invite_gui_enabled = true`, получатель увидит GUI.

Если GUI выключен, остаётся старый chat fallback:

```text
Party invite from <name>. Use /party accept
```

Клиентский ответ идёт через уже существующий `PartyActionPayload`:

```text
accept_invite
decline_invite
```

---

## 5. Party-only chat

Есть два способа отправить сообщение только участникам пати.

### Через prefix

Если в конфиге:

```toml
party_chat_prefix = "!"
```

то сообщение:

```text
!hello party
```

будет отправлено только online-участникам пати.

Обычный чат без `!` остаётся глобальным.

### Через команду

```text
/party chat <message>
```

Пример:

```text
/party chat Go to extraction point
```

---

## 6. Новые party_tools blocks

Добавлены новые блоки:

```text
are ENTITY and TARGET in same party
is party PvP enabled for ENTITY
set server party system enabled to ENABLED
is server party system enabled
transfer party leadership from ENTITY to TARGET
is ENTITY party leader
send party message MESSAGE to party of ENTITY
admin add TARGET to party of ENTITY ignore limit? IGNORE_LIMIT
admin disband party of ENTITY
```

### are ENTITY and TARGET in same party

Boolean.

Возвращает `true`, если оба игрока в одной пати.

Пример:

```text
if are Event/target entity and Source entity in same party:
    cancel event
```

---

### is party PvP enabled for ENTITY

Boolean.

Возвращает PvP-состояние пати игрока.

Если игрок не в пати, возвращает `true`.

---

### set server party system enabled to ENABLED

Action.

Включает или отключает party-систему для обычных игроков.

Пример:

```text
set server party system enabled to false
```

---

### is server party system enabled

Boolean.

Проверяет, включена ли party-система.

---

### transfer party leadership from ENTITY to TARGET

Action.

Передаёт лидерство от текущего лидера другому участнику пати.

---

### is ENTITY party leader

Boolean.

Проверяет, является ли игрок лидером своей пати.

---

### send party message MESSAGE to party of ENTITY

Action.

Отправляет system message всем online-участникам пати выбранного игрока.

Пример:

```text
send party message "Boss started!" to party of Event/target entity
```

---

### admin add TARGET to party of ENTITY ignore limit? IGNORE_LIMIT

Action.

Добавляет `TARGET` в пати, где находится `ENTITY`.

Если `IGNORE_LIMIT = true`, лимит участников игнорируется.

---

### admin disband party of ENTITY

Action.

Расформировывает пати, в которой находится `ENTITY`.

---

## 7. Новые команды

Обычные:

```text
/party chat <message>
/party transfer <player>
```

Админские:

```text
/party admin enabled <true|false>
/party admin reloadconfig
/party admin transfer <party_member> <new_leader>
```

Уже существующие админские команды остаются:

```text
/party admin info <player>
/party admin gui <player>
/party admin limit <player> <size>
/party admin pvp <player> <true|false>
/party admin add <party_member> <target>
/party admin forceadd <party_member> <target>
/party admin remove <target>
/party admin disband <player>
```

---

## 8. generator.yaml

Добавь новые helper templates:

```yaml
  - template: party_api_server_config.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiServerConfig.java"

  - template: party_api_pvp_guard.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiPvpGuard.java"

  - template: party_api_chat_guard.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiChatGuard.java"
```

И убедись, что эти helper templates уже есть:

```yaml
  - template: party_api_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiSystem.java"

  - template: party_api_commands.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiCommands.java"

  - template: party_api_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/PartyApiNetwork.java"

  - template: party_api_client.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/PartyApiClient.java"
```

---

## 9. Cleanup

После замены templates удали generated-файлы:

```text
src/main/java/net/mcreator/<modid>/party/PartyApiSystem.java
src/main/java/net/mcreator/<modid>/party/PartyApiCommands.java
src/main/java/net/mcreator/<modid>/party/PartyApiServerConfig.java
src/main/java/net/mcreator/<modid>/party/PartyApiPvpGuard.java
src/main/java/net/mcreator/<modid>/party/PartyApiChatGuard.java
src/main/java/net/mcreator/<modid>/network/PartyApiNetwork.java
src/main/java/net/mcreator/<modid>/client/PartyApiClient.java
```

Потом:

```text
Regenerate code
```

Если нужно проверить с чистого состояния:

```text
run/world/data/<modid>_party_api_system_v1.dat
```

можно удалить.
