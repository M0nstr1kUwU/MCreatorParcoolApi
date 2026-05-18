package ${package}.party;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.saveddata.SavedData;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.ModList;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.tick.PlayerTickEvent;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiSystem {
	private static final String DATA_NAME = "${modid}_party_api_system_v1";
	private static final int MAX_OVERLAY_PINNED = 4;
	private static final Map<UUID, InviteData> INVITES = new ConcurrentHashMap<>();
	private static final Map<String, Long> INVITE_COOLDOWNS = new ConcurrentHashMap<>();

	private PartyApiSystem() {
	}

	public static boolean isPartySystemEnabled() {
		return PartyApiServerConfig.partyEnabled();
	}

	public static boolean adminSetPartySystemEnabled(boolean enabled) {
		boolean ok = PartyApiServerConfig.setPartyEnabled(enabled);

		if (!enabled) {
			clearAllOnlinePartyScreens();
		} else {
			syncAllOnlineParties();
		}

		return ok;
	}

	public static boolean createParty(ServerPlayer leader) {
		return createParty(leader, PartyApiServerConfig.defaultShowSelf());
	}

	public static boolean createParty(ServerPlayer leader, boolean showSelf) {
		if (leader == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null || data.getPartyOf(leader.getUUID()) != null) {
			return false;
		}

		PartyData party = new PartyData(UUID.randomUUID(), leader.getUUID());
		party.members.add(leader.getUUID());
		party.defaultShowSelf = showSelf;
		party.maxMembers = PartyApiServerConfig.defaultMaxMembers();
		party.showSelfByViewer.put(leader.getUUID(), showSelf);
		party.overlayPositionByViewer.put(leader.getUUID(), "CUSTOM");
		party.overlayXByViewer.put(leader.getUUID(), PartyApiServerConfig.defaultOverlayX());
		party.overlayYByViewer.put(leader.getUUID(), PartyApiServerConfig.defaultOverlayY());

		data.parties.put(party.id, party);
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static boolean disbandParty(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		if (party == null || !party.leader.equals(player.getUUID())) {
			return false;
		}

		return disbandPartyInternal(data, party);
	}

	public static boolean adminDisbandPartyOf(ServerPlayer targetPartyMember) {
		if (targetPartyMember == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(targetPartyMember.getUUID());
		return party != null && disbandPartyInternal(data, party);
	}

	private static boolean disbandPartyInternal(PartySavedData data, PartyData party) {
		List<UUID> members = new ArrayList<>(party.members);
		data.parties.remove(party.id);
		data.setDirty();

		for (UUID memberId : members) {
			ServerPlayer member = getServerPlayer(memberId);

			if (member != null) {
				${package}.network.PartyApiNetwork.sendEmptyParty(member);
			}
		}

		return true;
	}

	public static boolean invitePlayer(ServerPlayer leader, ServerPlayer invited) {
		if (leader == null || invited == null || leader.getUUID().equals(invited.getUUID()) || !isPartySystemEnabled()) {
			return false;
		}

		clearExpiredInvites();
		clearExpiredInviteCooldowns();

		long remainingCooldown = getInviteCooldownSecondsRemaining(leader, invited);
		if (remainingCooldown > 0L) {
			leader.displayClientMessage(Component.literal("Invite cooldown: wait " + remainingCooldown + "s before inviting this player again."), false);
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(leader.getUUID());

		if (party == null) {
			createParty(leader, PartyApiServerConfig.defaultShowSelf());
			party = data.getPartyOf(leader.getUUID());
		}

		if (party == null || !party.leader.equals(leader.getUUID())) {
			return false;
		}

		if (data.getPartyOf(invited.getUUID()) != null) {
			leader.displayClientMessage(Component.literal("Player is already in a party."), false);
			return false;
		}

		if (isFull(party)) {
			leader.displayClientMessage(Component.literal("Party is full (" + party.members.size() + "/" + party.maxMembers + ")"), false);
			return false;
		}

		InviteData current = INVITES.get(invited.getUUID());

		if (current != null && current.partyId.equals(party.id) && !current.isExpired()) {
			leader.displayClientMessage(Component.literal("Invite is already pending. Revoke it first or wait until it expires."), false);
			return false;
		}

		INVITE_COOLDOWNS.put(inviteCooldownKey(leader.getUUID(), invited.getUUID()), System.currentTimeMillis());
		INVITES.put(invited.getUUID(), new InviteData(party.id, leader.getUUID(), invited.getUUID(), System.currentTimeMillis()));

		invited.displayClientMessage(Component.literal("Party invite from " + leader.getGameProfile().getName() + ". Use /party accept"), false);

		if (PartyApiServerConfig.inviteGuiEnabled()) {
			${package}.network.PartyApiNetwork.openPartyInviteScreen(invited, leader.getGameProfile().getName());
		}

		syncParty(party);
		return true;
	}

	public static boolean revokeInvite(ServerPlayer actor, ServerPlayer invited) {
		if (actor == null || invited == null) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(actor.getUUID()) : null;

		if (party == null || !party.leader.equals(actor.getUUID())) {
			return false;
		}

		InviteData invite = INVITES.get(invited.getUUID());

		if (invite == null || !invite.partyId.equals(party.id)) {
			return false;
		}

		INVITES.remove(invited.getUUID());
		actor.displayClientMessage(Component.literal("Invite revoked for " + invited.getGameProfile().getName()), false);
		invited.displayClientMessage(Component.literal("Party invite was revoked."), false);

		syncParty(party);
		return true;
	}

	public static boolean acceptInvite(ServerPlayer player) {
		if (player == null || !isPartySystemEnabled()) {
			return false;
		}

		clearExpiredInvites();

		PartySavedData data = getSavedData();

		if (data == null || data.getPartyOf(player.getUUID()) != null) {
			return false;
		}

		InviteData invite = INVITES.remove(player.getUUID());

		if (invite == null || invite.isExpired()) {
			return false;
		}

		PartyData party = data.parties.get(invite.partyId);

		if (party == null || isFull(party)) {
			return false;
		}

		party.members.add(player.getUUID());
		party.showSelfByViewer.putIfAbsent(player.getUUID(), party.defaultShowSelf);
		party.overlayPositionByViewer.putIfAbsent(player.getUUID(), "CUSTOM");
		party.overlayXByViewer.putIfAbsent(player.getUUID(), PartyApiServerConfig.defaultOverlayX());
		party.overlayYByViewer.putIfAbsent(player.getUUID(), PartyApiServerConfig.defaultOverlayY());

		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean declineInvite(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		return INVITES.remove(player.getUUID()) != null;
	}

	public static boolean leaveParty(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		if (party == null) {
			return false;
		}

		removeMemberInternal(party, player.getUUID());

		if (party.members.isEmpty()) {
			data.parties.remove(party.id);
		} else if (party.leader.equals(player.getUUID())) {
			party.leader = party.members.iterator().next();
		}

		data.setDirty();
		${package}.network.PartyApiNetwork.sendEmptyParty(player);
		syncParty(party);
		return true;
	}

	public static boolean kickPlayer(ServerPlayer actor, ServerPlayer target) {
		if (actor == null || target == null || actor.getUUID().equals(target.getUUID()) || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(actor.getUUID());

		if (party == null || !party.leader.equals(actor.getUUID()) || !party.members.contains(target.getUUID())) {
			return false;
		}

		removeMemberInternal(party, target.getUUID());

		if (party.members.isEmpty()) {
			data.parties.remove(party.id);
		} else if (party.leader.equals(target.getUUID())) {
			party.leader = party.members.iterator().next();
		}

		data.setDirty();
		${package}.network.PartyApiNetwork.sendEmptyParty(target);
		target.displayClientMessage(Component.literal("You were kicked from party."), false);
		syncParty(party);
		return true;
	}

	public static boolean adminRemovePlayerFromParty(ServerPlayer target) {
		if (target == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(target.getUUID());

		if (party == null) {
			return false;
		}

		removeMemberInternal(party, target.getUUID());

		if (party.members.isEmpty()) {
			data.parties.remove(party.id);
		} else if (party.leader.equals(target.getUUID())) {
			party.leader = party.members.iterator().next();
		}

		data.setDirty();
		${package}.network.PartyApiNetwork.sendEmptyParty(target);
		syncParty(party);
		return true;
	}

	private static void removeMemberInternal(PartyData party, UUID playerId) {
		if (party == null || playerId == null) {
			return;
		}

		party.members.remove(playerId);
		party.pinsByViewer.remove(playerId);
		party.overlayPositionByViewer.remove(playerId);
		party.overlayXByViewer.remove(playerId);
		party.overlayYByViewer.remove(playerId);
		party.showSelfByViewer.remove(playerId);
		party.overlayElementPositionsByViewer.remove(playerId);
		party.customOverlayEntriesByViewer.remove(playerId);

		for (LinkedHashSet<UUID> pins : party.pinsByViewer.values()) {
			pins.remove(playerId);
		}
	}

	public static boolean setPvp(ServerPlayer actor, boolean enabled) {
		PartyData party = getLeaderParty(actor);
		PartySavedData data = getSavedData();

		if (party == null || data == null) {
			return false;
		}

		party.pvpEnabled = enabled;
		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean adminSetPvp(ServerPlayer targetPartyMember, boolean enabled) {
		PartySavedData data = getSavedData();
		PartyData party = targetPartyMember != null && data != null ? data.getPartyOf(targetPartyMember.getUUID()) : null;

		if (party == null) {
			return false;
		}

		party.pvpEnabled = enabled;
		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean setPartyMaxMembers(ServerPlayer actor, int maxMembers) {
		PartyData party = getLeaderParty(actor);
		PartySavedData data = getSavedData();

		if (party == null || data == null) {
			return false;
		}

		party.maxMembers = clampMaxMembers(maxMembers);
		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean adminSetPartyMaxMembers(ServerPlayer targetPartyMember, int maxMembers) {
		PartySavedData data = getSavedData();
		PartyData party = targetPartyMember != null && data != null ? data.getPartyOf(targetPartyMember.getUUID()) : null;

		if (party == null) {
			return false;
		}

		party.maxMembers = clampMaxMembers(maxMembers);
		data.setDirty();
		syncParty(party);
		return true;
	}

	public static int getPartyMaxMembers(ServerPlayer player) {
		PartySavedData data = getSavedData();
		PartyData party = player != null && data != null ? data.getPartyOf(player.getUUID()) : null;
		return party != null ? party.maxMembers : 0;
	}

	public static boolean isPartyFull(ServerPlayer player) {
		PartySavedData data = getSavedData();
		PartyData party = player != null && data != null ? data.getPartyOf(player.getUUID()) : null;
		return party != null && isFull(party);
	}

	public static boolean adminAddPlayerToParty(ServerPlayer targetPartyMember, ServerPlayer playerToAdd, boolean ignoreLimit) {
		if (targetPartyMember == null || playerToAdd == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null || data.getPartyOf(playerToAdd.getUUID()) != null) {
			return false;
		}

		PartyData party = data.getPartyOf(targetPartyMember.getUUID());

		if (party == null) {
			return false;
		}

		if (!ignoreLimit && isFull(party)) {
			return false;
		}

		party.members.add(playerToAdd.getUUID());
		party.showSelfByViewer.putIfAbsent(playerToAdd.getUUID(), party.defaultShowSelf);
		party.overlayPositionByViewer.putIfAbsent(playerToAdd.getUUID(), "CUSTOM");
		party.overlayXByViewer.putIfAbsent(playerToAdd.getUUID(), PartyApiServerConfig.defaultOverlayX());
		party.overlayYByViewer.putIfAbsent(playerToAdd.getUUID(), PartyApiServerConfig.defaultOverlayY());

		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean setPinned(ServerPlayer viewer, ServerPlayer target, boolean pinned) {
		if (viewer == null || target == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (party == null || !party.members.contains(target.getUUID())) {
			return false;
		}

		LinkedHashSet<UUID> pins = party.pinsByViewer.computeIfAbsent(viewer.getUUID(), id -> new LinkedHashSet<>());

		if (pinned) {
			if (!pins.contains(target.getUUID()) && pins.size() >= MAX_OVERLAY_PINNED) {
				return false;
			}

			pins.add(target.getUUID());
		} else {
			pins.remove(target.getUUID());
		}

		data.setDirty();
		syncPartyTo(viewer, party);
		return true;
	}

	public static boolean setShowSelf(ServerPlayer viewer, boolean showSelf) {
		if (viewer == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (party == null) {
			return false;
		}

		party.showSelfByViewer.put(viewer.getUUID(), showSelf);
		data.setDirty();
		syncPartyTo(viewer, party);
		return true;
	}

	public static boolean getShowSelf(ServerPlayer viewer) {
		PartySavedData data = getSavedData();
		PartyData party = viewer != null && data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (viewer == null || party == null) {
			return PartyApiServerConfig.defaultShowSelf();
		}

		return party.showSelfByViewer.getOrDefault(viewer.getUUID(), party.defaultShowSelf);
	}

	public static boolean setOverlayPosition(ServerPlayer player, String position) {
		if (player == null || position == null) {
			return false;
		}

		switch (normalizePosition(position)) {
			case "LEFT_TOP" -> {
				return setOverlayPosition(player, 8, 22);
			}
			case "LEFT_BOTTOM" -> {
				return setOverlayPosition(player, 8, 180);
			}
			case "RIGHT_TOP" -> {
				return setOverlayPosition(player, 240, 22);
			}
			case "RIGHT_CENTER" -> {
				return setOverlayPosition(player, 240, 100);
			}
			case "RIGHT_BOTTOM" -> {
				return setOverlayPosition(player, 240, 180);
			}
			default -> {
				return setOverlayPosition(player, PartyApiServerConfig.defaultOverlayX(), PartyApiServerConfig.defaultOverlayY());
			}
		}
	}

	public static boolean setOverlayPosition(ServerPlayer player, int x, int y) {
		if (player == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(player.getUUID()) : null;

		if (party == null) {
			return false;
		}

		party.overlayXByViewer.put(player.getUUID(), x);
		party.overlayYByViewer.put(player.getUUID(), y);
		party.overlayPositionByViewer.put(player.getUUID(), "CUSTOM");
		data.setDirty();
		syncPartyTo(player, party);
		return true;
	}

	public static boolean resetOverlayPosition(ServerPlayer player) {
		return setOverlayPosition(player, PartyApiServerConfig.defaultOverlayX(), PartyApiServerConfig.defaultOverlayY());
	}

	public static boolean initializeOverlayLayout(ServerPlayer viewer, boolean showSelf, int x, int y) {
		if (viewer == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (party == null) {
			return false;
		}

		party.showSelfByViewer.put(viewer.getUUID(), showSelf);
		party.overlayXByViewer.put(viewer.getUUID(), x);
		party.overlayYByViewer.put(viewer.getUUID(), y);
		party.overlayPositionByViewer.put(viewer.getUUID(), "CUSTOM");
		party.overlayElementPositionsByViewer.computeIfAbsent(viewer.getUUID(), key -> new ConcurrentHashMap<>());
		party.customOverlayEntriesByViewer.computeIfAbsent(viewer.getUUID(), key -> new ConcurrentHashMap<>());

		data.setDirty();
		syncPartyTo(viewer, party);
		return true;
	}

	public static boolean setOverlayElementPosition(ServerPlayer viewer, String elementId, int x, int y) {
		if (viewer == null || elementId == null || elementId.isBlank()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (party == null) {
			return false;
		}

		Map<String, OverlayElementPosition> positions = party.overlayElementPositionsByViewer.computeIfAbsent(viewer.getUUID(), id -> new ConcurrentHashMap<>());
		positions.put(elementId.trim(), new OverlayElementPosition(x, y));
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

	private static boolean addOverlayEntry(ServerPlayer viewer, String id, String type, String label, String value, String max, int x, int y, int width, int height, String texture) {
		if (viewer == null || id == null || id.isBlank()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (party == null) {
			return false;
		}

		Map<String, CustomOverlayEntry> entries = party.customOverlayEntriesByViewer.computeIfAbsent(viewer.getUUID(), key -> new ConcurrentHashMap<>());
		entries.put(id.trim(), new CustomOverlayEntry(id.trim(), type, label == null ? "" : label, value == null ? "" : value, max == null ? "" : max, x, y, Math.max(1, width), Math.max(1, height), texture == null ? "" : texture));
		data.setDirty();
		syncPartyTo(viewer, party);
		return true;
	}

	public static boolean clearOverlayCustomEntries(ServerPlayer viewer) {
		PartySavedData data = getSavedData();
		PartyData party = viewer != null && data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (party == null) {
			return false;
		}

		party.customOverlayEntriesByViewer.remove(viewer.getUUID());
		data.setDirty();
		syncPartyTo(viewer, party);
		return true;
	}

	public static boolean setPlayerStat(ServerPlayer player, String key, String value) {
		if (player == null || key == null || key.isBlank()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		Map<String, String> stats = data.extraStatsByPlayer.computeIfAbsent(player.getUUID(), id -> new LinkedHashMap<>());
		stats.put(key.trim(), value == null ? "" : value);
		data.setDirty();

		PartyData party = data.getPartyOf(player.getUUID());

		if (party != null && isPartySystemEnabled()) {
			syncParty(party);
		}

		return true;
	}

	public static boolean clearPlayerStat(ServerPlayer player, String key) {
		if (player == null || key == null || key.isBlank()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		Map<String, String> stats = data.extraStatsByPlayer.get(player.getUUID());

		if (stats != null) {
			stats.remove(key.trim());
			data.setDirty();
		}

		PartyData party = data.getPartyOf(player.getUUID());

		if (party != null && isPartySystemEnabled()) {
			syncParty(party);
		}

		return true;
	}

	public static boolean setLevelDisplayRequiredModId(String modId) {
		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		data.levelDisplayRequiredModId = normalizeModId(modId);
		data.setDirty();
		syncAllOnlineParties();
		return true;
	}

	public static String getLevelDisplayRequiredModId() {
		PartySavedData data = getSavedData();
		return data == null ? "" : normalizeModId(data.levelDisplayRequiredModId);
	}

	public static boolean isLevelDisplayEnabled() {
		String modId = getLevelDisplayRequiredModId();

		if (modId.isBlank()) {
			return false;
		}

		try {
			return ModList.get().isLoaded(modId);
		} catch (Throwable ignored) {
			return false;
		}
	}

	public static String roundNoDecimals(double value) {
		if (Double.isNaN(value) || Double.isInfinite(value)) {
			return "0";
		}

		return String.valueOf(Math.round(value));
	}

	public static boolean setPlayerLevelStatRounded(ServerPlayer player, double value) {
		return setPlayerStat(player, "LVL", roundNoDecimals(value));
	}

	private static String normalizeModId(String modId) {
		return modId == null ? "" : modId.trim().toLowerCase(java.util.Locale.ROOT);
	}

	private static String formatLevelText(String raw) {
		if (raw == null || raw.isBlank()) {
			return "";
		}

		try {
			return roundNoDecimals(Double.parseDouble(raw.trim().replace(',', '.')));
		} catch (Throwable ignored) {
			return raw.trim();
		}
	}

	private static String getLevelTextForPlayer(PartySavedData data, UUID playerId) {
		if (data == null || playerId == null || !isLevelDisplayEnabled()) {
			return "";
		}

		Map<String, String> stats = data.extraStatsByPlayer.get(playerId);

		if (stats == null || stats.isEmpty()) {
			return "";
		}

		String raw = stats.getOrDefault("LVL", stats.getOrDefault("lvl", ""));
		return formatLevelText(raw);
	}

	private static Map<String, String> filterStatsForDisplay(Map<String, String> rawStats) {
		if (rawStats == null || rawStats.isEmpty()) {
			return Map.of();
		}

		Map<String, String> result = new LinkedHashMap<>(rawStats);

		if (!isLevelDisplayEnabled()) {
			result.remove("LVL");
			result.remove("lvl");
			return result;
		}

		String level = formatLevelText(result.getOrDefault("LVL", result.getOrDefault("lvl", "")));
		result.remove("lvl");

		if (!level.isBlank()) {
			result.put("LVL", level);
		}

		return result;
	}

	public static boolean isInParty(ServerPlayer player) {
		PartySavedData data = getSavedData();
		return player != null && data != null && data.getPartyOf(player.getUUID()) != null;
	}

	public static boolean areInSameParty(ServerPlayer first, ServerPlayer second) {
		if (first == null || second == null) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(first.getUUID()) : null;
		return party != null && party.members.contains(second.getUUID());
	}

	public static boolean isPartyPvpEnabled(ServerPlayer player) {
		PartySavedData data = getSavedData();
		PartyData party = player != null && data != null ? data.getPartyOf(player.getUUID()) : null;
		return party == null || party.pvpEnabled;
	}

	public static boolean shouldCancelPvpDamage(ServerPlayer attacker, ServerPlayer target) {
		return attacker != null && target != null && !attacker.getUUID().equals(target.getUUID()) && isPartySystemEnabled() && areInSameParty(attacker, target) && !isPartyPvpEnabled(attacker);
	}

	public static int getPartySize(ServerPlayer player) {
		PartySavedData data = getSavedData();
		PartyData party = player != null && data != null ? data.getPartyOf(player.getUUID()) : null;
		return party != null ? party.members.size() : 0;
	}

	public static int getOnlinePartySize(ServerPlayer player) {
		PartySavedData data = getSavedData();
		PartyData party = player != null && data != null ? data.getPartyOf(player.getUUID()) : null;

		if (party == null) {
			return 0;
		}

		int count = 0;

		for (UUID memberId : party.members) {
			if (getServerPlayer(memberId) != null) {
				count++;
			}
		}

		return count;
	}

	public static boolean isPartyLeader(ServerPlayer player) {
		PartySavedData data = getSavedData();
		PartyData party = player != null && data != null ? data.getPartyOf(player.getUUID()) : null;
		return party != null && party.leader.equals(player.getUUID());
	}

	public static boolean transferLeadership(ServerPlayer actor, ServerPlayer target) {
		PartyData party = getLeaderParty(actor);
		PartySavedData data = getSavedData();

		if (party == null || data == null || target == null || !party.members.contains(target.getUUID())) {
			return false;
		}

		party.leader = target.getUUID();
		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean adminTransferLeadership(ServerPlayer targetPartyMember, ServerPlayer newLeader) {
		PartySavedData data = getSavedData();
		PartyData party = targetPartyMember != null && data != null ? data.getPartyOf(targetPartyMember.getUUID()) : null;

		if (party == null || newLeader == null || !party.members.contains(newLeader.getUUID())) {
			return false;
		}

		party.leader = newLeader.getUUID();
		data.setDirty();
		syncParty(party);
		return true;
	}

	public static boolean sendPartyChat(ServerPlayer sender, String message) {
		if (sender == null || message == null || message.isBlank() || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(sender.getUUID()) : null;

		if (party == null) {
			return false;
		}

		Component component = Component.literal("[Party] <" + sender.getGameProfile().getName() + "> " + message);

		for (UUID memberId : party.members) {
			ServerPlayer member = getServerPlayer(memberId);

			if (member != null) {
				member.sendSystemMessage(component);
			}
		}

		return true;
	}

	public static boolean sendPartyChatStyled(ServerPlayer sender, Component message) {
		return sendPartyChat(sender, message == null ? "" : message.getString());
	}

	public static boolean sendMessageToParty(ServerPlayer anchor, String message) {
		if (anchor == null || message == null || message.isBlank() || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(anchor.getUUID()) : null;

		if (party == null) {
			return false;
		}

		Component component = Component.literal(message);

		for (UUID memberId : party.members) {
			ServerPlayer member = getServerPlayer(memberId);

			if (member != null) {
				member.sendSystemMessage(component);
			}
		}

		return true;
	}

	public static void openPartyGui(ServerPlayer player) {
		openPartyMainGui(player);
	}

	public static void openPartyMainGui(ServerPlayer player) {
		if (player == null || !isPartySystemEnabled()) {
			return;
		}

		syncPartyTo(player);
		${package}.network.PartyApiNetwork.openPartyScreen(player, "MAIN");
	}

	public static void openInviteGui(ServerPlayer player) {
		if (player == null || !isPartySystemEnabled()) {
			return;
		}

		${package}.network.PartyApiNetwork.sendOnlinePlayerList(player, buildOnlinePlayerList(player, false));
		${package}.network.PartyApiNetwork.openPartyScreen(player, "INVITE");
	}

	public static void openSettingsGui(ServerPlayer player) {
		if (player == null || !isPartySystemEnabled()) {
			return;
		}

		syncPartyTo(player);
		${package}.network.PartyApiNetwork.openPartyScreen(player, "SETTINGS");
	}

	public static void openAdminGui(ServerPlayer player) {
		if (player == null || !player.hasPermissions(PartyApiServerConfig.adminPermissionLevel())) {
			return;
		}

		syncPartyTo(player);
		${package}.network.PartyApiNetwork.sendOnlinePlayerList(player, buildOnlinePlayerList(player, true));
		${package}.network.PartyApiNetwork.openPartyScreen(player, "ADMIN");
	}

	public static void openPartyGuiForPartyOf(ServerPlayer viewer, ServerPlayer targetPartyMember) {
		if (viewer == null || targetPartyMember == null) {
			return;
		}

		PartySavedData data = getSavedData();
		PartyData party = data != null ? data.getPartyOf(targetPartyMember.getUUID()) : null;

		if (party != null) {
			// Admin View must show the full party roster, even if the viewer is also a member
			// and their personal showSelf option is disabled.
			syncPartyTo(viewer, party, true);
		}

		${package}.network.PartyApiNetwork.openPartyScreen(viewer, "MAIN");
	}

	public static void handleClientAction(ServerPlayer player, String action, String targetId, String value) {
		if (player == null || action == null) {
			return;
		}

		boolean adminAction = action.startsWith("admin_");

		if (!isPartySystemEnabled() && !adminAction) {
			return;
		}

		if (adminAction && !player.hasPermissions(PartyApiServerConfig.adminPermissionLevel())) {
			return;
		}

		ServerPlayer target = parsePlayer(targetId);

		switch (action) {
			case "pin" -> {
				if (target != null) {
					setPinned(player, target, true);
				}
			}
			case "unpin" -> {
				if (target != null) {
					setPinned(player, target, false);
				}
			}
			case "invite" -> {
				if (target != null) {
					invitePlayer(player, target);
				}
			}
			case "revoke_invite" -> {
				if (target != null) {
					revokeInvite(player, target);
				}
			}
			case "kick" -> {
				if (target != null) {
					kickPlayer(player, target);
				}
			}
			case "position" -> setOverlayPosition(player, value);
			case "position_xy" -> {
				int[] xy = parseXY(value);
				setOverlayPosition(player, xy[0], xy[1]);
			}
			case "show_self_on" -> setShowSelf(player, true);
			case "show_self_off" -> setShowSelf(player, false);
			case "pvp_on" -> setPvp(player, true);
			case "pvp_off" -> setPvp(player, false);
			case "accept_invite" -> acceptInvite(player);
			case "decline_invite" -> declineInvite(player);
			case "create_party" -> {
				createParty(player, PartyApiServerConfig.defaultShowSelf());
				openPartyMainGui(player);
			}
			case "leave_party" -> {
				leaveParty(player);
				openPartyMainGui(player);
			}
			case "disband_party" -> {
				disbandParty(player);
				openPartyMainGui(player);
			}
			case "open_main" -> openPartyMainGui(player);
			case "open_invite" -> openInviteGui(player);
			case "open_settings" -> openSettingsGui(player);
			case "open_admin" -> openAdminGui(player);

			case "admin_enable" -> {
				adminSetPartySystemEnabled(true);
				openAdminGui(player);
			}
			case "admin_disable" -> {
				adminSetPartySystemEnabled(false);
				openAdminGui(player);
			}
			case "admin_refresh" -> openAdminGui(player);
			case "admin_view" -> {
				if (target != null) {
					openPartyGuiForPartyOf(player, target);
				}
			}
			case "admin_remove" -> {
				if (target != null) {
					adminRemovePlayerFromParty(target);
					openAdminGui(player);
				}
			}
			case "admin_disband" -> {
				if (target != null) {
					adminDisbandPartyOf(target);
					openAdminGui(player);
				}
			}
			case "admin_pvp_on" -> {
				if (target != null) {
					adminSetPvp(target, true);
					openAdminGui(player);
				}
			}
			case "admin_pvp_off" -> {
				if (target != null) {
					adminSetPvp(target, false);
					openAdminGui(player);
				}
			}
			case "admin_limit_4" -> {
				if (target != null) {
					adminSetPartyMaxMembers(target, 4);
					openAdminGui(player);
				}
			}
			case "admin_limit_8" -> {
				if (target != null) {
					adminSetPartyMaxMembers(target, 8);
					openAdminGui(player);
				}
			}
			case "admin_limit_16" -> {
				if (target != null) {
					adminSetPartyMaxMembers(target, 16);
					openAdminGui(player);
				}
			}
			case "admin_limit_custom" -> {
				if (target != null) {
					adminSetPartyMaxMembers(target, parseInt(value, PartyApiServerConfig.defaultMaxMembers()));
					openAdminGui(player);
				}
			}
			default -> {
			}
		}
	}

	@SubscribeEvent
	public static void onPlayerTick(PlayerTickEvent.Post event) {
		if (!(event.getEntity() instanceof ServerPlayer player)) {
			return;
		}

		if (player.tickCount % 20 != 0) {
			return;
		}

		syncPartyTo(player);
	}

	private static void syncPartyTo(ServerPlayer viewer) {
		PartySavedData data = getSavedData();
		PartyData party = viewer != null && data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (viewer == null) {
			return;
		}

		if (party == null || !isPartySystemEnabled()) {
			${package}.network.PartyApiNetwork.sendEmptyParty(viewer);
			return;
		}

		syncPartyTo(viewer, party);
	}

	private static void syncParty(PartyData party) {
		if (party == null || !isPartySystemEnabled()) {
			return;
		}

		for (UUID memberId : party.members) {
			ServerPlayer member = getServerPlayer(memberId);

			if (member != null) {
				syncPartyTo(member, party);
			}
		}
	}

	private static void syncPartyTo(ServerPlayer viewer, PartyData party) {
		syncPartyTo(viewer, party, false);
	}

	private static void syncPartyTo(ServerPlayer viewer, PartyData party, boolean forceShowAllMembers) {
		if (viewer == null || party == null) {
			return;
		}

		PartySavedData data = getSavedData();
		LinkedHashSet<UUID> pins = party.pinsByViewer.getOrDefault(viewer.getUUID(), new LinkedHashSet<>());
		boolean showSelf = forceShowAllMembers || party.showSelfByViewer.getOrDefault(viewer.getUUID(), party.defaultShowSelf);
		List<${package}.network.PartyApiNetwork.MemberSyncData> members = new ArrayList<>();

		for (UUID memberId : party.members) {
			if (!showSelf && memberId.equals(viewer.getUUID())) {
				continue;
			}

			ServerPlayer member = getServerPlayer(memberId);

			if (member == null) {
				continue;
			}

			Map<String, String> stats = data == null ? Map.of() : filterStatsForDisplay(data.extraStatsByPlayer.getOrDefault(memberId, Map.of()));

			members.add(new ${package}.network.PartyApiNetwork.MemberSyncData(
				memberId.toString(),
				member.getGameProfile().getName(),
				member.getHealth(),
				member.getMaxHealth(),
				member.getAbsorptionAmount(),
				member.getFoodData().getFoodLevel(),
				member.getFoodData().getSaturationLevel(),
				party.leader.equals(memberId),
				pins.contains(memberId),
				stats
			));
		}

		int x = party.overlayXByViewer.getOrDefault(viewer.getUUID(), PartyApiServerConfig.defaultOverlayX());
		int y = party.overlayYByViewer.getOrDefault(viewer.getUUID(), PartyApiServerConfig.defaultOverlayY());

		List<${package}.network.PartyApiNetwork.OverlayElementPositionSyncData> elementPositions = new ArrayList<>();
		for (Map.Entry<String, OverlayElementPosition> entry : party.overlayElementPositionsByViewer.getOrDefault(viewer.getUUID(), Map.of()).entrySet()) {
			elementPositions.add(new ${package}.network.PartyApiNetwork.OverlayElementPositionSyncData(entry.getKey(), entry.getValue().x, entry.getValue().y));
		}

		List<${package}.network.PartyApiNetwork.CustomOverlayEntrySyncData> customEntries = new ArrayList<>();
		for (CustomOverlayEntry entry : party.customOverlayEntriesByViewer.getOrDefault(viewer.getUUID(), Map.of()).values()) {
			customEntries.add(new ${package}.network.PartyApiNetwork.CustomOverlayEntrySyncData(entry.id, entry.type, entry.label, entry.value, entry.max, entry.x, entry.y, entry.width, entry.height, entry.texture));
		}

		${package}.network.PartyApiNetwork.syncParty(
			viewer,
			party.id.toString(),
			party.leader.toString(),
			party.pvpEnabled,
			party.overlayPositionByViewer.getOrDefault(viewer.getUUID(), "CUSTOM"),
			x,
			y,
			PartyApiServerConfig.overlayNicknameFontScalePercent(),
			showSelf,
			viewer.hasPermissions(PartyApiServerConfig.adminPermissionLevel()),
			members,
			elementPositions,
			customEntries
		);
	}

	private static List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> buildOnlinePlayerList(ServerPlayer viewer, boolean includeViewer) {
		List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> list = new ArrayList<>();
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();
		PartySavedData data = getSavedData();
		PartyData viewerParty = viewer != null && data != null ? data.getPartyOf(viewer.getUUID()) : null;

		if (server == null || viewer == null) {
			return list;
		}

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			if (!includeViewer && player.getUUID().equals(viewer.getUUID())) {
				continue;
			}

			PartyData targetParty = data != null ? data.getPartyOf(player.getUUID()) : null;
			boolean inViewerParty = viewerParty != null && viewerParty.members.contains(player.getUUID());
			boolean pending = viewerParty != null && INVITES.containsKey(player.getUUID()) && INVITES.get(player.getUUID()).partyId.equals(viewerParty.id) && !INVITES.get(player.getUUID()).isExpired();

			String targetPartyId = "";
			String leaderId = "";
			String leaderName = "";
			int partySize = 0;
			int partyMax = 0;
			boolean targetIsLeader = false;

			if (targetParty != null) {
				targetPartyId = targetParty.id.toString();
				leaderId = targetParty.leader.toString();
				ServerPlayer leader = getServerPlayer(targetParty.leader);
				leaderName = leader != null ? leader.getGameProfile().getName() : leaderId;
				partySize = targetParty.members.size();
				partyMax = targetParty.maxMembers;
				targetIsLeader = targetParty.leader.equals(player.getUUID());
			}

			String levelText = getLevelTextForPlayer(data, player.getUUID());

			list.add(new ${package}.network.PartyApiNetwork.OnlinePlayerSyncData(
				player.getUUID().toString(),
				player.getGameProfile().getName(),
				inViewerParty,
				pending,
				targetPartyId,
				leaderId,
				leaderName,
				partySize,
				partyMax,
				targetIsLeader,
				!levelText.isBlank(),
				levelText
			));
		}

		return list;
	}

	private static String inviteCooldownKey(UUID sender, UUID target) {
		return String.valueOf(sender) + "->" + String.valueOf(target);
	}

	private static long getInviteCooldownSecondsRemaining(ServerPlayer sender, ServerPlayer target) {
		if (sender == null || target == null) {
			return 0L;
		}

		Long started = INVITE_COOLDOWNS.get(inviteCooldownKey(sender.getUUID(), target.getUUID()));
		if (started == null) {
			return 0L;
		}

		long cooldownMs = Math.max(1L, PartyApiServerConfig.inviteCooldownSeconds()) * 1000L;
		long elapsed = System.currentTimeMillis() - started;
		long remaining = cooldownMs - elapsed;

		if (remaining <= 0L) {
			INVITE_COOLDOWNS.remove(inviteCooldownKey(sender.getUUID(), target.getUUID()));
			return 0L;
		}

		return Math.max(1L, (remaining + 999L) / 1000L);
	}

	private static void clearExpiredInviteCooldowns() {
		long cooldownMs = Math.max(1L, PartyApiServerConfig.inviteCooldownSeconds()) * 1000L;
		long now = System.currentTimeMillis();

		for (String key : new ArrayList<>(INVITE_COOLDOWNS.keySet())) {
			Long started = INVITE_COOLDOWNS.get(key);
			if (started == null || now - started > cooldownMs) {
				INVITE_COOLDOWNS.remove(key);
			}
		}
	}

	private static void clearExpiredInvites() {
		for (UUID invited : new ArrayList<>(INVITES.keySet())) {
			InviteData invite = INVITES.get(invited);

			if (invite == null || invite.isExpired()) {
				INVITES.remove(invited);
			}
		}
	}

	private static PartyData getLeaderParty(ServerPlayer actor) {
		PartySavedData data = getSavedData();
		PartyData party = actor != null && data != null ? data.getPartyOf(actor.getUUID()) : null;
		return party != null && party.leader.equals(actor.getUUID()) ? party : null;
	}

	private static boolean isFull(PartyData party) {
		return party != null && party.members.size() >= party.maxMembers;
	}

	private static int clampMaxMembers(int maxMembers) {
		return Math.max(1, Math.min(PartyApiServerConfig.hardMaxMembers(), maxMembers));
	}

	private static String normalizePosition(String position) {
		if (position == null) {
			return "CUSTOM";
		}

		return switch (position.trim().toUpperCase(java.util.Locale.ROOT)) {
			case "LEFT_TOP", "TOP_LEFT" -> "LEFT_TOP";
			case "LEFT_BOTTOM", "BOTTOM_LEFT" -> "LEFT_BOTTOM";
			case "RIGHT_TOP", "TOP_RIGHT" -> "RIGHT_TOP";
			case "RIGHT_CENTER", "RIGHT" -> "RIGHT_CENTER";
			case "RIGHT_BOTTOM", "BOTTOM_RIGHT" -> "RIGHT_BOTTOM";
			default -> "CUSTOM";
		};
	}

	private static int[] parseXY(String value) {
		int[] result = new int[] { PartyApiServerConfig.defaultOverlayX(), PartyApiServerConfig.defaultOverlayY() };

		if (value == null) {
			return result;
		}

		String[] parts = value.split(",");

		if (parts.length >= 2) {
			result[0] = parseInt(parts[0], result[0]);
			result[1] = parseInt(parts[1], result[1]);
		}

		return result;
	}

	private static int parseInt(String value, int fallback) {
		try {
			return Integer.parseInt(value.trim());
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	private static void clearAllOnlinePartyScreens() {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return;
		}

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			${package}.network.PartyApiNetwork.sendEmptyParty(player);
		}
	}

	private static void syncAllOnlineParties() {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return;
		}

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			syncPartyTo(player);
		}
	}

	private static ServerPlayer getServerPlayer(UUID uuid) {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();
		return server != null && uuid != null ? server.getPlayerList().getPlayer(uuid) : null;
	}

	private static ServerPlayer parsePlayer(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}

		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return null;
		}

		try {
			ServerPlayer byUuid = server.getPlayerList().getPlayer(UUID.fromString(value));

			if (byUuid != null) {
				return byUuid;
			}
		} catch (Throwable ignored) {
		}

		return server.getPlayerList().getPlayerByName(value);
	}

	private static PartySavedData getSavedData() {
		try {
			MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

			if (server == null) {
				return null;
			}

			ServerLevel overworld = server.overworld();

			if (overworld == null) {
				return null;
			}

			return overworld.getDataStorage().computeIfAbsent(
				new SavedData.Factory<>(PartySavedData::new, PartySavedData::load, null),
				DATA_NAME
			);
		} catch (Throwable ignored) {
			return null;
		}
	}

	private record OverlayElementPosition(int x, int y) {
	}

	private record CustomOverlayEntry(String id, String type, String label, String value, String max, int x, int y, int width, int height, String texture) {
	}

	private record InviteData(UUID partyId, UUID sender, UUID target, long createdAt) {
		private boolean isExpired() {
			long lifetime = Math.max(1L, PartyApiServerConfig.inviteCooldownSeconds()) * 1000L;
			return System.currentTimeMillis() - createdAt > lifetime;
		}
	}

	private static final class PartyData {
		private final UUID id;
		private UUID leader;
		private boolean pvpEnabled = false;
		private boolean defaultShowSelf = false;
		private int maxMembers = PartyApiServerConfig.defaultMaxMembers();

		private final LinkedHashSet<UUID> members = new LinkedHashSet<>();
		private final Map<UUID, LinkedHashSet<UUID>> pinsByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, String> overlayPositionByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, Integer> overlayXByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, Integer> overlayYByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, Boolean> showSelfByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, Map<String, OverlayElementPosition>> overlayElementPositionsByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, Map<String, CustomOverlayEntry>> customOverlayEntriesByViewer = new ConcurrentHashMap<>();

		private PartyData(UUID id, UUID leader) {
			this.id = id;
			this.leader = leader;
		}
	}

	public static final class PartySavedData extends SavedData {
		private final Map<UUID, PartyData> parties = new ConcurrentHashMap<>();
		private final Map<UUID, Map<String, String>> extraStatsByPlayer = new ConcurrentHashMap<>();
		private String levelDisplayRequiredModId = "";

		private PartyData getPartyOf(UUID playerId) {
			if (playerId == null) {
				return null;
			}

			for (PartyData party : parties.values()) {
				if (party.members.contains(playerId)) {
					return party;
				}
			}

			return null;
		}

		public static PartySavedData load(CompoundTag tag, HolderLookup.Provider provider) {
			PartySavedData data = new PartySavedData();
			data.levelDisplayRequiredModId = tag.contains("LevelDisplayRequiredModId") ? normalizeModId(tag.getString("LevelDisplayRequiredModId")) : "";
			ListTag partiesTag = tag.getList("Parties", Tag.TAG_COMPOUND);

			for (int i = 0; i < partiesTag.size(); i++) {
				try {
					CompoundTag pt = partiesTag.getCompound(i);
					PartyData party = new PartyData(UUID.fromString(pt.getString("Id")), UUID.fromString(pt.getString("Leader")));
					party.pvpEnabled = pt.getBoolean("PvpEnabled");
					party.defaultShowSelf = pt.contains("DefaultShowSelf") ? pt.getBoolean("DefaultShowSelf") : PartyApiServerConfig.defaultShowSelf();
					party.maxMembers = pt.contains("MaxMembers") ? clampStatic(pt.getInt("MaxMembers"), 1, PartyApiServerConfig.hardMaxMembers()) : PartyApiServerConfig.defaultMaxMembers();

					ListTag members = pt.getList("Members", Tag.TAG_STRING);
					for (int j = 0; j < members.size(); j++) {
						party.members.add(UUID.fromString(members.getString(j)));
					}

					ListTag viewerSettings = pt.getList("ViewerSettings", Tag.TAG_COMPOUND);
					for (int j = 0; j < viewerSettings.size(); j++) {
						CompoundTag vt = viewerSettings.getCompound(j);
						UUID viewer = UUID.fromString(vt.getString("Viewer"));
						party.showSelfByViewer.put(viewer, vt.contains("ShowSelf") ? vt.getBoolean("ShowSelf") : party.defaultShowSelf);
						party.overlayPositionByViewer.put(viewer, vt.contains("Position") ? vt.getString("Position") : "CUSTOM");
						party.overlayXByViewer.put(viewer, vt.contains("X") ? vt.getInt("X") : PartyApiServerConfig.defaultOverlayX());
						party.overlayYByViewer.put(viewer, vt.contains("Y") ? vt.getInt("Y") : PartyApiServerConfig.defaultOverlayY());
					}

					data.parties.put(party.id, party);
				} catch (Throwable ignored) {
				}
			}

			ListTag statsTag = tag.getList("Stats", Tag.TAG_COMPOUND);
			for (int i = 0; i < statsTag.size(); i++) {
				try {
					CompoundTag st = statsTag.getCompound(i);
					UUID player = UUID.fromString(st.getString("Player"));
					Map<String, String> stats = new LinkedHashMap<>();
					ListTag values = st.getList("Values", Tag.TAG_COMPOUND);

					for (int j = 0; j < values.size(); j++) {
						CompoundTag vt = values.getCompound(j);
						stats.put(vt.getString("Key"), vt.getString("Value"));
					}

					data.extraStatsByPlayer.put(player, stats);
				} catch (Throwable ignored) {
				}
			}

			return data;
		}

		@Override
		public CompoundTag save(CompoundTag tag, HolderLookup.Provider provider) {
			ListTag partiesTag = new ListTag();

			for (PartyData party : parties.values()) {
				CompoundTag pt = new CompoundTag();
				pt.putString("Id", party.id.toString());
				pt.putString("Leader", party.leader.toString());
				pt.putBoolean("PvpEnabled", party.pvpEnabled);
				pt.putBoolean("DefaultShowSelf", party.defaultShowSelf);
				pt.putInt("MaxMembers", party.maxMembers);

				ListTag members = new ListTag();
				for (UUID member : party.members) {
					members.add(StringTag.valueOf(member.toString()));
				}
				pt.put("Members", members);

				ListTag viewerSettings = new ListTag();
				for (UUID viewer : party.members) {
					CompoundTag vt = new CompoundTag();
					vt.putString("Viewer", viewer.toString());
					vt.putBoolean("ShowSelf", party.showSelfByViewer.getOrDefault(viewer, party.defaultShowSelf));
					vt.putString("Position", party.overlayPositionByViewer.getOrDefault(viewer, "CUSTOM"));
					vt.putInt("X", party.overlayXByViewer.getOrDefault(viewer, PartyApiServerConfig.defaultOverlayX()));
					vt.putInt("Y", party.overlayYByViewer.getOrDefault(viewer, PartyApiServerConfig.defaultOverlayY()));
					viewerSettings.add(vt);
				}
				pt.put("ViewerSettings", viewerSettings);

				partiesTag.add(pt);
			}
			tag.put("Parties", partiesTag);

			ListTag statsTag = new ListTag();
			for (Map.Entry<UUID, Map<String, String>> entry : extraStatsByPlayer.entrySet()) {
				CompoundTag st = new CompoundTag();
				st.putString("Player", entry.getKey().toString());
				ListTag values = new ListTag();

				for (Map.Entry<String, String> stat : entry.getValue().entrySet()) {
					CompoundTag vt = new CompoundTag();
					vt.putString("Key", stat.getKey());
					vt.putString("Value", stat.getValue());
					values.add(vt);
				}

				st.put("Values", values);
				statsTag.add(st);
			}
			tag.put("Stats", statsTag);
			tag.putString("LevelDisplayRequiredModId", normalizeModId(levelDisplayRequiredModId));

			return tag;
		}

		private static int clampStatic(int value, int min, int max) {
			return Math.max(min, Math.min(max, value));
		}
	}
}
