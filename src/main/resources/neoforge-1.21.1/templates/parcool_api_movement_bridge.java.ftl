package ${package}.parcool;

import java.util.UUID;

import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiMovementBridge {
	private static final com.alrex.parcool.server.limitation.Limitation.ID MCREATOR_BRIDGE_ID =
		new com.alrex.parcool.server.limitation.Limitation.ID("parcool_api", "mcreator_bridge");

	private ParCoolApiMovementBridge() {
	}

	@SubscribeEvent
	public static void onPlayerLoggedIn(net.neoforged.neoforge.event.entity.player.PlayerEvent.PlayerLoggedInEvent event) {
		if (event.getEntity() instanceof ServerPlayer serverPlayer) {
			schedulePermissionBurst(serverPlayer);
		}
	}

	public static void disableSprint(ServerPlayer player) {
		disableAbility(player, ${package}.events.ParCoolApiBridgeEvents.ABILITY_SPRINT,
			com.alrex.parcool.common.action.impl.FastRun.class);
	}

	public static void disableClimb(ServerPlayer player) {
		disableAbility(player, ${package}.events.ParCoolApiBridgeEvents.ABILITY_CLIMB,
			com.alrex.parcool.common.action.impl.ClimbUp.class,
			com.alrex.parcool.common.action.impl.ClimbPoles.class);
	}

	public static void disableJump(ServerPlayer player) {
		disableAbility(player, ${package}.events.ParCoolApiBridgeEvents.ABILITY_JUMP,
			com.alrex.parcool.common.action.impl.ChargeJump.class,
			com.alrex.parcool.common.action.impl.JumpFromBar.class,
			com.alrex.parcool.common.action.impl.WallJump.class);
	}

	public static void disableHang(ServerPlayer player) {
		disableAbility(player, ${package}.events.ParCoolApiBridgeEvents.ABILITY_HANG,
			com.alrex.parcool.common.action.impl.HangDown.class,
			com.alrex.parcool.common.action.impl.ClingToCliff.class);
	}

	public static void disableWallRun(ServerPlayer player) {
		disableAbility(player, ${package}.events.ParCoolApiBridgeEvents.ABILITY_WALL_RUN,
			com.alrex.parcool.common.action.impl.HorizontalWallRun.class,
			com.alrex.parcool.common.action.impl.VerticalWallRun.class,
			com.alrex.parcool.common.action.impl.WallSlide.class,
			com.alrex.parcool.common.action.impl.WallJump.class);
	}

	public static void disableAllMovements(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.server.limitation.Limitation limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(player.getUUID(), MCREATOR_BRIDGE_ID);

			limitation.setAllDefault();
			limitation.setEnabled(true);

			for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : com.alrex.parcool.common.action.Actions.LIST) {
				try {
					limitation.setPossibilityOf(actionClass, false);
					limitation.setLeastStaminaConsumption(actionClass, Integer.MAX_VALUE);
				} catch (Throwable ignoredAction) {
				}
			}

			schedulePermissionBurst(player);

			${package}.events.ParCoolApiBridgeEvents.fireMovementAbilityChanged(
				player,
				${package}.events.ParCoolApiBridgeEvents.ABILITY_ALL_MOVEMENTS,
				false
			);
		} catch (Throwable ignored) {
		}
	}

	public static void enableAllMovements(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.server.limitation.Limitation limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(player.getUUID(), MCREATOR_BRIDGE_ID);

			limitation.setAllDefault();
			limitation.setEnabled(false);

			for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : com.alrex.parcool.common.action.Actions.LIST) {
				try {
					limitation.setPossibilityOf(actionClass, true);
					limitation.setLeastStaminaConsumption(actionClass, 0);
				} catch (Throwable ignoredAction) {
				}
			}

			schedulePermissionBurst(player);

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
				try {
					limitation.setPossibilityOf(actionClass, false);
					limitation.setLeastStaminaConsumption(actionClass, Integer.MAX_VALUE);
				} catch (Throwable ignoredAction) {
				}
			}

			schedulePermissionBurst(player);
			${package}.events.ParCoolApiBridgeEvents.fireMovementAbilityChanged(player, abilityId, false);
		} catch (Throwable ignored) {
		}
	}

	public static void forceSyncPermissions(ServerPlayer player) {
		if (player == null) {
			return;
		}

		schedulePermissionBurst(player);
		${package}.events.ParCoolApiBridgeEvents.firePermissionsForceSynced(player);
	}

	public static void schedulePermissionBurst(ServerPlayer player) {
		if (player == null) {
			return;
		}

		syncParCoolLimitations(player);
		queuePermissionSync(player, 5);
		queuePermissionSync(player, 20);
		queuePermissionSync(player, 40);
		queuePermissionSync(player, 80);
		queuePermissionSync(player, 120);
		queuePermissionSync(player, 200);
	}

	private static void queuePermissionSync(ServerPlayer player, int delayTicks) {
		if (player == null) {
			return;
		}

		MinecraftServer server = player.getServer();

		if (server == null) {
			return;
		}

		UUID playerId = player.getUUID();

		${JavaModName}.queueServerWork(Math.max(0, delayTicks), () -> {
			try {
				ServerPlayer currentPlayer = server.getPlayerList().getPlayer(playerId);

				if (currentPlayer != null) {
					syncParCoolLimitations(currentPlayer);
				}
			} catch (Throwable ignored) {
			}
		});
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