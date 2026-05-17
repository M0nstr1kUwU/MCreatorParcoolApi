# Party System Integration Patch

This pack intentionally keeps full integration points in this patch file so you can merge them into your current `party_api_system.java.ftl`, `party_api_network.java.ftl`, and `party_api_client.java.ftl` without losing your local work.

## Required PartyApiSystem methods

Add or replace these methods in `PartyApiSystem`:

```java
public static boolean setShowSelf(ServerPlayer viewer, boolean showSelf) {
    if (viewer == null || !isPartySystemEnabled()) return false;
    PartySavedData data = getSavedData();
    PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;
    if (party == null) return false;
    party.showSelfByViewer.put(viewer.getUUID(), showSelf);
    data.setDirty();
    syncPartyTo(viewer, party);
    return true;
}

public static boolean getShowSelf(ServerPlayer viewer) {
    PartySavedData data = getSavedData();
    PartyData party = viewer != null && data != null ? data.getPartyOf(viewer.getUUID()) : null;
    if (party == null) return PartyApiServerConfig.get().defaultShowSelf;
    return party.showSelfByViewer.getOrDefault(viewer.getUUID(), party.defaultShowSelf);
}

public static boolean setOverlayPosition(ServerPlayer viewer, int x, int y) {
    if (viewer == null || !isPartySystemEnabled()) return false;
    PartySavedData data = getSavedData();
    PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;
    if (party == null) return false;
    party.overlayXByViewer.put(viewer.getUUID(), x);
    party.overlayYByViewer.put(viewer.getUUID(), y);
    data.setDirty();
    syncPartyTo(viewer, party);
    return true;
}

public static boolean resetOverlayPosition(ServerPlayer viewer) {
    return setOverlayPosition(viewer, PartyApiServerConfig.get().defaultOverlayX, PartyApiServerConfig.get().defaultOverlayY);
}

public static boolean setOverlayElementPosition(ServerPlayer viewer, String elementId, int x, int y) {
    if (viewer == null || elementId == null || elementId.isBlank()) return false;
    PartySavedData data = getSavedData();
    PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;
    if (party == null) return false;
    Map<String, ElementLayout> layouts = party.elementLayoutsByViewer.computeIfAbsent(viewer.getUUID(), id -> new java.util.concurrent.ConcurrentHashMap<>());
    layouts.put(elementId.trim(), new ElementLayout(x, y));
    data.setDirty();
    syncPartyTo(viewer, party);
    return true;
}

public static boolean addOverlayValueEntry(ServerPlayer viewer, String id, String label, String value, int x, int y, int width, int height, String texture) {
    return addOverlayEntry(viewer, id, "VALUE", label, value, "", x, y, width, height, texture);
}

public static boolean addOverlayBarEntry(ServerPlayer viewer, String id, String label, double current, double max, int x, int y, int width, int height, String texture) {
    return addOverlayEntry(viewer, id, "BAR", label, String.valueOf(current), String.valueOf(max), x, y, width, height, texture);
}

private static boolean addOverlayEntry(ServerPlayer viewer, String id, String kind, String label, String value, String max, int x, int y, int width, int height, String texture) {
    if (viewer == null || id == null || id.isBlank()) return false;
    PartySavedData data = getSavedData();
    PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;
    if (party == null) return false;
    Map<String, CustomOverlayEntry> entries = party.customEntriesByViewer.computeIfAbsent(viewer.getUUID(), v -> new java.util.concurrent.ConcurrentHashMap<>());
    entries.put(id.trim(), new CustomOverlayEntry(id.trim(), kind, label == null ? "" : label, value == null ? "" : value, max == null ? "" : max, x, y, Math.max(1, width), Math.max(1, height), texture == null ? "" : texture));
    data.setDirty();
    syncPartyTo(viewer, party);
    return true;
}

public static boolean clearOverlayCustomEntries(ServerPlayer viewer) {
    PartySavedData data = getSavedData();
    PartyData party = viewer != null && data != null ? data.getPartyOf(viewer.getUUID()) : null;
    if (party == null) return false;
    party.customEntriesByViewer.remove(viewer.getUUID());
    data.setDirty();
    syncPartyTo(viewer, party);
    return true;
}

private record ElementLayout(int x, int y) {}
private record CustomOverlayEntry(String id, String kind, String label, String value, String max, int x, int y, int width, int height, String texture) {}
```

## Required fields inside PartyData

```java
private boolean defaultShowSelf = PartyApiServerConfig.get().defaultShowSelf;
private final Map<UUID, Boolean> showSelfByViewer = new java.util.concurrent.ConcurrentHashMap<>();
private final Map<UUID, Integer> overlayXByViewer = new java.util.concurrent.ConcurrentHashMap<>();
private final Map<UUID, Integer> overlayYByViewer = new java.util.concurrent.ConcurrentHashMap<>();
private final Map<UUID, Map<String, ElementLayout>> elementLayoutsByViewer = new java.util.concurrent.ConcurrentHashMap<>();
private final Map<UUID, Map<String, CustomOverlayEntry>> customEntriesByViewer = new java.util.concurrent.ConcurrentHashMap<>();
```

## Invite cooldown logic

Before adding an invite, check if the same target already has pending invite from the same party. Do not replace it. Add `revokeInvite(actor, invited)` and `declineInvite(player)` methods.

## GUI requirements

- Invite GUI requests a synced online player list from server.
- Rows contain Invite / Revoke buttons.
- Main party GUI contains Kick button next to members.
- Settings GUI contains ShowSelf toggle and X/Y position controls.
- Admin GUI button is shown only when `player.hasPermissions(PartyApiServerConfig.get().adminPermissionLevel)` is synced as true.
