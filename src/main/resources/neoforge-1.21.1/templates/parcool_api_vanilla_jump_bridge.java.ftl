package ${package}.parcool;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.Attributes;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.tick.PlayerTickEvent;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiVanillaJumpBridge {
	private static final ResourceLocation VANILLA_JUMP_DISABLED_MODIFIER_ID =
		ResourceLocation.fromNamespaceAndPath("${modid}", "parcool_api_vanilla_jump_disabled");

	private static final String TAG_VANILLA_JUMP_DISABLED = "ParCoolApi_VanillaJumpDisabled";
	private static final String TAG_WAS_ON_GROUND = "ParCoolApi_VanillaJumpWasOnGround";

	private static final Map<UUID, Boolean> DISABLED_PLAYERS = new ConcurrentHashMap<>();

	private ParCoolApiVanillaJumpBridge() {
	}

	public static void setVanillaJumpDisabled(ServerPlayer player, boolean disabled) {
		if (player == null) {
			return;
		}

		DISABLED_PLAYERS.put(player.getUUID(), disabled);
		player.getPersistentData().putBoolean(TAG_VANILLA_JUMP_DISABLED, disabled);

		if (disabled) {
			applyJumpStrengthBlock(player);
		} else {
			removeJumpStrengthBlock(player);
		}
	}

	public static boolean isVanillaJumpDisabled(ServerPlayer player) {
		if (player == null) {
			return false;
		}

		UUID uuid = player.getUUID();

		if (DISABLED_PLAYERS.containsKey(uuid)) {
			return DISABLED_PLAYERS.get(uuid);
		}

		boolean disabled = player.getPersistentData().getBoolean(TAG_VANILLA_JUMP_DISABLED);
		DISABLED_PLAYERS.put(uuid, disabled);
		return disabled;
	}

	private static void applyJumpStrengthBlock(ServerPlayer player) {
		try {
			AttributeInstance attribute = player.getAttribute(Attributes.JUMP_STRENGTH);

			if (attribute != null) {
				attribute.removeModifier(VANILLA_JUMP_DISABLED_MODIFIER_ID);
				attribute.addOrUpdateTransientModifier(
					new AttributeModifier(
						VANILLA_JUMP_DISABLED_MODIFIER_ID,
						-1.0D,
						AttributeModifier.Operation.ADD_MULTIPLIED_TOTAL
					)
				);
			}
		} catch (Throwable ignored) {
		}
	}

	private static void removeJumpStrengthBlock(ServerPlayer player) {
		try {
			AttributeInstance attribute = player.getAttribute(Attributes.JUMP_STRENGTH);

			if (attribute != null) {
				attribute.removeModifier(VANILLA_JUMP_DISABLED_MODIFIER_ID);
			}
		} catch (Throwable ignored) {
		}
	}

	@SubscribeEvent
	public static void onPlayerTick(PlayerTickEvent.Post event) {
		if (!(event.getEntity() instanceof ServerPlayer player)) {
			return;
		}

		if (!isVanillaJumpDisabled(player)) {
			player.getPersistentData().putBoolean(TAG_WAS_ON_GROUND, player.onGround());
			return;
		}

		applyJumpStrengthBlock(player);

		boolean wasOnGround = player.getPersistentData().getBoolean(TAG_WAS_ON_GROUND);
		boolean isOnGround = player.onGround();

		if (wasOnGround && !isOnGround && player.getDeltaMovement().y > 0.0D) {
			player.setDeltaMovement(player.getDeltaMovement().x, 0.0D, player.getDeltaMovement().z);
			player.hurtMarked = true;
		}

		player.getPersistentData().putBoolean(TAG_WAS_ON_GROUND, isOnGround);
	}
}