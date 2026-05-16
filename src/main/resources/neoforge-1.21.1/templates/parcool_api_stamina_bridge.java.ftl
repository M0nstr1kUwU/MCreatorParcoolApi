package ${package}.parcool;

import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.player.Player;

public final class ParCoolApiStaminaBridge {
	private ParCoolApiStaminaBridge() {
	}

	public static int getStamina(Player player) {
		if (player == null) {
			return 0;
		}

		try {
			return Math.max(0, com.alrex.parcool.api.Stamina.get(player).getValue());
		} catch (Throwable ignored) {
			return 0;
		}
	}

	public static int getMaxStamina(Player player) {
		if (player == null) {
			return 0;
		}

		try {
			return Math.max(0, com.alrex.parcool.api.Stamina.get(player).getMaxValue());
		} catch (Throwable ignored) {
			return 0;
		}
	}

	public static boolean isExhausted(Player player) {
		if (player == null) {
			return false;
		}

		try {
			return com.alrex.parcool.api.Stamina.get(player).isExhausted();
		} catch (Throwable ignored) {
			return false;
		}
	}

	public static double getStaminaPercent(Player player, double decimalsRaw) {
		if (player == null) {
			return 0.0D;
		}

		try {
			int current = getStamina(player);
			int max = getMaxStamina(player);

			if (max <= 0) {
				return 0.0D;
			}

			int decimals = (int) Math.max(0, Math.min(10, Math.round(decimalsRaw)));
			double scale = Math.pow(10.0D, decimals);
			double percent = ((double) current / (double) max) * 100.0D;

			return Math.round(percent * scale) / scale;
		} catch (Throwable ignored) {
			return 0.0D;
		}
	}

	public static void addStamina(ServerPlayer player, double amountRaw) {
		if (player == null) {
			return;
		}

		try {
			int amount = Math.max(0, (int) Math.round(amountRaw));

			if (amount > 0) {
				com.alrex.parcool.api.Stamina.get(player).recover(amount);
			}
		} catch (Throwable ignored) {
		}
	}

	public static void consumeStamina(ServerPlayer player, double amountRaw) {
		if (player == null) {
			return;
		}

		try {
			int amount = Math.max(0, (int) Math.round(amountRaw));

			if (amount > 0) {
				com.alrex.parcool.api.Stamina.get(player).consume(amount);
			}
		} catch (Throwable ignored) {
		}
	}

	public static void setStamina(ServerPlayer player, double valueRaw) {
		if (player == null) {
			return;
		}

		try {
			int max = Math.max(0, getMaxStamina(player));
			int target = Math.max(0, (int) Math.round(valueRaw));

			if (max > 0) {
				target = Math.min(target, max);
			}

			int current = getStamina(player);
			int delta = target - current;

			if (delta > 0) {
				com.alrex.parcool.api.Stamina.get(player).recover(delta);
			} else if (delta < 0) {
				com.alrex.parcool.api.Stamina.get(player).consume(-delta);
			}
		} catch (Throwable ignored) {
		}
	}

	public static void setMaxStamina(ServerPlayer player, double valueRaw) {
		if (player == null) {
			return;
		}

		try {
			double safeValue = Math.max(1.0D, Math.min(2147483647.0D, valueRaw));

			AttributeInstance attribute = player.getAttribute(com.alrex.parcool.api.Attributes.MAX_STAMINA);

			if (attribute != null) {
				attribute.setBaseValue(safeValue);
			}

			int current = getStamina(player);
			int newMax = Math.max(1, (int) Math.round(safeValue));

			if (current > newMax) {
				setStamina(player, newMax);
			}
		} catch (Throwable ignored) {
		}
	}

	public static double getStaminaRecovery(ServerPlayer player) {
		if (player == null) {
			return 0.0D;
		}

		try {
			AttributeInstance attribute = player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY);

			return attribute != null ? attribute.getValue() : 0.0D;
		} catch (Throwable ignored) {
			return 0.0D;
		}
	}

	public static void setStaminaRecovery(ServerPlayer player, double valueRaw) {
		if (player == null) {
			return;
		}

		try {
			double safeValue = Math.max(0.0D, Math.min(2147483647.0D, valueRaw));

			AttributeInstance attribute = player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY);

			if (attribute != null) {
				attribute.setBaseValue(safeValue);
			}
		} catch (Throwable ignored) {
		}
	}
}