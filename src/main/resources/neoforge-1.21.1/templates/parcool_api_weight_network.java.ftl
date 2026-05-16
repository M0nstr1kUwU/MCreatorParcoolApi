package ${package}.network;

import java.util.UUID;

import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
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
public final class ParCoolApiWeightNetwork {
	private static final String NETWORK_VERSION = "2";

	private ParCoolApiWeightNetwork() {
	}

	@SubscribeEvent
	public static void registerPayloads(RegisterPayloadHandlersEvent event) {
		PayloadRegistrar registrar = event.registrar(NETWORK_VERSION);

		registrar.playToClient(
			SyncPlayerWeightPayload.TYPE,
			SyncPlayerWeightPayload.STREAM_CODEC,
			SyncPlayerWeightPayload::handleClient
		);
	}

	public static void syncToPlayer(ServerPlayer player, double maxWeight, double currentWeight, double loadPercent, int status) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(
				player,
				new SyncPlayerWeightPayload(
					player.getUUID().toString(),
					maxWeight,
					currentWeight,
					loadPercent,
					status
				)
			);
		} catch (Throwable ignored) {
		}
	}

	public record SyncPlayerWeightPayload(
		String playerId,
		double maxWeight,
		double currentWeight,
		double loadPercent,
		int status
	) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<SyncPlayerWeightPayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "parcool_api_weight_sync"));

		public static final StreamCodec<RegistryFriendlyByteBuf, SyncPlayerWeightPayload> STREAM_CODEC =
			new StreamCodec<>() {
				@Override
				public SyncPlayerWeightPayload decode(RegistryFriendlyByteBuf buffer) {
					return new SyncPlayerWeightPayload(
						buffer.readUtf(),
						buffer.readDouble(),
						buffer.readDouble(),
						buffer.readDouble(),
						buffer.readInt()
					);
				}

				@Override
				public void encode(RegistryFriendlyByteBuf buffer, SyncPlayerWeightPayload payload) {
					buffer.writeUtf(payload.playerId());
					buffer.writeDouble(payload.maxWeight());
					buffer.writeDouble(payload.currentWeight());
					buffer.writeDouble(payload.loadPercent());
					buffer.writeInt(payload.status());
				}
			};

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(SyncPlayerWeightPayload payload, IPayloadContext context) {
			context.enqueueWork(() -> {
				try {
					UUID uuid = UUID.fromString(payload.playerId());

					${package}.weight.ParCoolApiWeightSystem.acceptClientSync(
						uuid,
						payload.maxWeight(),
						payload.currentWeight(),
						payload.loadPercent(),
						payload.status()
					);
				} catch (Throwable ignored) {
				}
			});
		}
	}
}