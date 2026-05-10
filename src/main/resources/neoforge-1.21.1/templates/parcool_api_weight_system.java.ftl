package ${package}.weight;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.tick.PlayerTickEvent;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiWeightSystem {
	private static final Map<ResourceLocation, Double> ITEM_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Double> PLAYER_MAX_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Boolean> PLAYER_AUTO_ENABLED = new ConcurrentHashMap<>();
	private static final Map<UUID, Integer> PLAYER_LAST_STATUS = new ConcurrentHashMap<>();

	private static final String TAG_MAX_CARRY_WEIGHT = "ParCoolApiWeight_MaxCarryWeight";
	private static final String TAG_HAS_AUTO_ENABLED = "ParCoolApiWeight_HasAutoEnabled";
	private static final String TAG_AUTO_ENABLED = "ParCoolApiWeight_AutoEnabled";
	private static final String TAG_LAST_STATUS = "ParCoolApiWeight_LastStatus";

	private static double defaultItemWeight = 1.0D;
	private static double defaultMaxCarryWeight = 64.0D;
	private static int autoUpdateIntervalTicks = 10;

	private ParCoolApiWeightSystem() {
	}

	public static void setDefaultItemWeight(double weight) {
		defaultItemWeight = Math.max(0.0D, weight);
	}

	public static double getDefaultItemWeight() {
		return defaultItemWeight;
	}

	public static void setAllRegisteredItemsWeight(double weight) {
		double safeWeight = Math.max(0.0D, weight);

		for (Item item : BuiltInRegistries.ITEM) {
			ResourceLocation id = BuiltInRegistries.ITEM.getKey(item);

			if (id != null) {
				ITEM_WEIGHTS.put(id, safeWeight);
			}
		}
	}

	public static void setItemWeight(ItemStack stack, double weight) {
		if (stack == null || stack.isEmpty()) {
			return;
		}

		ResourceLocation id = BuiltInRegistries.ITEM.getKey(stack.getItem());

		if (id != null) {
			ITEM_WEIGHTS.put(id, Math.max(0.0D, weight));
		}
	}

	public static void setItemWeightById(String itemId, double weight) {
		ResourceLocation id = parseItemId(itemId);

		if (id != null) {
			ITEM_WEIGHTS.put(id, Math.max(0.0D, weight));
		}
	}

	public static double getUnitWeightById(String itemId) {
		ResourceLocation id = parseItemId(itemId);

		if (id == null) {
			return 0.0D;
		}

		return ITEM_WEIGHTS.getOrDefault(id, defaultItemWeight);
	}

	public static double getStackWeightById(String itemId, int count) {
		return getUnitWeightById(itemId) * Math.max(0, count);
	}

	private static ResourceLocation parseItemId(String itemId) {
		if (itemId == null) {
			return null;
		}

		String normalized = itemId.trim();

		if (normalized.isEmpty()) {
			return null;
		}

		if (!normalized.contains(":")) {
			normalized = "minecraft:" + normalized;
		}

		try {
			return ResourceLocation.tryParse(normalized);
		} catch (Throwable ignored) {
			return null;
		}
	}

	public static double getUnitWeight(ItemStack stack) {
		if (stack == null || stack.isEmpty()) {
			return 0.0D;
		}

		ResourceLocation id = BuiltInRegistries.ITEM.getKey(stack.getItem());

		if (id == null) {
			return defaultItemWeight;
		}

		return ITEM_WEIGHTS.getOrDefault(id, defaultItemWeight);
	}

	public static double getStackWeight(ItemStack stack) {
		if (stack == null || stack.isEmpty()) {
			return 0.0D;
		}

		return getUnitWeight(stack) * Math.max(0, stack.getCount());
	}

	public static double getInventoryWeight(Player player) {
		if (player == null) {
			return 0.0D;
		}

		double total = 0.0D;

		for (ItemStack stack : player.getInventory().items) {
			total += getStackWeight(stack);
		}

		for (ItemStack stack : player.getInventory().armor) {
			total += getStackWeight(stack);
		}

		for (ItemStack stack : player.getInventory().offhand) {
			total += getStackWeight(stack);
		}

		return total;
	}

	public static void setMaxCarryWeight(Player player, double maxWeight) {
		if (player == null) {
			return;
		}

		double safeMaxWeight = Math.max(1.0D, maxWeight);

		PLAYER_MAX_WEIGHTS.put(player.getUUID(), safeMaxWeight);

		CompoundTag tag = player.getPersistentData();
		tag.putDouble(TAG_MAX_CARRY_WEIGHT, safeMaxWeight);
	}

	public static double getMaxCarryWeight(Player player) {
		if (player == null) {
			return defaultMaxCarryWeight;
		}

		UUID uuid = player.getUUID();

		if (PLAYER_MAX_WEIGHTS.containsKey(uuid)) {
			return PLAYER_MAX_WEIGHTS.get(uuid);
		}

		CompoundTag tag = player.getPersistentData();

		if (tag.contains(TAG_MAX_CARRY_WEIGHT)) {
			double stored = Math.max(1.0D, tag.getDouble(TAG_MAX_CARRY_WEIGHT));
			PLAYER_MAX_WEIGHTS.put(uuid, stored);
			return stored;
		}

		return defaultMaxCarryWeight;
	}

	public static void setDefaultMaxCarryWeight(double maxWeight) {
		defaultMaxCarryWeight = Math.max(1.0D, maxWeight);
	}

	public static double getLoadPercent(Player player) {
		double max = getMaxCarryWeight(player);

		if (max <= 0.0D) {
			return 0.0D;
		}

		return getInventoryWeight(player) / max * 100.0D;
	}

	public static boolean isOverloaded(Player player) {
		return getInventoryWeight(player) >= getMaxCarryWeight(player) * 0.75D;
	}

	public static int getWeightStatus(Player player) {
		double max = getMaxCarryWeight(player);

		if (max <= 0.0D) {
			return 0;
		}

		double ratio = getInventoryWeight(player) / max;

		if (ratio >= 2.0D) {
			return 4;
		}

		if (ratio >= 1.75D) {
			return 3;
		}

		if (ratio >= 1.25D) {
			return 2;
		}

		if (ratio >= 0.75D) {
			return 1;
		}

		return 0;
	}

	public static void setAutoEnabled(Player player, boolean enabled) {
		if (player == null) {
			return;
		}

		PLAYER_AUTO_ENABLED.put(player.getUUID(), enabled);

		CompoundTag tag = player.getPersistentData();
		tag.putBoolean(TAG_HAS_AUTO_ENABLED, true);
		tag.putBoolean(TAG_AUTO_ENABLED, enabled);

		if (!enabled && player instanceof ServerPlayer serverPlayer) {
			clearParCoolWeightRestriction(serverPlayer);
			setLastStatus(serverPlayer, 0);
		}
	}

	public static boolean isAutoEnabled(Player player) {
		if (player == null) {
			return false;
		}

		UUID uuid = player.getUUID();

		if (PLAYER_AUTO_ENABLED.containsKey(uuid)) {
			return PLAYER_AUTO_ENABLED.get(uuid);
		}

		CompoundTag tag = player.getPersistentData();

		if (tag.getBoolean(TAG_HAS_AUTO_ENABLED)) {
			boolean stored = tag.getBoolean(TAG_AUTO_ENABLED);
			PLAYER_AUTO_ENABLED.put(uuid, stored);
			return stored;
		}

		return true;
	}

	public static void setAutoUpdateIntervalTicks(int ticks) {
		autoUpdateIntervalTicks = Math.max(1, ticks);
	}

	private static int getLastStatus(Player player) {
		if (player == null) {
			return -1;
		}

		UUID uuid = player.getUUID();

		if (PLAYER_LAST_STATUS.containsKey(uuid)) {
			return PLAYER_LAST_STATUS.get(uuid);
		}

		CompoundTag tag = player.getPersistentData();

		if (tag.contains(TAG_LAST_STATUS)) {
			int stored = tag.getInt(TAG_LAST_STATUS);
			PLAYER_LAST_STATUS.put(uuid, stored);
			return stored;
		}

		return -1;
	}

	private static void setLastStatus(Player player, int status) {
		if (player == null) {
			return;
		}

		PLAYER_LAST_STATUS.put(player.getUUID(), status);
		player.getPersistentData().putInt(TAG_LAST_STATUS, status);
	}

	public static void updatePlayerWeightState(Player player) {
		if (!(player instanceof ServerPlayer serverPlayer)) {
			return;
		}

		int status = getWeightStatus(serverPlayer);
		int oldStatus = getLastStatus(serverPlayer);

		setLastStatus(serverPlayer, status);

		double currentWeight = getInventoryWeight(serverPlayer);
		double maxWeight = getMaxCarryWeight(serverPlayer);
		double loadPercent = getLoadPercent(serverPlayer);

		applyStatusEffects(serverPlayer, status);

		if (status != oldStatus) {
			${package}.events.ParCoolApiBridgeEvents.fireWeightStatusChanged(
				serverPlayer,
				oldStatus,
				status,
				currentWeight,
				maxWeight,
				loadPercent
			);

			applyParCoolWeightRestriction(serverPlayer, status);
		}
	}

	private static void applyStatusEffects(ServerPlayer player, int status) {
		if (status <= 0) {
			return;
		}

		if (status == 1) {
			player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 40, 0, false, false, true));
			return;
		}

		if (status == 2) {
			player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 40, 1, false, false, true));
			player.addEffect(new MobEffectInstance(MobEffects.DIG_SLOWDOWN, 40, 0, false, false, true));
			return;
		}

		if (status == 3) {
			player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 40, 2, false, false, true));
			player.addEffect(new MobEffectInstance(MobEffects.DIG_SLOWDOWN, 40, 1, false, false, true));
			player.addEffect(new MobEffectInstance(MobEffects.WEAKNESS, 40, 0, false, false, true));
			return;
		}

		player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 60, 4, false, false, true));
		player.addEffect(new MobEffectInstance(MobEffects.DIG_SLOWDOWN, 60, 2, false, false, true));
		player.addEffect(new MobEffectInstance(MobEffects.WEAKNESS, 60, 1, false, false, true));
		player.addEffect(new MobEffectInstance(MobEffects.DARKNESS, 80, 0, false, false, true));
	}

	private static void applyParCoolWeightRestriction(ServerPlayer player, int status) {
		if (status <= 1) {
			clearParCoolWeightRestriction(player);
			return;
		}

		try {
			com.alrex.parcool.server.limitation.Limitation limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(
					player.getUUID(),
					new com.alrex.parcool.server.limitation.Limitation.ID("parcool_api", "weight_overload")
				);

			limitation.setEnabled(true);

			if (status >= 2) {
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.FastRun.class, false);
			}

			if (status >= 3) {
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ChargeJump.class, false);
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.JumpFromBar.class, false);
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.HorizontalWallRun.class, false);
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.VerticalWallRun.class, false);
			}

			if (status >= 4) {
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClimbUp.class, false);
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClimbPoles.class, false);
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.HangDown.class, false);
				limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClingToCliff.class, false);
			}

			${package}.parcool.ParCoolApiMovementBridge.syncParCoolLimitations(player);
		} catch (Throwable ignored) {
		}
	}

	private static void clearParCoolWeightRestriction(ServerPlayer player) {
		try {
			com.alrex.parcool.server.limitation.Limitation limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(
					player.getUUID(),
					new com.alrex.parcool.server.limitation.Limitation.ID("parcool_api", "weight_overload")
				);

			limitation.setEnabled(false);

			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.FastRun.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ChargeJump.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.JumpFromBar.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.HorizontalWallRun.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.VerticalWallRun.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClimbUp.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClimbPoles.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.HangDown.class, true);
			limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.ClingToCliff.class, true);

			${package}.parcool.ParCoolApiMovementBridge.syncParCoolLimitations(player);
		} catch (Throwable ignored) {
		}
	}

	@SubscribeEvent
	public static void onPlayerTick(PlayerTickEvent.Post event) {
		if (!(event.getEntity() instanceof ServerPlayer serverPlayer)) {
			return;
		}

		if (!isAutoEnabled(serverPlayer)) {
			return;
		}

		if (serverPlayer.tickCount % autoUpdateIntervalTicks != 0) {
			return;
		}

		updatePlayerWeightState(serverPlayer);
	}
}