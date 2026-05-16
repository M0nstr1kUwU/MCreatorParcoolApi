package ${package}.parcool;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.storage.LevelResource;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiMovementBridge {
	private static final com.alrex.parcool.api.unstable.Limitation.ID MCREATOR_BRIDGE_ID =
		new com.alrex.parcool.api.unstable.Limitation.ID("parcool_api", "mcreator_bridge");

	private ParCoolApiMovementBridge() {
	}

	@SubscribeEvent
    public static void onPlayerLoggedIn(net.neoforged.neoforge.event.entity.player.PlayerEvent.PlayerLoggedInEvent event) {
    	if (event.getEntity() instanceof ServerPlayer serverPlayer) {
    		cleanupCorruptedBridgeLimitationFile(serverPlayer);
    		schedulePermissionBurst(serverPlayer);

    		try {
    			${package}.network.ParCoolApiCameraNetwork.requestParCoolClientHandshake(serverPlayer);
    		} catch (Throwable ignored) {
    		}
    	}
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
			com.alrex.parcool.common.action.impl.JumpFromBar.class,
			com.alrex.parcool.common.action.impl.WallJump.class
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
			com.alrex.parcool.common.action.impl.VerticalWallRun.class,
			com.alrex.parcool.common.action.impl.WallSlide.class,
			com.alrex.parcool.common.action.impl.WallJump.class
		);
	}

	public static void disableAllMovements(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.api.unstable.Limitation limitation =
				com.alrex.parcool.api.unstable.Limitation.get(player, MCREATOR_BRIDGE_ID);

			limitation.setDefault();
			limitation.enable();

			for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : com.alrex.parcool.common.action.Actions.LIST) {
				try {
					limitation.permit(actionClass, false);
					limitation.setLeastStaminaConsumption(actionClass, Integer.MAX_VALUE);
				} catch (Throwable ignoredAction) {
				}
			}

			limitation.apply();
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
			com.alrex.parcool.api.unstable.Limitation limitation =
				com.alrex.parcool.api.unstable.Limitation.get(player, MCREATOR_BRIDGE_ID);

			limitation.setDefault();
			limitation.disable();

			for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : com.alrex.parcool.common.action.Actions.LIST) {
				try {
					limitation.permit(actionClass, true);
					limitation.setLeastStaminaConsumption(actionClass, 0);
				} catch (Throwable ignoredAction) {
				}
			}

			limitation.apply();
			deleteBridgeLimitationFile(player);
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
			com.alrex.parcool.api.unstable.Limitation limitation =
				com.alrex.parcool.api.unstable.Limitation.get(player, MCREATOR_BRIDGE_ID);

			limitation.enable();

			for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : actionClasses) {
				try {
					limitation.permit(actionClass, false);
					limitation.setLeastStaminaConsumption(actionClass, Integer.MAX_VALUE);
				} catch (Throwable ignoredAction) {
				}
			}

			limitation.apply();
			schedulePermissionBurst(player);

			${package}.events.ParCoolApiBridgeEvents.fireMovementAbilityChanged(player, abilityId, false);
		} catch (Throwable ignored) {
		}
	}

	public static void forceSyncPermissions(ServerPlayer player) {
    	if (player == null) {
    		return;
    	}

    	cleanupCorruptedBridgeLimitationFile(player);
    	schedulePermissionBurst(player);

    	try {
    		${package}.network.ParCoolApiCameraNetwork.requestParCoolClientHandshake(player);
    	} catch (Throwable ignored) {
    	}

    	${package}.events.ParCoolApiBridgeEvents.firePermissionsForceSynced(player);
    }

	public static void schedulePermissionBurst(ServerPlayer player) {
		if (player == null) {
			return;
		}

		applyCurrentLimitation(player);
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
					applyCurrentLimitation(currentPlayer);
				}
			} catch (Throwable ignored) {
			}
		});
	}

	private static void applyCurrentLimitation(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.api.unstable.Limitation.get(player, MCREATOR_BRIDGE_ID).apply();
		} catch (Throwable ignored) {
		}
	}

	private static void cleanupCorruptedBridgeLimitationFile(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			Path file = getBridgeLimitationFile(player);

			if (file == null || !Files.exists(file)) {
				return;
			}

			String content = Files.readString(file);
			String trimmed = content.trim();

			boolean corrupted =
				trimmed.isEmpty()
					|| trimmed.contains("}on\"")
					|| trimmed.contains("on\":0}]}")
					|| trimmed.indexOf('{') != 0
					|| trimmed.lastIndexOf('}') != trimmed.length() - 1;

			if (corrupted) {
				Files.deleteIfExists(file);
			}
		} catch (Throwable ignored) {
		}
	}

	private static void deleteBridgeLimitationFile(ServerPlayer player) {
		try {
			Path file = getBridgeLimitationFile(player);

			if (file != null) {
				Files.deleteIfExists(file);
			}
		} catch (Throwable ignored) {
		}
	}

	private static Path getBridgeLimitationFile(ServerPlayer player) {
		if (player == null || player.getServer() == null) {
			return null;
		}

		return player.getServer()
			.getWorldPath(new LevelResource("serverconfig"))
			.resolve("parcool")
			.resolve("limitations")
			.resolve(MCREATOR_BRIDGE_ID.getGroup())
			.resolve(MCREATOR_BRIDGE_ID.getName())
			.resolve(player.getUUID().toString() + ".json");
	}
}