package ${package}.parcool;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.server.level.ServerPlayer;

public final class ParCoolApiStaminaMonitor {
	private static final Map<UUID, Boolean> EMPTY_UNTIL_FULL_ACTIVE = new ConcurrentHashMap<>();

	private ParCoolApiStaminaMonitor() {
	}

	public static boolean shouldRunEmptyUntilFull(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		try {
			int value = ${package}.parcool.ParCoolApiStaminaBridge.getStamina(player);
			int max = Math.max(1, ${package}.parcool.ParCoolApiStaminaBridge.getMaxStamina(player));

			UUID playerId = player.getUUID();
			boolean active = EMPTY_UNTIL_FULL_ACTIVE.getOrDefault(playerId, false);

			if (!active && value <= 0) {
				EMPTY_UNTIL_FULL_ACTIVE.put(playerId, true);
				return true;
			}

			if (active && value >= max) {
				EMPTY_UNTIL_FULL_ACTIVE.put(playerId, false);
				return false;
			}

			return active && value < max;
		} catch (Throwable ignored) {
			return false;
		}
	}

	public static boolean isActive(ServerPlayer player) {
		return player != null && EMPTY_UNTIL_FULL_ACTIVE.getOrDefault(player.getUUID(), false);
	}

	public static void reset(ServerPlayer player) {
		if (player != null) {
			EMPTY_UNTIL_FULL_ACTIVE.remove(player.getUUID());
		}
	}
}