package ${package}.parcool;

import net.minecraft.server.level.ServerPlayer;

public final class ParCoolApiMovementBridge {
	private static final com.alrex.parcool.server.limitation.Limitation.ID MCREATOR_BRIDGE_ID =
		new com.alrex.parcool.server.limitation.Limitation.ID("parcool_api", "mcreator_bridge");

	private ParCoolApiMovementBridge() {
	}

	public static void disableSprint(ServerPlayer player) {
		disableAbility(
			player,
			${package}.events.ParCoolApiBridgeEvents.ABILITY_SPRINT,
			com.alrex.parcool.common.action.impl.FastRun.class
		);
	}

	public static void disableClimb(ServerPlayer player) {
		disableAbility(
			player,
			${package}.events.ParCoolApiBridgeEvents.ABILITY_CLIMB,
			com.alrex.parcool.common.action.impl.ClimbUp.class,
			com.alrex.parcool.common.action.impl.ClimbPoles.class
		);
	}

	public static void disableJump(ServerPlayer player) {
		disableAbility(
			player,
			${package}.events.ParCoolApiBridgeEvents.ABILITY_JUMP,
			com.alrex.parcool.common.action.impl.ChargeJump.class,
			com.alrex.parcool.common.action.impl.JumpFromBar.class
		);
	}

	public static void disableHang(ServerPlayer player) {
		disableAbility(
			player,
			${package}.events.ParCoolApiBridgeEvents.ABILITY_HANG,
			com.alrex.parcool.common.action.impl.HangDown.class,
			com.alrex.parcool.common.action.impl.ClingToCliff.class
		);
	}

	public static void disableWallRun(ServerPlayer player) {
		disableAbility(
			player,
			${package}.events.ParCoolApiBridgeEvents.ABILITY_WALL_RUN,
			com.alrex.parcool.common.action.impl.HorizontalWallRun.class,
			com.alrex.parcool.common.action.impl.VerticalWallRun.class
		);
	}

	public static void disableAllMovements(ServerPlayer player) {
		disableAbility(
			player,
			${package}.events.ParCoolApiBridgeEvents.ABILITY_ALL_MOVEMENTS,
			com.alrex.parcool.common.action.impl.FastRun.class,
			com.alrex.parcool.common.action.impl.ClimbUp.class,
			com.alrex.parcool.common.action.impl.ClimbPoles.class,
			com.alrex.parcool.common.action.impl.ChargeJump.class,
			com.alrex.parcool.common.action.impl.JumpFromBar.class,
			com.alrex.parcool.common.action.impl.HangDown.class,
			com.alrex.parcool.common.action.impl.ClingToCliff.class,
			com.alrex.parcool.common.action.impl.HorizontalWallRun.class,
			com.alrex.parcool.common.action.impl.VerticalWallRun.class
		);
	}

	public static void enableAllMovements(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.server.limitation.Limitation limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(player.getUUID(), MCREATOR_BRIDGE_ID);

			limitation.setEnabled(false);

			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.FastRun.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClimbUp.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClimbPoles.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ChargeJump.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.JumpFromBar.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.HangDown.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClingToCliff.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.HorizontalWallRun.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.VerticalWallRun.class, true);

			syncParCoolLimitations(player);
			${package}.events.ParCoolApiBridgeEvents.fireMovementAbilityChanged(
				player,
				${package}.events.ParCoolApiBridgeEvents.ABILITY_ALL_MOVEMENTS,
				true
			);
		} catch (Throwable ignored) {
		}
	}

	@SafeVarargs
	private static void disableAbility(ServerPlayer player, int abilityId, Class<? extends com.alrex.parcool.common.action.Action>... actionClasses) {
		if (player == null || actionClasses == null || actionClasses.length == 0) {
			return;
		}

		try {
			com.alrex.parcool.server.limitation.Limitation limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(player.getUUID(), MCREATOR_BRIDGE_ID);

			limitation.setEnabled(true);

			for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : actionClasses) {
				limitation.setPossibilityOf(actionClass, false);
			}

			syncParCoolLimitations(player);
			${package}.events.ParCoolApiBridgeEvents.fireMovementAbilityChanged(player, abilityId, false);
		} catch (Throwable ignored) {
		}
	}

	public static void forceSyncPermissions(ServerPlayer player) {
		if (player == null) {
			return;
		}

		syncParCoolLimitations(player);
		${package}.events.ParCoolApiBridgeEvents.firePermissionsForceSynced(player);
	}

	public static void syncParCoolLimitations(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			Class<?> limitationsClass = Class.forName("com.alrex.parcool.server.limitation.Limitations");

			try {
				limitationsClass
					.getMethod("updateOnlyLimitation", ServerPlayer.class)
					.invoke(null, player);
			} catch (NoSuchMethodException missingUpdateOnlyLimitation) {
				limitationsClass
					.getMethod("update", ServerPlayer.class)
					.invoke(null, player);
			}
		} catch (Throwable ignored) {
		}
	}
}