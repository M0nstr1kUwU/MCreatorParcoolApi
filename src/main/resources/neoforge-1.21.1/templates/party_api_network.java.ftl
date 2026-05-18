package ${package}.network;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.network.PacketDistributor;
import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;
import net.neoforged.neoforge.network.handling.IPayloadContext;
import net.neoforged.neoforge.network.registration.PayloadRegistrar;

@EventBusSubscriber(modid = "${modid}", bus = EventBusSubscriber.Bus.MOD)
public final class PartyApiNetwork {
	private static final String NETWORK_VERSION = "3";

	private PartyApiNetwork() {
	}

	@SubscribeEvent
	public static void registerPayloads(RegisterPayloadHandlersEvent event) {
		PayloadRegistrar registrar = event.registrar(NETWORK_VERSION);

		registrar.playToClient(SyncPartyPayload.TYPE, SyncPartyPayload.STREAM_CODEC, SyncPartyPayload::handleClient);
		registrar.playToClient(OpenPartyScreenPayload.TYPE, OpenPartyScreenPayload.STREAM_CODEC, OpenPartyScreenPayload::handleClient);
		registrar.playToClient(OpenPartyInvitePayload.TYPE, OpenPartyInvitePayload.STREAM_CODEC, OpenPartyInvitePayload::handleClient);
		registrar.playToClient(OnlinePlayerListPayload.TYPE, OnlinePlayerListPayload.STREAM_CODEC, OnlinePlayerListPayload::handleClient);
		registrar.playToServer(PartyActionPayload.TYPE, PartyActionPayload.STREAM_CODEC, PartyActionPayload::handleServer);
	}

	public static void syncParty(ServerPlayer player, String partyId, String leaderId, boolean pvpEnabled, String overlayPosition, int overlayX, int overlayY, int nicknameScalePercent, boolean showSelf, boolean admin, List<MemberSyncData> members, List<OverlayElementPositionSyncData> elementPositions, List<CustomOverlayEntrySyncData> customEntries) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new SyncPartyPayload(partyId, leaderId, pvpEnabled, overlayPosition, overlayX, overlayY, nicknameScalePercent, showSelf, admin, members, elementPositions, customEntries));
		} catch (Throwable ignored) {
		}
	}

	public static void sendEmptyParty(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new SyncPartyPayload("", "", false, "CUSTOM", 8, 58, 80, false, false, List.of(), List.of(), List.of()));
		} catch (Throwable ignored) {
		}
	}

	public static void openPartyScreen(ServerPlayer player) {
		openPartyScreen(player, "MAIN");
	}

	public static void openPartyScreen(ServerPlayer player, String screen) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new OpenPartyScreenPayload(screen == null ? "MAIN" : screen));
		} catch (Throwable ignored) {
		}
	}

	public static void openPartyInviteScreen(ServerPlayer player, String inviterName) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new OpenPartyInvitePayload(inviterName == null ? "Unknown" : inviterName));
		} catch (Throwable ignored) {
		}
	}

	public static void sendOnlinePlayerList(ServerPlayer player, List<OnlinePlayerSyncData> players) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new OnlinePlayerListPayload(players == null ? List.of() : players));
		} catch (Throwable ignored) {
		}
	}

	public static void sendClientAction(String action, String targetId, String value) {
		try {
			PacketDistributor.sendToServer(new PartyActionPayload(action == null ? "" : action, targetId == null ? "" : targetId, value == null ? "" : value));
		} catch (Throwable ignored) {
		}
	}

	public record MemberSyncData(String uuid, String name, float health, float maxHealth, float absorption, int food, float saturation, boolean leader, boolean pinned, Map<String, String> stats) {
		public MemberSyncData {
			uuid = uuid == null ? "" : uuid;
			name = name == null ? "" : name;
			health = Math.max(0.0F, health);
			maxHealth = Math.max(1.0F, maxHealth);
			absorption = Math.max(0.0F, absorption);
			food = Math.max(0, Math.min(20, food));
			saturation = Math.max(0.0F, saturation);
			stats = stats == null ? Map.of() : stats;
		}
	}

	public record OverlayElementPositionSyncData(String id, int x, int y) {
		public OverlayElementPositionSyncData {
			id = id == null ? "" : id;
		}
	}

	public record CustomOverlayEntrySyncData(String id, String type, String label, String value, String max, int x, int y, int width, int height, String texture) {
		public CustomOverlayEntrySyncData {
			id = id == null ? "" : id;
			type = type == null ? "VALUE" : type;
			label = label == null ? "" : label;
			value = value == null ? "" : value;
			max = max == null ? "" : max;
			width = Math.max(1, width);
			height = Math.max(1, height);
			texture = texture == null ? "" : texture;
		}
	}

	public record OnlinePlayerSyncData(String uuid, String name, boolean inMyParty, boolean pendingInvite, String partyId, String leaderId, String leaderName, int partySize, int partyMaxMembers, boolean partyLeader) {
		public OnlinePlayerSyncData {
			uuid = uuid == null ? "" : uuid;
			name = name == null ? "" : name;
			partyId = partyId == null ? "" : partyId;
			leaderId = leaderId == null ? "" : leaderId;
			leaderName = leaderName == null ? "" : leaderName;
			partySize = Math.max(0, partySize);
			partyMaxMembers = Math.max(0, partyMaxMembers);
		}

		public boolean inAnyParty() {
			return !partyId.isEmpty();
		}
	}

	public record SyncPartyPayload(
		String partyId,
		String leaderId,
		boolean pvpEnabled,
		String overlayPosition,
		int overlayX,
		int overlayY,
		int nicknameScalePercent,
		boolean showSelf,
		boolean admin,
		List<MemberSyncData> members,
		List<OverlayElementPositionSyncData> elementPositions,
		List<CustomOverlayEntrySyncData> customEntries
	) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<SyncPartyPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_sync_v3"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, SyncPartyPayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public SyncPartyPayload decode(RegistryFriendlyByteBuf buffer) {
					String partyId = buffer.readUtf();
					String leaderId = buffer.readUtf();
					boolean pvp = buffer.readBoolean();
					String position = buffer.readUtf();
					int x = buffer.readInt();
					int y = buffer.readInt();
					int nicknameScale = buffer.readInt();
					boolean showSelf = buffer.readBoolean();
					boolean admin = buffer.readBoolean();

					int memberCount = Math.max(0, buffer.readInt());
					List<MemberSyncData> members = new ArrayList<>();

					for (int i = 0; i < memberCount; i++) {
						String uuid = buffer.readUtf();
						String name = buffer.readUtf();
						float health = buffer.readFloat();
						float maxHealth = buffer.readFloat();
						float absorption = buffer.readFloat();
						int food = buffer.readInt();
						float saturation = buffer.readFloat();
						boolean leader = buffer.readBoolean();
						boolean pinned = buffer.readBoolean();

						int statCount = Math.max(0, buffer.readInt());
						Map<String, String> stats = new LinkedHashMap<>();

						for (int s = 0; s < statCount; s++) {
							stats.put(buffer.readUtf(), buffer.readUtf());
						}

						members.add(new MemberSyncData(uuid, name, health, maxHealth, absorption, food, saturation, leader, pinned, stats));
					}

					int elementCount = Math.max(0, buffer.readInt());
					List<OverlayElementPositionSyncData> elementPositions = new ArrayList<>();

					for (int i = 0; i < elementCount; i++) {
						elementPositions.add(new OverlayElementPositionSyncData(buffer.readUtf(), buffer.readInt(), buffer.readInt()));
					}

					int customCount = Math.max(0, buffer.readInt());
					List<CustomOverlayEntrySyncData> customEntries = new ArrayList<>();

					for (int i = 0; i < customCount; i++) {
						customEntries.add(new CustomOverlayEntrySyncData(
							buffer.readUtf(), buffer.readUtf(), buffer.readUtf(), buffer.readUtf(), buffer.readUtf(),
							buffer.readInt(), buffer.readInt(), buffer.readInt(), buffer.readInt(), buffer.readUtf()
						));
					}

					return new SyncPartyPayload(partyId, leaderId, pvp, position, x, y, nicknameScale, showSelf, admin, members, elementPositions, customEntries);
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, SyncPartyPayload payload) {
					buffer.writeUtf(payload.partyId() == null ? "" : payload.partyId());
					buffer.writeUtf(payload.leaderId() == null ? "" : payload.leaderId());
					buffer.writeBoolean(payload.pvpEnabled());
					buffer.writeUtf(payload.overlayPosition() == null ? "CUSTOM" : payload.overlayPosition());
					buffer.writeInt(payload.overlayX());
					buffer.writeInt(payload.overlayY());
					buffer.writeInt(payload.nicknameScalePercent());
					buffer.writeBoolean(payload.showSelf());
					buffer.writeBoolean(payload.admin());

					List<MemberSyncData> members = payload.members() == null ? List.of() : payload.members();
					buffer.writeInt(members.size());

					for (MemberSyncData member : members) {
						buffer.writeUtf(member.uuid());
						buffer.writeUtf(member.name());
						buffer.writeFloat(member.health());
						buffer.writeFloat(member.maxHealth());
						buffer.writeFloat(member.absorption());
						buffer.writeInt(member.food());
						buffer.writeFloat(member.saturation());
						buffer.writeBoolean(member.leader());
						buffer.writeBoolean(member.pinned());

						Map<String, String> stats = member.stats() == null ? Map.of() : member.stats();
						buffer.writeInt(stats.size());

						for (Map.Entry<String, String> stat : stats.entrySet()) {
							buffer.writeUtf(stat.getKey() == null ? "" : stat.getKey());
							buffer.writeUtf(stat.getValue() == null ? "" : stat.getValue());
						}
					}

					List<OverlayElementPositionSyncData> positions = payload.elementPositions() == null ? List.of() : payload.elementPositions();
					buffer.writeInt(positions.size());
					for (OverlayElementPositionSyncData pos : positions) {
						buffer.writeUtf(pos.id());
						buffer.writeInt(pos.x());
						buffer.writeInt(pos.y());
					}

					List<CustomOverlayEntrySyncData> entries = payload.customEntries() == null ? List.of() : payload.customEntries();
					buffer.writeInt(entries.size());
					for (CustomOverlayEntrySyncData entry : entries) {
						buffer.writeUtf(entry.id());
						buffer.writeUtf(entry.type());
						buffer.writeUtf(entry.label());
						buffer.writeUtf(entry.value());
						buffer.writeUtf(entry.max());
						buffer.writeInt(entry.x());
						buffer.writeInt(entry.y());
						buffer.writeInt(entry.width());
						buffer.writeInt(entry.height());
						buffer.writeUtf(entry.texture());
					}
				}
			};

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(SyncPartyPayload payload, IPayloadContext context) {
			context.enqueueWork(() -> ${package}.client.PartyApiClient.acceptSync(payload));
		}
	}

	public record OpenPartyScreenPayload(String screen) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<OpenPartyScreenPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_open_screen_v3"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, OpenPartyScreenPayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public OpenPartyScreenPayload decode(RegistryFriendlyByteBuf buffer) {
					return new OpenPartyScreenPayload(buffer.readUtf());
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, OpenPartyScreenPayload payload) {
					buffer.writeUtf(payload.screen() == null ? "MAIN" : payload.screen());
				}
			};

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(OpenPartyScreenPayload payload, IPayloadContext context) {
			context.enqueueWork(() -> ${package}.client.PartyApiClient.openPartyScreen(payload.screen()));
		}
	}

	public record OpenPartyInvitePayload(String inviterName) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<OpenPartyInvitePayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_open_invite_v3"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, OpenPartyInvitePayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public OpenPartyInvitePayload decode(RegistryFriendlyByteBuf buffer) {
					return new OpenPartyInvitePayload(buffer.readUtf());
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, OpenPartyInvitePayload payload) {
					buffer.writeUtf(payload.inviterName() == null ? "Unknown" : payload.inviterName());
				}
			};

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(OpenPartyInvitePayload payload, IPayloadContext context) {
			context.enqueueWork(() -> ${package}.client.PartyApiClient.openPartyInviteScreen(payload.inviterName()));
		}
	}

	public record OnlinePlayerListPayload(List<OnlinePlayerSyncData> players) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<OnlinePlayerListPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_online_players_v3"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, OnlinePlayerListPayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public OnlinePlayerListPayload decode(RegistryFriendlyByteBuf buffer) {
					int count = Math.max(0, buffer.readInt());
					List<OnlinePlayerSyncData> players = new ArrayList<>();

					for (int i = 0; i < count; i++) {
						players.add(new OnlinePlayerSyncData(
							buffer.readUtf(),
							buffer.readUtf(),
							buffer.readBoolean(),
							buffer.readBoolean(),
							buffer.readUtf(),
							buffer.readUtf(),
							buffer.readUtf(),
							buffer.readInt(),
							buffer.readInt(),
							buffer.readBoolean()
						));
					}

					return new OnlinePlayerListPayload(players);
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, OnlinePlayerListPayload payload) {
					List<OnlinePlayerSyncData> players = payload.players() == null ? List.of() : payload.players();
					buffer.writeInt(players.size());

					for (OnlinePlayerSyncData player : players) {
						buffer.writeUtf(player.uuid());
						buffer.writeUtf(player.name());
						buffer.writeBoolean(player.inMyParty());
						buffer.writeBoolean(player.pendingInvite());
						buffer.writeUtf(player.partyId());
						buffer.writeUtf(player.leaderId());
						buffer.writeUtf(player.leaderName());
						buffer.writeInt(player.partySize());
						buffer.writeInt(player.partyMaxMembers());
						buffer.writeBoolean(player.partyLeader());
					}
				}
			};

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(OnlinePlayerListPayload payload, IPayloadContext context) {
			context.enqueueWork(() -> ${package}.client.PartyApiClient.acceptOnlinePlayers(payload.players()));
		}
	}

	public record PartyActionPayload(String action, String targetId, String value) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<PartyActionPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_action_v3"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, PartyActionPayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public PartyActionPayload decode(RegistryFriendlyByteBuf buffer) {
					return new PartyActionPayload(buffer.readUtf(), buffer.readUtf(), buffer.readUtf());
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, PartyActionPayload payload) {
					buffer.writeUtf(payload.action() == null ? "" : payload.action());
					buffer.writeUtf(payload.targetId() == null ? "" : payload.targetId());
					buffer.writeUtf(payload.value() == null ? "" : payload.value());
				}
			};

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleServer(PartyActionPayload payload, IPayloadContext context) {
			context.enqueueWork(() -> {
				if (context.player() instanceof ServerPlayer serverPlayer) {
					${package}.party.PartyApiSystem.handleClientAction(serverPlayer, payload.action(), payload.targetId(), payload.value());
				}
			});
		}
	}
}
