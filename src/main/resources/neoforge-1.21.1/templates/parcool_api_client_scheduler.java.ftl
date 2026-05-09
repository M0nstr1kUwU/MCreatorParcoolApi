package ${package}.client;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.UUID;

import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.loading.FMLEnvironment;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.ClientTickEvent;

public final class ParCoolApiClientScheduler {
	private static final List<ScheduledClientTask> TASKS = new ArrayList<>();

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

	@EventBusSubscriber(Dist.CLIENT)
	private static final class ClientTickHandler {
		private ClientTickHandler() {
		}

		@SubscribeEvent
		public static void onClientTick(ClientTickEvent.Post event) {
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