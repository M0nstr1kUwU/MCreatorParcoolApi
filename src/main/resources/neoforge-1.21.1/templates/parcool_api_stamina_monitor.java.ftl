package ${package}.parcool;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.world.entity.player.Player;

public final class ParCoolApiStaminaMonitor {
	private static final Map<UUID, Boolean> EMPTY_UNTIL_FULL_ACTIVE = new ConcurrentHashMap<>();

	private ParCoolApiStaminaMonitor() {
	}

	public static boolean shouldRunEmptyUntilFull(Player player) {
		if (player == null) {
			return false;
		}

		try {
			int value = com.alrex.parcool.api.Stamina.get(player).getValue();
			int max = Math.max(1, com.alrex.parcool.api.Stamina.get(player).getMaxValue());

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

	public static void reset(Player player) {
		if (player != null) {
			EMPTY_UNTIL_FULL_ACTIVE.remove(player.getUUID());
		}
	}
}