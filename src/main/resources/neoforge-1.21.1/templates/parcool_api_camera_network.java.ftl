package ${package}.network;

import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.api.distmarker.Dist;
import net.neoforged.api.distmarker.OnlyIn;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.network.PacketDistributor;
import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;
import net.neoforged.neoforge.network.registration.PayloadRegistrar;
import net.neoforged.neoforge.network.handling.IPayloadContext;

@EventBusSubscriber(modid = "${modid}", bus = EventBusSubscriber.Bus.MOD)
public final class ParCoolApiCameraNetwork {
	private static final String NETWORK_VERSION = "2";

	private ParCoolApiCameraNetwork() {
	}

	@SubscribeEvent
	public static void registerPayloads(RegisterPayloadHandlersEvent event) {
		PayloadRegistrar registrar = event.registrar(NETWORK_VERSION);

		registrar.playToClient(
			SetCameraPerspectivePayload.TYPE,
			SetCameraPerspectivePayload.STREAM_CODEC,
			SetCameraPerspectivePayload::handleClient
		);

		registrar.playToClient(
			RequestParCoolClientHandshakePayload.TYPE,
			RequestParCoolClientHandshakePayload.STREAM_CODEC,
			RequestParCoolClientHandshakePayload::handleClient
		);
	}

	public static void sendToPlayer(ServerPlayer player, String perspectiveName) {
		sendToPlayer(player, perspectiveName, 0);
	}

	public static void sendToPlayer(ServerPlayer player, String perspectiveName, int delayTicks) {
		if (player == null) {
			return;
		}

		String normalized = normalizePerspectiveName(perspectiveName);
		int safeDelayTicks = Math.max(0, delayTicks);

		${package}.events.ParCoolApiBridgeEvents.fireCameraPerspectiveRequested(player, perspectiveNameToId(normalized));
		PacketDistributor.sendToPlayer(player, new SetCameraPerspectivePayload(normalized, safeDelayTicks));
	}

	public static void requestParCoolClientHandshake(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			PacketDistributor.sendToPlayer(player, RequestParCoolClientHandshakePayload.INSTANCE);
		} catch (Throwable ignored) {
		}
	}

	private static String normalizePerspectiveName(String perspectiveName) {
		if (perspectiveName == null) {
			return "FIRST_PERSON";
		}

		return switch (perspectiveName.trim().toUpperCase(java.util.Locale.ROOT)) {
			case "THIRD_PERSON_BACK", "BACK", "THIRD_BACK", "THIRD_PERSON" -> "THIRD_PERSON_BACK";
			case "THIRD_PERSON_FRONT", "FRONT", "THIRD_FRONT" -> "THIRD_PERSON_FRONT";
			default -> "FIRST_PERSON";
		};
	}

	private static int perspectiveNameToId(String perspectiveName) {
		return switch (normalizePerspectiveName(perspectiveName)) {
			case "THIRD_PERSON_BACK" -> ${package}.events.ParCoolApiBridgeEvents.CAMERA_THIRD_PERSON_BACK;
			case "THIRD_PERSON_FRONT" -> ${package}.events.ParCoolApiBridgeEvents.CAMERA_THIRD_PERSON_FRONT;
			default -> ${package}.events.ParCoolApiBridgeEvents.CAMERA_FIRST_PERSON;
		};
	}

	public record SetCameraPerspectivePayload(String perspectiveName, int delayTicks) implements CustomPacketPayload {
		public static final CustomPacketPayload.Type<SetCameraPerspectivePayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "parcool_api_camera_perspective"));

		public static final StreamCodec<RegistryFriendlyByteBuf, SetCameraPerspectivePayload> STREAM_CODEC = StreamCodec.composite(
			ByteBufCodecs.STRING_UTF8,
			SetCameraPerspectivePayload::perspectiveName,
			ByteBufCodecs.INT,
			SetCameraPerspectivePayload::delayTicks,
			SetCameraPerspectivePayload::new
		);

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(SetCameraPerspectivePayload payload, IPayloadContext context) {
			context.enqueueWork(() -> {
				int safeDelayTicks = Math.max(0, payload.delayTicks());

				${package}.client.ParCoolApiClientScheduler.requestParCoolClientHandshakeBurst();

				if (safeDelayTicks <= 0) {
					ClientCameraPerspectiveHandler.apply(payload.perspectiveName());
				} else {
					${package}.client.ParCoolApiClientScheduler.queueClientWork(
						safeDelayTicks,
						() -> ClientCameraPerspectiveHandler.apply(payload.perspectiveName())
					);
				}
			});
		}
	}

	public enum RequestParCoolClientHandshakePayload implements CustomPacketPayload {
		INSTANCE;

		public static final CustomPacketPayload.Type<RequestParCoolClientHandshakePayload> TYPE =
			new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("${modid}", "parcool_api_request_client_handshake"));

		public static final StreamCodec<RegistryFriendlyByteBuf, RequestParCoolClientHandshakePayload> STREAM_CODEC =
			StreamCodec.unit(INSTANCE);

		@Override
		public CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
			return TYPE;
		}

		private static void handleClient(RequestParCoolClientHandshakePayload payload, IPayloadContext context) {
			context.enqueueWork(${package}.client.ParCoolApiClientScheduler::requestParCoolClientHandshakeBurst);
		}
	}

	@OnlyIn(Dist.CLIENT)
	private static final class ClientCameraPerspectiveHandler {
		private ClientCameraPerspectiveHandler() {
		}

		private static void apply(String perspectiveName) {
			net.minecraft.client.Minecraft minecraft = net.minecraft.client.Minecraft.getInstance();

			if (minecraft == null || minecraft.options == null) {
				return;
			}

			net.minecraft.client.CameraType cameraType = switch (normalizePerspectiveName(perspectiveName)) {
				case "THIRD_PERSON_BACK" -> net.minecraft.client.CameraType.THIRD_PERSON_BACK;
				case "THIRD_PERSON_FRONT" -> net.minecraft.client.CameraType.THIRD_PERSON_FRONT;
				default -> net.minecraft.client.CameraType.FIRST_PERSON;
			};

			minecraft.options.setCameraType(cameraType);
		}
	}
}