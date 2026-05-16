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
	private static final String NETWORK_VERSION = "1";

	private PartyApiNetwork() {
	}

	@SubscribeEvent
	public static void registerPayloads(RegisterPayloadHandlersEvent event) {
		PayloadRegistrar registrar = event.registrar(NETWORK_VERSION);

		registrar.playToClient(
			SyncPartyPayload.TYPE,
			SyncPartyPayload.STREAM_CODEC,
			SyncPartyPayload::handleClient
		);

		registrar.playToClient(
			OpenPartyScreenPayload.TYPE,
			OpenPartyScreenPayload.STREAM_CODEC,
			OpenPartyScreenPayload::handleClient
		);

		registrar.playToServer(
			PartyActionPayload.TYPE,
			PartyActionPayload.STREAM_CODEC,
			PartyActionPayload::handleServer
		);
	}

	public static void syncParty(ServerPlayer player, String partyId, String leaderId, boolean pvpEnabled, String overlayPosition, List<MemberSyncData> members) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new SyncPartyPayload(partyId, leaderId, pvpEnabled, overlayPosition, members));
		} catch (Throwable ignored) {
		}
	}

	public static void sendEmptyParty(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, new SyncPartyPayload("", "", false, "LEFT_CENTER", List.of()));
		} catch (Throwable ignored) {
		}
	}

	public static void openPartyScreen(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, OpenPartyScreenPayload.INSTANCE);
		} catch (Throwable ignored) {
		}
	}

	public static void sendClientAction(String action, String targetId, String value) {
		try {
			PacketDistributor.sendToServer(new PartyActionPayload(
				action == null ? "" : action,
				targetId == null ? "" : targetId,
				value == null ? "" : value
			));
		} catch (Throwable ignored) {
		}
	}

	public record MemberSyncData(
		String uuid,
		String name,
		float health,
		float maxHealth,
		float absorption,
		int food,
		float saturation,
		boolean leader,
		boolean pinned,
		Map<String, String> stats
	) {
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

	public record SyncPartyPayload(
		String partyId,
		String leaderId,
		boolean pvpEnabled,
		String overlayPosition,
		List<MemberSyncData> members
	) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<SyncPartyPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_sync"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, SyncPartyPayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public SyncPartyPayload decode(RegistryFriendlyByteBuf buffer) {
					String partyId = buffer.readUtf();
					String leaderId = buffer.readUtf();
					boolean pvp = buffer.readBoolean();
					String position = buffer.readUtf();

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

						members.add(new MemberSyncData(
							uuid,
							name,
							health,
							maxHealth,
							absorption,
							food,
							saturation,
							leader,
							pinned,
							stats
						));
					}

					return new SyncPartyPayload(partyId, leaderId, pvp, position, members);
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, SyncPartyPayload payload) {
					buffer.writeUtf(payload.partyId() == null ? "" : payload.partyId());
					buffer.writeUtf(payload.leaderId() == null ? "" : payload.leaderId());
					buffer.writeBoolean(payload.pvpEnabled());
					buffer.writeUtf(payload.overlayPosition() == null ? "LEFT_CENTER" : payload.overlayPosition());

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

	public enum OpenPartyScreenPayload implements CustomPacketPayload {
		INSTANCE;

		public static final CustomPacketPayload.Type<OpenPartyScreenPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_open_screen"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, OpenPartyScreenPayload> STREAM_CODEC =
			net.minecraft.network.codec.StreamCodec.unit(INSTANCE);

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(OpenPartyScreenPayload payload, IPayloadContext context) {
			context.enqueueWork(${package}.client.PartyApiClient::openPartyScreen);
		}
	}

	public record PartyActionPayload(String action, String targetId, String value) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<PartyActionPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "party_action"));

		public static final net.minecraft.network.codec.StreamCodec<RegistryFriendlyByteBuf, PartyActionPayload> STREAM_CODEC =
			new net.minecraft.network.codec.StreamCodec<>() {
				@Override
				public PartyActionPayload decode(RegistryFriendlyByteBuf buffer) {
					return new PartyActionPayload(
						buffer.readUtf(),
						buffer.readUtf(),
						buffer.readUtf()
					);
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
					${package}.party.PartyApiSystem.handleClientAction(
						serverPlayer,
						payload.action(),
						payload.targetId(),
						payload.value()
					);
				}
			});
		}
	}
}