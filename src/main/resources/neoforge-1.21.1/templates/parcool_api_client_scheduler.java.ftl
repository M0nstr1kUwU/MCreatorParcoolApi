package ${package}.client;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.UUID;

import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.loading.FMLEnvironment;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.ClientPlayerNetworkEvent;
import net.neoforged.neoforge.client.event.ClientTickEvent;
import net.neoforged.neoforge.network.PacketDistributor;

public final class ParCoolApiClientScheduler {
	private static final List<ScheduledClientTask> TASKS = new ArrayList<>();

	private static UUID lastHandshakePlayerId = null;
	private static int clientHandshakeTicks = -1;

	private ParCoolApiClientScheduler() {
	}

	public static void queueClientWork(int ticks, Runnable task) {
		if (FMLEnvironment.dist != Dist.CLIENT || task == null) {
			return;
		}

		synchronized (TASKS) {
			TASKS.add(new ScheduledClientTask(null, Math.max(0, ticks), task));
		}
	}

	public static void queueClientWorkForLocalPlayer(UUID expectedPlayerId, int ticks, Runnable task) {
		if (FMLEnvironment.dist != Dist.CLIENT || task == null) {
			return;
		}

		synchronized (TASKS) {
			TASKS.add(new ScheduledClientTask(expectedPlayerId, Math.max(0, ticks), task));
		}
	}

	public static void requestParCoolClientHandshakeBurst() {
		if (FMLEnvironment.dist != Dist.CLIENT) {
			return;
		}

		try {
			net.minecraft.client.Minecraft minecraft = net.minecraft.client.Minecraft.getInstance();

			if (minecraft != null && minecraft.player != null) {
				lastHandshakePlayerId = minecraft.player.getUUID();
				clientHandshakeTicks = 0;
			}
		} catch (Throwable ignored) {
		}
	}

	@EventBusSubscriber(Dist.CLIENT)
	private static final class ClientEventHandler {
		private ClientEventHandler() {
		}

		@SubscribeEvent
		public static void onClientLogin(ClientPlayerNetworkEvent.LoggingIn event) {
			try {
				if (event.getPlayer() != null) {
					lastHandshakePlayerId = event.getPlayer().getUUID();
					clientHandshakeTicks = 0;
				}
			} catch (Throwable ignored) {
			}
		}

		@SubscribeEvent
		public static void onClientLogout(ClientPlayerNetworkEvent.LoggingOut event) {
			lastHandshakePlayerId = null;
			clientHandshakeTicks = -1;

			synchronized (TASKS) {
				TASKS.clear();
			}
		}

		@SubscribeEvent
		public static void onClientTick(ClientTickEvent.Post event) {
			runClientHandshakeIfNeeded();
			runQueuedClientTasks();
		}

		private static void runClientHandshakeIfNeeded() {
			if (clientHandshakeTicks < 0) {
				return;
			}

			try {
				net.minecraft.client.Minecraft minecraft = net.minecraft.client.Minecraft.getInstance();

				if (minecraft == null || minecraft.player == null || minecraft.level == null) {
					return;
				}

				UUID currentPlayerId = minecraft.player.getUUID();

				if (lastHandshakePlayerId == null || !lastHandshakePlayerId.equals(currentPlayerId)) {
					lastHandshakePlayerId = currentPlayerId;
					clientHandshakeTicks = 0;
				}

				if (clientHandshakeTicks == 0
						|| clientHandshakeTicks == 5
						|| clientHandshakeTicks == 20
						|| clientHandshakeTicks == 40
						|| clientHandshakeTicks == 80
						|| clientHandshakeTicks == 120
						|| clientHandshakeTicks == 200) {
					sendParCoolClientInformation(minecraft.player);
				}

				clientHandshakeTicks++;

				if (clientHandshakeTicks > 220) {
					clientHandshakeTicks = -1;
				}
			} catch (Throwable ignored) {
				clientHandshakeTicks = -1;
			}
		}

		private static void sendParCoolClientInformation(net.minecraft.client.player.LocalPlayer player) {
			if (player == null) {
				return;
			}

			try {
				if (!${package}.parcool.ParCoolApiRuntime.isClientInformationPayloadAvailable()) {
					return;
				}

				PacketDistributor.sendToServer(
					new com.alrex.parcool.common.network.payload.ClientInformationPayload(
						player.getUUID(),
						true,
						com.alrex.parcool.common.info.ClientSetting.readFromLocalConfig()
					)
				);
			} catch (Throwable ignored) {
			}
		}

		private static void runQueuedClientTasks() {
			List<Runnable> tasksToRun = new ArrayList<>();

			synchronized (TASKS) {
				Iterator<ScheduledClientTask> iterator = TASKS.iterator();

				while (iterator.hasNext()) {
					ScheduledClientTask scheduledTask = iterator.next();

					if (!scheduledTask.isForCurrentLocalPlayer()) {
						iterator.remove();
						continue;
					}

					if (scheduledTask.remainingTicks-- <= 0) {
						tasksToRun.add(scheduledTask.task);
						iterator.remove();
					}
				}
			}

			for (Runnable task : tasksToRun) {
				try {
					task.run();

					try {
						net.minecraft.client.Minecraft minecraft = net.minecraft.client.Minecraft.getInstance();

						if (minecraft != null && minecraft.player != null) {
							${package}.events.ParCoolApiBridgeEvents.fireClientWaitFinished(minecraft.player);
						}
					} catch (Throwable ignoredEvent) {
					}
				} catch (Throwable ignored) {
				}
			}
		}
	}

	private static final class ScheduledClientTask {
		private final UUID expectedPlayerId;
		private int remainingTicks;
		private final Runnable task;

		private ScheduledClientTask(UUID expectedPlayerId, int remainingTicks, Runnable task) {
			this.expectedPlayerId = expectedPlayerId;
			this.remainingTicks = remainingTicks;
			this.task = task;
		}

		private boolean isForCurrentLocalPlayer() {
			if (expectedPlayerId == null) {
				return true;
			}

			try {
				net.minecraft.client.Minecraft minecraft = net.minecraft.client.Minecraft.getInstance();

				return minecraft != null
					&& minecraft.player != null
					&& expectedPlayerId.equals(minecraft.player.getUUID());
			} catch (Throwable ignored) {
				return false;
			}
		}
	}
}