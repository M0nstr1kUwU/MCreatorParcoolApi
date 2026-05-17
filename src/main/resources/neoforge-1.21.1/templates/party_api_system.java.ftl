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
import net.minecraft.nbt.Tag;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.saveddata.SavedData;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.tick.PlayerTickEvent;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiSystem {
	private static final String DATA_NAME = "${modid}_party_api_system_v1";

	private static final int MAX_OVERLAY_PINNED = 4;
	private static final int DEFAULT_MAX_MEMBERS = 4; // fallback, real default comes from PartyApiServerConfig
	private static final int HARD_MAX_MEMBERS = 200; // fallback, real hard cap comes from PartyApiServerConfig

	private static final Map<UUID, UUID> INVITES = new ConcurrentHashMap<>();
	private static final Map<UUID, Long> INVITE_TIME = new ConcurrentHashMap<>();
	private static final long INVITE_LIFETIME_MS = 120_000L;

	private PartyApiSystem() {
	}

	public static boolean isPartySystemEnabled() {
		PartySavedData data = getSavedData();
		return data == null || data.partySystemEnabled;
	}

	public static boolean adminSetPartySystemEnabled(boolean enabled) {
		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		data.partySystemEnabled = enabled;
		data.setDirty();

		if (!enabled) {
			clearAllOnlinePartyScreens();
		} else {
			syncAllOnlineParties();
		}

		return true;
	}

	public static boolean createParty(ServerPlayer leader) {
		return createParty(leader, true);
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

		if (party == null) {
			return false;
		}

		return disbandPartyInternal(data, party);
	}

	private static boolean disbandPartyInternal(PartySavedData data, PartyData party) {
		if (data == null || party == null) {
			return false;
		}

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

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(leader.getUUID());

		if (party == null) {
			createParty(leader, true);
			party = data.getPartyOf(leader.getUUID());
		}

		if (party == null || !party.leader.equals(leader.getUUID())) {
			return false;
		}

		if (data.getPartyOf(invited.getUUID()) != null) {
			return false;
		}

		if (isFull(party)) {
			leader.displayClientMessage(net.minecraft.network.chat.Component.literal(
				"Party is full (" + party.members.size() + "/" + party.maxMembers + ")"
			), false);
			return false;
		}

		INVITES.put(invited.getUUID(), party.id);
		INVITE_TIME.put(invited.getUUID(), System.currentTimeMillis());

		invited.displayClientMessage(net.minecraft.network.chat.Component.literal(
			"Party invite from " + leader.getGameProfile().getName() + ". Use /party accept"
		), false);

		if (PartyApiServerConfig.inviteGuiEnabled()) {
			${package}.network.PartyApiNetwork.openPartyInviteScreen(invited, leader.getGameProfile().getName());
		}

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

		UUID partyId = INVITES.remove(player.getUUID());
		INVITE_TIME.remove(player.getUUID());

		if (partyId == null) {
			return false;
		}

		PartyData party = data.parties.get(partyId);

		if (party == null || isFull(party)) {
			return false;
		}

		party.members.add(player.getUUID());
		party.showSelfByViewer.putIfAbsent(player.getUUID(), party.defaultShowSelf);
		data.setDirty();

		syncParty(party);
		return true;
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
		if (actor == null || target == null || !isPartySystemEnabled()) {
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

		if (actor.getUUID().equals(target.getUUID())) {
			return false;
		}

		removeMemberInternal(party, target.getUUID());

		if (party.leader.equals(target.getUUID()) && !party.members.isEmpty()) {
			party.leader = party.members.iterator().next();
		}

		data.setDirty();

		${package}.network.PartyApiNetwork.sendEmptyParty(target);
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
		party.showSelfByViewer.remove(playerId);

		for (LinkedHashSet<UUID> pins : party.pinsByViewer.values()) {
			pins.remove(playerId);
		}
	}

	public static boolean setPvp(ServerPlayer actor, boolean enabled) {
		if (actor == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(actor.getUUID());

		if (party == null || !party.leader.equals(actor.getUUID())) {
			return false;
		}

		party.pvpEnabled = enabled;
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static boolean adminSetPvp(ServerPlayer targetPartyMember, boolean enabled) {
		if (targetPartyMember == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(targetPartyMember.getUUID());

		if (party == null) {
			return false;
		}

		party.pvpEnabled = enabled;
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static boolean setPartyMaxMembers(ServerPlayer actor, int maxMembers) {
		if (actor == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(actor.getUUID());

		if (party == null || !party.leader.equals(actor.getUUID())) {
			return false;
		}

		party.maxMembers = clampMaxMembers(maxMembers);
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static boolean adminSetPartyMaxMembers(ServerPlayer targetPartyMember, int maxMembers) {
		if (targetPartyMember == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(targetPartyMember.getUUID());

		if (party == null) {
			return false;
		}

		party.maxMembers = clampMaxMembers(maxMembers);
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static int getPartyMaxMembers(ServerPlayer player) {
		if (player == null) {
			return 0;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return 0;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		return party != null ? party.maxMembers : 0;
	}

	public static boolean isPartyFull(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(player.getUUID());

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
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static boolean setPinned(ServerPlayer viewer, ServerPlayer target, boolean pinned) {
		if (viewer == null || target == null || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(viewer.getUUID());

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

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(viewer.getUUID());

		if (party == null) {
			return false;
		}

		party.showSelfByViewer.put(viewer.getUUID(), showSelf);
		data.setDirty();

		syncPartyTo(viewer, party);
		return true;
	}

	public static boolean setOverlayPosition(ServerPlayer player, String position) {
		if (player == null || !isPartySystemEnabled()) {
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

		party.overlayPositionByViewer.put(player.getUUID(), normalizePosition(position));
		data.setDirty();
		syncPartyTo(player, party);
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

	public static boolean isInParty(ServerPlayer player) {
		PartySavedData data = getSavedData();
		return player != null && data != null && data.getPartyOf(player.getUUID()) != null;
	}

	public static boolean areInSameParty(ServerPlayer first, ServerPlayer second) {
		if (first == null || second == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(first.getUUID());

		return party != null && party.members.contains(second.getUUID());
	}

	public static boolean isPartyPvpEnabled(ServerPlayer player) {
		if (player == null) {
			return true;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return true;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		return party == null || party.pvpEnabled;
	}

	public static boolean shouldCancelPvpDamage(ServerPlayer attacker, ServerPlayer target) {
		if (attacker == null || target == null || attacker.getUUID().equals(target.getUUID())) {
			return false;
		}

		if (!isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(attacker.getUUID());

		return party != null && !party.pvpEnabled && party.members.contains(target.getUUID());
	}

	public static int getPartySize(ServerPlayer player) {
		PartySavedData data = getSavedData();

		if (player == null || data == null) {
			return 0;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		return party != null ? party.members.size() : 0;
	}

	public static int getOnlinePartySize(ServerPlayer player) {
		PartySavedData data = getSavedData();

		if (player == null || data == null) {
			return 0;
		}

		PartyData party = data.getPartyOf(player.getUUID());

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

	public static void openPartyGui(ServerPlayer player) {
		if (player == null || !isPartySystemEnabled()) {
			return;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		if (party != null) {
			syncPartyTo(player, party);
		}

		${package}.network.PartyApiNetwork.openPartyScreen(player);
	}

	public static void openPartyGuiForPartyOf(ServerPlayer viewer, ServerPlayer targetPartyMember) {
		if (viewer == null || targetPartyMember == null) {
			return;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return;
		}

		PartyData party = data.getPartyOf(targetPartyMember.getUUID());

		if (party != null) {
			syncPartyTo(viewer, party);
		}

		${package}.network.PartyApiNetwork.openPartyScreen(viewer);
	}


	public static boolean declineInvite(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		boolean hadInvite = INVITES.remove(player.getUUID()) != null;
		INVITE_TIME.remove(player.getUUID());
		return hadInvite;
	}

	public static boolean isPartyLeader(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		return party != null && party.leader.equals(player.getUUID());
	}

	public static boolean transferLeadership(ServerPlayer actor, ServerPlayer target) {
		if (actor == null || target == null || !isPartySystemEnabled()) {
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

		party.leader = target.getUUID();
		data.setDirty();

		syncParty(party);
		return true;
	}

	public static boolean adminTransferLeadership(ServerPlayer targetPartyMember, ServerPlayer newLeader) {
		if (targetPartyMember == null || newLeader == null) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(targetPartyMember.getUUID());

		if (party == null || !party.members.contains(newLeader.getUUID())) {
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

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(sender.getUUID());

		if (party == null) {
			return false;
		}

		net.minecraft.network.chat.Component component = net.minecraft.network.chat.Component.literal(
			"[Party] <" + sender.getGameProfile().getName() + "> " + message
		);

		for (UUID memberId : party.members) {
			ServerPlayer member = getServerPlayer(memberId);

			if (member != null) {
				member.sendSystemMessage(component);
			}
		}

		return true;
	}

	public static boolean sendPartyChatStyled(ServerPlayer sender, net.minecraft.network.chat.Component message) {
    	if (sender == null || message == null || !isPartySystemEnabled()) {
    		return false;
    	}

    	PartySavedData data = getSavedData();

    	if (data == null) {
    		return false;
    	}

    	PartyData party = data.getPartyOf(sender.getUUID());

    	if (party == null) {
    		return false;
    	}

    	net.minecraft.network.chat.MutableComponent finalMessage = net.minecraft.network.chat.Component.literal("[Party] ")
    		.withStyle(style -> style.withColor(net.minecraft.ChatFormatting.AQUA))
    		.append(net.minecraft.network.chat.Component.literal(sender.getGameProfile().getName() + ": ")
    			.withStyle(style -> style.withColor(net.minecraft.ChatFormatting.GRAY)))
    		.append(message);

    	for (java.util.UUID memberId : party.members) {
    		ServerPlayer member = getServerPlayer(memberId);

    		if (member != null) {
    			member.displayClientMessage(finalMessage, false);
    		}
    	}

    	return true;
    }

	public static boolean sendMessageToParty(ServerPlayer anchor, String message) {
		if (anchor == null || message == null || message.isBlank() || !isPartySystemEnabled()) {
			return false;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		PartyData party = data.getPartyOf(anchor.getUUID());

		if (party == null) {
			return false;
		}

		net.minecraft.network.chat.Component component = net.minecraft.network.chat.Component.literal(message);

		for (UUID memberId : party.members) {
			ServerPlayer member = getServerPlayer(memberId);

			if (member != null) {
				member.sendSystemMessage(component);
			}
		}

		return true;
	}

	public static void handleClientAction(ServerPlayer player, String action, String targetId, String value) {
		if (player == null || action == null || !isPartySystemEnabled()) {
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
			case "position" -> setOverlayPosition(player, value);
			case "show_self_on" -> setShowSelf(player, true);
			case "show_self_off" -> setShowSelf(player, false);
			case "pvp_on" -> setPvp(player, true);
			case "pvp_off" -> setPvp(player, false);
			case "accept_invite" -> acceptInvite(player);
			case "decline_invite" -> declineInvite(player);
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

		PartySavedData data = getSavedData();

		if (data == null) {
			return;
		}

		PartyData party = data.getPartyOf(player.getUUID());

		if (party == null) {
			return;
		}

		if (!data.partySystemEnabled) {
			${package}.network.PartyApiNetwork.sendEmptyParty(player);
			return;
		}

		syncPartyTo(player, party);
	}

	private static void clearExpiredInvites() {
		long now = System.currentTimeMillis();

		for (UUID invited : new ArrayList<>(INVITE_TIME.keySet())) {
			long time = INVITE_TIME.getOrDefault(invited, 0L);

			if (now - time > (PartyApiServerConfig.inviteLifetimeSeconds() * 1000L)) {
				INVITE_TIME.remove(invited);
				INVITES.remove(invited);
			}
		}
	}

	private static boolean isFull(PartyData party) {
		return party != null && party.members.size() >= party.maxMembers;
	}

	private static int clampMaxMembers(int maxMembers) {
		return Math.max(1, Math.min(PartyApiServerConfig.hardMaxMembers(), maxMembers));
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

		PartySavedData data = getSavedData();

		if (data == null) {
			return;
		}

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			PartyData party = data.getPartyOf(player.getUUID());

			if (party != null) {
				syncPartyTo(player, party);
			}
		}
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
		if (viewer == null || party == null) {
			return;
		}

		PartySavedData data = getSavedData();

		if (data == null) {
			return;
		}

		List<${package}.network.PartyApiNetwork.MemberSyncData> members = new ArrayList<>();
		LinkedHashSet<UUID> pins = party.pinsByViewer.getOrDefault(viewer.getUUID(), new LinkedHashSet<>());
		boolean showSelf = party.showSelfByViewer.getOrDefault(viewer.getUUID(), party.defaultShowSelf);

		for (UUID memberId : party.members) {
			if (!showSelf && memberId.equals(viewer.getUUID())) {
				continue;
			}

			ServerPlayer member = getServerPlayer(memberId);

			if (member == null) {
				continue;
			}

			Map<String, String> stats = data.extraStatsByPlayer.getOrDefault(memberId, Map.of());

			members.add(new ${package}.network.PartyApiNetwork.MemberSyncData(
				memberId.toString(),
				member.getGameProfile().getName(),
				Math.max(0.0F, member.getHealth()),
				Math.max(1.0F, member.getMaxHealth()),
				Math.max(0.0F, member.getAbsorptionAmount()),
				Math.max(0, member.getFoodData().getFoodLevel()),
				Math.max(0.0F, member.getFoodData().getSaturationLevel()),
				party.leader.equals(memberId),
				pins.contains(memberId),
				new LinkedHashMap<>(stats)
			));
		}

		String position = party.overlayPositionByViewer.getOrDefault(viewer.getUUID(), "LEFT_CENTER");

		${package}.network.PartyApiNetwork.syncParty(
			viewer,
			party.id.toString(),
			party.leader.toString(),
			party.pvpEnabled,
			position,
			members
		);
	}

	private static ServerPlayer getServerPlayer(UUID uuid) {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null || uuid == null) {
			return null;
		}

		return server.getPlayerList().getPlayer(uuid);
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
			UUID uuid = UUID.fromString(value);
			ServerPlayer byUuid = server.getPlayerList().getPlayer(uuid);

			if (byUuid != null) {
				return byUuid;
			}
		} catch (Throwable ignored) {
		}

		return server.getPlayerList().getPlayerByName(value);
	}

	private static String normalizePosition(String position) {
		if (position == null) {
			return "LEFT_CENTER";
		}

		return switch (position.trim().toUpperCase(java.util.Locale.ROOT)) {
			case "LEFT_TOP", "TOP_LEFT" -> "LEFT_TOP";
			case "LEFT_BOTTOM", "BOTTOM_LEFT" -> "LEFT_BOTTOM";
			case "RIGHT_TOP", "TOP_RIGHT" -> "RIGHT_TOP";
			case "RIGHT_CENTER", "RIGHT" -> "RIGHT_CENTER";
			case "RIGHT_BOTTOM", "BOTTOM_RIGHT" -> "RIGHT_BOTTOM";
			default -> "LEFT_CENTER";
		};
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

	public static final class PartyData {
		private final UUID id;
		private UUID leader;
		private boolean pvpEnabled = false;
		private boolean defaultShowSelf = true;
		private int maxMembers = DEFAULT_MAX_MEMBERS;
		private final LinkedHashSet<UUID> members = new LinkedHashSet<>();
		private final Map<UUID, LinkedHashSet<UUID>> pinsByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, String> overlayPositionByViewer = new ConcurrentHashMap<>();
		private final Map<UUID, Boolean> showSelfByViewer = new ConcurrentHashMap<>();

		private PartyData(UUID id, UUID leader) {
			this.id = id;
			this.leader = leader;
		}
	}

	public static final class PartySavedData extends SavedData {
		private boolean partySystemEnabled = PartyApiServerConfig.defaultPartySystemEnabled();
		private final Map<UUID, PartyData> parties = new ConcurrentHashMap<>();
		private final Map<UUID, Map<String, String>> extraStatsByPlayer = new ConcurrentHashMap<>();

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

			data.partySystemEnabled = !tag.contains("PartySystemEnabled") || tag.getBoolean("PartySystemEnabled");

			ListTag partiesTag = tag.getList("Parties", Tag.TAG_COMPOUND);

			for (int i = 0; i < partiesTag.size(); i++) {
				CompoundTag partyTag = partiesTag.getCompound(i);

				try {
					UUID id = UUID.fromString(partyTag.getString("Id"));
					UUID leader = UUID.fromString(partyTag.getString("Leader"));

					PartyData party = new PartyData(id, leader);
					party.pvpEnabled = partyTag.getBoolean("PvpEnabled");
					party.defaultShowSelf = !partyTag.contains("DefaultShowSelf") || partyTag.getBoolean("DefaultShowSelf");
					party.maxMembers = partyTag.contains("MaxMembers") ? clampMaxMembers(partyTag.getInt("MaxMembers")) : PartyApiServerConfig.defaultMaxMembers();

					ListTag membersTag = partyTag.getList("Members", Tag.TAG_STRING);
					for (int j = 0; j < membersTag.size(); j++) {
						party.members.add(UUID.fromString(membersTag.getString(j)));
					}

					ListTag pinsTag = partyTag.getList("Pins", Tag.TAG_COMPOUND);
					for (int j = 0; j < pinsTag.size(); j++) {
						CompoundTag pinTag = pinsTag.getCompound(j);
						UUID viewer = UUID.fromString(pinTag.getString("Viewer"));
						LinkedHashSet<UUID> pins = new LinkedHashSet<>();

						ListTag values = pinTag.getList("Values", Tag.TAG_STRING);
						for (int k = 0; k < values.size(); k++) {
							pins.add(UUID.fromString(values.getString(k)));
						}

						party.pinsByViewer.put(viewer, pins);
					}

					ListTag positionsTag = partyTag.getList("Positions", Tag.TAG_COMPOUND);
					for (int j = 0; j < positionsTag.size(); j++) {
						CompoundTag posTag = positionsTag.getCompound(j);
						party.overlayPositionByViewer.put(
							UUID.fromString(posTag.getString("Viewer")),
							posTag.getString("Position")
						);
					}

					ListTag showSelfTag = partyTag.getList("ShowSelf", Tag.TAG_COMPOUND);
					for (int j = 0; j < showSelfTag.size(); j++) {
						CompoundTag showTag = showSelfTag.getCompound(j);

						try {
							party.showSelfByViewer.put(
								UUID.fromString(showTag.getString("Viewer")),
								showTag.getBoolean("Value")
							);
						} catch (Throwable ignored) {
						}
					}

					for (UUID memberId : party.members) {
						party.showSelfByViewer.putIfAbsent(memberId, party.defaultShowSelf);
					}

					data.parties.put(id, party);
				} catch (Throwable ignored) {
				}
			}

			ListTag statsTag = tag.getList("ExtraStats", Tag.TAG_COMPOUND);
			for (int i = 0; i < statsTag.size(); i++) {
				CompoundTag playerTag = statsTag.getCompound(i);

				try {
					UUID playerId = UUID.fromString(playerTag.getString("Player"));
					Map<String, String> stats = new LinkedHashMap<>();

					ListTag entries = playerTag.getList("Entries", Tag.TAG_COMPOUND);
					for (int j = 0; j < entries.size(); j++) {
						CompoundTag entry = entries.getCompound(j);
						stats.put(entry.getString("Key"), entry.getString("Value"));
					}

					data.extraStatsByPlayer.put(playerId, stats);
				} catch (Throwable ignored) {
				}
			}

			return data;
		}

		@Override
		public CompoundTag save(CompoundTag tag, HolderLookup.Provider provider) {
			tag.putBoolean("PartySystemEnabled", partySystemEnabled);

			ListTag partiesTag = new ListTag();

			for (PartyData party : parties.values()) {
				CompoundTag partyTag = new CompoundTag();

				partyTag.putString("Id", party.id.toString());
				partyTag.putString("Leader", party.leader.toString());
				partyTag.putBoolean("PvpEnabled", party.pvpEnabled);
				partyTag.putBoolean("DefaultShowSelf", party.defaultShowSelf);
				partyTag.putInt("MaxMembers", clampMaxMembers(party.maxMembers));

				ListTag membersTag = new ListTag();
				for (UUID member : party.members) {
					membersTag.add(net.minecraft.nbt.StringTag.valueOf(member.toString()));
				}
				partyTag.put("Members", membersTag);

				ListTag pinsTag = new ListTag();
				for (Map.Entry<UUID, LinkedHashSet<UUID>> entry : party.pinsByViewer.entrySet()) {
					CompoundTag pinTag = new CompoundTag();
					pinTag.putString("Viewer", entry.getKey().toString());

					ListTag values = new ListTag();
					for (UUID pinned : entry.getValue()) {
						values.add(net.minecraft.nbt.StringTag.valueOf(pinned.toString()));
					}

					pinTag.put("Values", values);
					pinsTag.add(pinTag);
				}
				partyTag.put("Pins", pinsTag);

				ListTag positionsTag = new ListTag();
				for (Map.Entry<UUID, String> entry : party.overlayPositionByViewer.entrySet()) {
					CompoundTag posTag = new CompoundTag();
					posTag.putString("Viewer", entry.getKey().toString());
					posTag.putString("Position", entry.getValue());
					positionsTag.add(posTag);
				}
				partyTag.put("Positions", positionsTag);

				ListTag showSelfTag = new ListTag();
				for (Map.Entry<UUID, Boolean> entry : party.showSelfByViewer.entrySet()) {
					CompoundTag showTag = new CompoundTag();
					showTag.putString("Viewer", entry.getKey().toString());
					showTag.putBoolean("Value", entry.getValue());
					showSelfTag.add(showTag);
				}
				partyTag.put("ShowSelf", showSelfTag);

				partiesTag.add(partyTag);
			}

			tag.put("Parties", partiesTag);

			ListTag statsTag = new ListTag();
			for (Map.Entry<UUID, Map<String, String>> playerStats : extraStatsByPlayer.entrySet()) {
				CompoundTag playerTag = new CompoundTag();
				playerTag.putString("Player", playerStats.getKey().toString());

				ListTag entries = new ListTag();
				for (Map.Entry<String, String> entry : playerStats.getValue().entrySet()) {
					CompoundTag entryTag = new CompoundTag();
					entryTag.putString("Key", entry.getKey());
					entryTag.putString("Value", entry.getValue());
					entries.add(entryTag);
				}

				playerTag.put("Entries", entries);
				statsTag.add(playerTag);
			}

			tag.put("ExtraStats", statsTag);

			return tag;
		}
	}
}
