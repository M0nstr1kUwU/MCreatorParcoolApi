package ${package}.weight;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.core.HolderLookup;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.saveddata.SavedData;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.server.ServerStartedEvent;
import net.neoforged.neoforge.event.tick.PlayerTickEvent;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiWeightSystem {
	private static final String DATA_NAME = "${modid}_parcool_api_weight_system_v2";

	private static final com.alrex.parcool.api.unstable.Limitation.ID WEIGHT_LIMITATION_ID =
		new com.alrex.parcool.api.unstable.Limitation.ID("parcool_api", "weight_overload");

	private static final String LEGACY_TAG_MAX_CARRY_WEIGHT = "ParCoolApiWeight_MaxCarryWeight";
	private static final String LEGACY_TAG_HAS_AUTO_ENABLED = "ParCoolApiWeight_HasAutoEnabled";
	private static final String LEGACY_TAG_AUTO_ENABLED = "ParCoolApiWeight_AutoEnabled";
	private static final String LEGACY_TAG_LAST_STATUS = "ParCoolApiWeight_LastStatus";

	private static final Map<ResourceLocation, Double> ITEM_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Double> PLAYER_MAX_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Boolean> PLAYER_AUTO_ENABLED = new ConcurrentHashMap<>();
	private static final Map<UUID, Integer> PLAYER_LAST_STATUS = new ConcurrentHashMap<>();

	private static final Map<UUID, Double> CLIENT_CURRENT_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Double> CLIENT_LOAD_PERCENTS = new ConcurrentHashMap<>();

	private static double defaultItemWeight = 1.0D;
	private static double defaultMaxCarryWeight = 64.0D;
	private static int autoUpdateIntervalTicks = 10;
	private static boolean loadedFromSavedData = false;

	private ParCoolApiWeightSystem() {
	}

	@SubscribeEvent
	public static void onServerStarted(ServerStartedEvent event) {
		loadedFromSavedData = false;

		ITEM_WEIGHTS.clear();
		PLAYER_MAX_WEIGHTS.clear();
		PLAYER_AUTO_ENABLED.clear();
		PLAYER_LAST_STATUS.clear();
		CLIENT_CURRENT_WEIGHTS.clear();
		CLIENT_LOAD_PERCENTS.clear();

		ensureLoadedFromSavedData();
	}

	@SubscribeEvent
	public static void onPlayerLoggedIn(net.neoforged.neoforge.event.entity.player.PlayerEvent.PlayerLoggedInEvent event) {
		if (event.getEntity() instanceof ServerPlayer serverPlayer) {
			ensureLoadedFromSavedData();
			migrateLegacyPlayerDataIfNeeded(serverPlayer);

			getMaxCarryWeight(serverPlayer);
			isAutoEnabled(serverPlayer);
			getLastStatus(serverPlayer);

			${JavaModName}.queueServerWork(20, () -> {
				if (serverPlayer.connection != null) {
					updatePlayerWeightState(serverPlayer);
				}
			});

			${JavaModName}.queueServerWork(60, () -> {
				if (serverPlayer.connection != null) {
					updatePlayerWeightState(serverPlayer);
				}
			});
		}
	}

	@SubscribeEvent
	public static void onPlayerLoggedOut(net.neoforged.neoforge.event.entity.player.PlayerEvent.PlayerLoggedOutEvent event) {
		if (event.getEntity() instanceof Player player) {
			UUID uuid = player.getUUID();

			CLIENT_CURRENT_WEIGHTS.remove(uuid);
			CLIENT_LOAD_PERCENTS.remove(uuid);
		}
	}

	public static void acceptClientSync(UUID uuid, double maxWeight, double currentWeight, double loadPercent, int status) {
		if (uuid == null) {
			return;
		}

		PLAYER_MAX_WEIGHTS.put(uuid, sanitizeMaxCarryWeight(maxWeight));
		CLIENT_CURRENT_WEIGHTS.put(uuid, Math.max(0.0D, currentWeight));
		CLIENT_LOAD_PERCENTS.put(uuid, Math.max(0.0D, loadPercent));
		PLAYER_LAST_STATUS.put(uuid, status);
	}

	public static void setDefaultItemWeight(double weight) {
		ensureLoadedFromSavedData();

		defaultItemWeight = Math.max(0.0D, weight);
		saveGlobalSettings();
	}

	public static double getDefaultItemWeight() {
		ensureLoadedFromSavedData();
		return defaultItemWeight;
	}

	public static void setAllRegisteredItemsWeight(double weight) {
		ensureLoadedFromSavedData();

		defaultItemWeight = Math.max(0.0D, weight);
		ITEM_WEIGHTS.clear();

		saveAll();
	}

	public static void setItemWeight(ItemStack stack, double weight) {
		ensureLoadedFromSavedData();

		if (stack == null || stack.isEmpty()) {
			return;
		}

		ResourceLocation id = BuiltInRegistries.ITEM.getKey(stack.getItem());

		if (id != null) {
			ITEM_WEIGHTS.put(id, Math.max(0.0D, weight));
			saveItemWeights();
		}
	}

	public static void setItemWeightById(String itemId, double weight) {
		ensureLoadedFromSavedData();

		ResourceLocation id = parseItemId(itemId);

		if (id != null) {
			ITEM_WEIGHTS.put(id, Math.max(0.0D, weight));
			saveItemWeights();
		}
	}

	public static double getUnitWeightById(String itemId) {
		ensureLoadedFromSavedData();

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
		ensureLoadedFromSavedData();

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

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();

		if (!(player instanceof ServerPlayer) && CLIENT_CURRENT_WEIGHTS.containsKey(uuid)) {
			return CLIENT_CURRENT_WEIGHTS.get(uuid);
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

	public static void setMaxCarryWeight(ServerPlayer player, double maxWeight) {
		if (player == null) {
			return;
		}

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();
		double safeMaxWeight = sanitizeMaxCarryWeight(maxWeight);

		PLAYER_MAX_WEIGHTS.put(uuid, safeMaxWeight);
		PLAYER_LAST_STATUS.put(uuid, -1);

		ParCoolApiWeightSavedData data = getSavedData();

		if (data != null) {
			data.playerMaxWeights.put(uuid, safeMaxWeight);
			data.playerLastStatus.put(uuid, -1);
			data.setDirty();
		}

		player.getPersistentData().putDouble(LEGACY_TAG_MAX_CARRY_WEIGHT, safeMaxWeight);
		player.getPersistentData().putInt(LEGACY_TAG_LAST_STATUS, -1);

		updatePlayerWeightState(player);
	}

	public static double getMaxCarryWeight(Player player) {
		if (player == null) {
			return defaultMaxCarryWeight;
		}

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();

		if (PLAYER_MAX_WEIGHTS.containsKey(uuid)) {
			return sanitizeMaxCarryWeight(PLAYER_MAX_WEIGHTS.get(uuid));
		}

		ParCoolApiWeightSavedData data = getSavedData();

		if (data != null && data.playerMaxWeights.containsKey(uuid)) {
			double stored = sanitizeMaxCarryWeight(data.playerMaxWeights.get(uuid));
			PLAYER_MAX_WEIGHTS.put(uuid, stored);
			player.getPersistentData().putDouble(LEGACY_TAG_MAX_CARRY_WEIGHT, stored);
			return stored;
		}

		if (player.getPersistentData().contains(LEGACY_TAG_MAX_CARRY_WEIGHT)) {
			double migrated = sanitizeMaxCarryWeight(player.getPersistentData().getDouble(LEGACY_TAG_MAX_CARRY_WEIGHT));
			PLAYER_MAX_WEIGHTS.put(uuid, migrated);

			if (data != null) {
				data.playerMaxWeights.put(uuid, migrated);
				data.setDirty();
			}

			return migrated;
		}

		double fallback = sanitizeMaxCarryWeight(defaultMaxCarryWeight);
		PLAYER_MAX_WEIGHTS.put(uuid, fallback);
		player.getPersistentData().putDouble(LEGACY_TAG_MAX_CARRY_WEIGHT, fallback);

		if (data != null) {
			data.playerMaxWeights.put(uuid, fallback);
			data.setDirty();
		}

		return fallback;
	}

	public static void setDefaultMaxCarryWeight(double maxWeight) {
		ensureLoadedFromSavedData();

		defaultMaxCarryWeight = sanitizeMaxCarryWeight(maxWeight);
		saveGlobalSettings();
	}

	public static double getLoadPercent(Player player) {
		if (player == null) {
			return 0.0D;
		}

		UUID uuid = player.getUUID();

		if (!(player instanceof ServerPlayer) && CLIENT_LOAD_PERCENTS.containsKey(uuid)) {
			return CLIENT_LOAD_PERCENTS.get(uuid);
		}

		double max = getMaxCarryWeight(player);

		if (max <= 0.0D) {
			return 0.0D;
		}

		return getInventoryWeight(player) / max * 100.0D;
	}

	public static boolean isOverloaded(Player player) {
		return getWeightStatus(player) > 0;
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

	public static void setAutoEnabled(ServerPlayer player, boolean enabled) {
		if (player == null) {
			return;
		}

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();

		PLAYER_AUTO_ENABLED.put(uuid, enabled);

		ParCoolApiWeightSavedData data = getSavedData();

		if (data != null) {
			data.playerAutoEnabled.put(uuid, enabled);
			data.setDirty();
		}

		player.getPersistentData().putBoolean(LEGACY_TAG_HAS_AUTO_ENABLED, true);
		player.getPersistentData().putBoolean(LEGACY_TAG_AUTO_ENABLED, enabled);

		if (!enabled) {
			clearParCoolWeightRestriction(player);
			setLastStatus(player, 0);
		}

		updatePlayerWeightState(player);
	}

	public static boolean isAutoEnabled(Player player) {
		if (player == null) {
			return false;
		}

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();

		if (PLAYER_AUTO_ENABLED.containsKey(uuid)) {
			return PLAYER_AUTO_ENABLED.get(uuid);
		}

		ParCoolApiWeightSavedData data = getSavedData();

		if (data != null && data.playerAutoEnabled.containsKey(uuid)) {
			boolean stored = data.playerAutoEnabled.get(uuid);
			PLAYER_AUTO_ENABLED.put(uuid, stored);
			return stored;
		}

		if (player.getPersistentData().getBoolean(LEGACY_TAG_HAS_AUTO_ENABLED)) {
			boolean migrated = player.getPersistentData().getBoolean(LEGACY_TAG_AUTO_ENABLED);
			PLAYER_AUTO_ENABLED.put(uuid, migrated);

			if (data != null) {
				data.playerAutoEnabled.put(uuid, migrated);
				data.setDirty();
			}

			return migrated;
		}

		PLAYER_AUTO_ENABLED.put(uuid, true);

		if (data != null) {
			data.playerAutoEnabled.put(uuid, true);
			data.setDirty();
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

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();

		if (PLAYER_LAST_STATUS.containsKey(uuid)) {
			return PLAYER_LAST_STATUS.get(uuid);
		}

		ParCoolApiWeightSavedData data = getSavedData();

		if (data != null && data.playerLastStatus.containsKey(uuid)) {
			int stored = data.playerLastStatus.get(uuid);
			PLAYER_LAST_STATUS.put(uuid, stored);
			return stored;
		}

		if (player.getPersistentData().contains(LEGACY_TAG_LAST_STATUS)) {
			int migrated = player.getPersistentData().getInt(LEGACY_TAG_LAST_STATUS);
			PLAYER_LAST_STATUS.put(uuid, migrated);

			if (data != null) {
				data.playerLastStatus.put(uuid, migrated);
				data.setDirty();
			}

			return migrated;
		}

		PLAYER_LAST_STATUS.put(uuid, -1);

		if (data != null) {
			data.playerLastStatus.put(uuid, -1);
			data.setDirty();
		}

		return -1;
	}

	private static void setLastStatus(Player player, int status) {
		if (player == null) {
			return;
		}

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();

		PLAYER_LAST_STATUS.put(uuid, status);

		ParCoolApiWeightSavedData data = getSavedData();

		if (data != null) {
			data.playerLastStatus.put(uuid, status);
			data.setDirty();
		}

		player.getPersistentData().putInt(LEGACY_TAG_LAST_STATUS, status);
	}

	public static void updatePlayerWeightState(Player player) {
		if (!(player instanceof ServerPlayer serverPlayer)) {
			return;
		}

		ensureLoadedFromSavedData();

		int status = getWeightStatus(serverPlayer);
		int oldStatus = getLastStatus(serverPlayer);

		double currentWeight = getInventoryWeight(serverPlayer);
		double maxWeight = getMaxCarryWeight(serverPlayer);
		double loadPercent = getLoadPercent(serverPlayer);

		applyStatusEffects(serverPlayer, status);
		applyParCoolWeightRestriction(serverPlayer, status);
		applyVanillaJumpRestriction(serverPlayer, status);
		syncWeightStateToClient(serverPlayer, maxWeight, currentWeight, loadPercent, status);

		if (status != oldStatus) {
			${package}.events.ParCoolApiBridgeEvents.fireWeightStatusChanged(
				serverPlayer,
				oldStatus,
				status,
				currentWeight,
				maxWeight,
				loadPercent
			);
		}

		setLastStatus(serverPlayer, status);
	}

	private static void syncWeightStateToClient(ServerPlayer player, double maxWeight, double currentWeight, double loadPercent, int status) {
		if (player == null) {
			return;
		}

		try {
			${package}.network.ParCoolApiWeightNetwork.syncToPlayer(player, maxWeight, currentWeight, loadPercent, status);
		} catch (Throwable ignored) {
		}
	}

	private static void applyStatusEffects(ServerPlayer player, int status) {
		if (status <= 0) {
			return;
		}

		if (status == 1) {
			player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 40, 1, false, false, true));
			return;
		}

		if (status == 2) {
			player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 40, 2, false, false, true));
			player.addEffect(new MobEffectInstance(MobEffects.DIG_SLOWDOWN, 40, 0, false, false, true));
			return;
		}

		if (status == 3) {
			player.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 40, 3, false, false, true));
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
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.api.unstable.Limitation limitation =
				com.alrex.parcool.api.unstable.Limitation.get(player, WEIGHT_LIMITATION_ID);

			limitation.setDefault();

			if (status <= 0) {
				limitation.disable();
				limitation.apply();
				return;
			}

			limitation.enable();

			if (status >= 1) {
				limitation.permit(com.alrex.parcool.common.action.impl.FastRun.class, false);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.FastRun.class, Integer.MAX_VALUE);
			}

			if (status >= 2) {
				limitation.permit(com.alrex.parcool.common.action.impl.ChargeJump.class, false);
				limitation.permit(com.alrex.parcool.common.action.impl.JumpFromBar.class, false);
				limitation.permit(com.alrex.parcool.common.action.impl.WallJump.class, false);

				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.ChargeJump.class, Integer.MAX_VALUE);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.JumpFromBar.class, Integer.MAX_VALUE);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.WallJump.class, Integer.MAX_VALUE);
			}

			if (status >= 3) {
				limitation.permit(com.alrex.parcool.common.action.impl.HorizontalWallRun.class, false);
				limitation.permit(com.alrex.parcool.common.action.impl.VerticalWallRun.class, false);
				limitation.permit(com.alrex.parcool.common.action.impl.WallSlide.class, false);
				limitation.permit(com.alrex.parcool.common.action.impl.ClimbUp.class, false);
				limitation.permit(com.alrex.parcool.common.action.impl.ClimbPoles.class, false);

				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.HorizontalWallRun.class, Integer.MAX_VALUE);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.VerticalWallRun.class, Integer.MAX_VALUE);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.WallSlide.class, Integer.MAX_VALUE);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.ClimbUp.class, Integer.MAX_VALUE);
				limitation.setLeastStaminaConsumption(com.alrex.parcool.common.action.impl.ClimbPoles.class, Integer.MAX_VALUE);
			}

			if (status >= 4) {
				for (Class<? extends com.alrex.parcool.common.action.Action> actionClass : com.alrex.parcool.common.action.Actions.LIST) {
					try {
						limitation.permit(actionClass, false);
						limitation.setLeastStaminaConsumption(actionClass, Integer.MAX_VALUE);
					} catch (Throwable ignoredAction) {
					}
				}
			}

			limitation.apply();
		} catch (Throwable ignored) {
		}
	}

	private static void applyVanillaJumpRestriction(ServerPlayer player, int status) {
		if (player == null) {
			return;
		}

		try {
			${package}.parcool.ParCoolApiVanillaJumpBridge.setVanillaJumpDisabled(player, status >= 2);
		} catch (Throwable ignored) {
		}
	}

	private static void clearParCoolWeightRestriction(ServerPlayer player) {
		if (player == null) {
			return;
		}

		try {
			com.alrex.parcool.api.unstable.Limitation limitation =
				com.alrex.parcool.api.unstable.Limitation.get(player, WEIGHT_LIMITATION_ID);

			limitation.setDefault();
			limitation.disable();
			limitation.apply();

			${package}.parcool.ParCoolApiVanillaJumpBridge.setVanillaJumpDisabled(player, false);
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

	private static double sanitizeMaxCarryWeight(double value) {
		if (Double.isNaN(value) || Double.isInfinite(value) || value < 2.0D) {
			return Math.max(64.0D, defaultMaxCarryWeight);
		}

		return value;
	}

	private static void migrateLegacyPlayerDataIfNeeded(ServerPlayer player) {
		if (player == null) {
			return;
		}

		ensureLoadedFromSavedData();

		UUID uuid = player.getUUID();
		ParCoolApiWeightSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		if (!data.playerMaxWeights.containsKey(uuid) && player.getPersistentData().contains(LEGACY_TAG_MAX_CARRY_WEIGHT)) {
			data.playerMaxWeights.put(uuid, sanitizeMaxCarryWeight(player.getPersistentData().getDouble(LEGACY_TAG_MAX_CARRY_WEIGHT)));
			data.setDirty();
		}

		if (!data.playerAutoEnabled.containsKey(uuid) && player.getPersistentData().getBoolean(LEGACY_TAG_HAS_AUTO_ENABLED)) {
			data.playerAutoEnabled.put(uuid, player.getPersistentData().getBoolean(LEGACY_TAG_AUTO_ENABLED));
			data.setDirty();
		}

		if (!data.playerLastStatus.containsKey(uuid) && player.getPersistentData().contains(LEGACY_TAG_LAST_STATUS)) {
			data.playerLastStatus.put(uuid, player.getPersistentData().getInt(LEGACY_TAG_LAST_STATUS));
			data.setDirty();
		}
	}

	private static ParCoolApiWeightSavedData getSavedData() {
		try {
			MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

			if (server == null) {
				return null;
			}

			ServerLevel overworld = server.overworld();

			if (overworld == null) {
				return null;
			}

			return overworld.getDataStorage().computeIfAbsent(
				new SavedData.Factory<>(ParCoolApiWeightSavedData::new, ParCoolApiWeightSavedData::load, null),
				DATA_NAME
			);
		} catch (Throwable ignored) {
			return null;
		}
	}

	private static void ensureLoadedFromSavedData() {
		if (loadedFromSavedData) {
			return;
		}

		ParCoolApiWeightSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		defaultItemWeight = Math.max(0.0D, data.defaultItemWeight);
		defaultMaxCarryWeight = sanitizeMaxCarryWeight(data.defaultMaxCarryWeight);

		ITEM_WEIGHTS.clear();
		ITEM_WEIGHTS.putAll(data.itemWeights);

		PLAYER_MAX_WEIGHTS.clear();
		for (Map.Entry<UUID, Double> entry : data.playerMaxWeights.entrySet()) {
			PLAYER_MAX_WEIGHTS.put(entry.getKey(), sanitizeMaxCarryWeight(entry.getValue()));
		}

		PLAYER_AUTO_ENABLED.clear();
		PLAYER_AUTO_ENABLED.putAll(data.playerAutoEnabled);

		PLAYER_LAST_STATUS.clear();
		PLAYER_LAST_STATUS.putAll(data.playerLastStatus);

		loadedFromSavedData = true;
	}

	private static void saveGlobalSettings() {
		ParCoolApiWeightSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		data.defaultItemWeight = defaultItemWeight;
		data.defaultMaxCarryWeight = defaultMaxCarryWeight;
		data.setDirty();
	}

	private static void saveItemWeights() {
		ParCoolApiWeightSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		data.defaultItemWeight = defaultItemWeight;
		data.itemWeights.clear();
		data.itemWeights.putAll(ITEM_WEIGHTS);
		data.setDirty();
	}

	private static void saveAll() {
		ParCoolApiWeightSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		data.defaultItemWeight = defaultItemWeight;
		data.defaultMaxCarryWeight = defaultMaxCarryWeight;

		data.itemWeights.clear();
		data.itemWeights.putAll(ITEM_WEIGHTS);

		data.playerMaxWeights.clear();
		data.playerMaxWeights.putAll(PLAYER_MAX_WEIGHTS);

		data.playerAutoEnabled.clear();
		data.playerAutoEnabled.putAll(PLAYER_AUTO_ENABLED);

		data.playerLastStatus.clear();
		data.playerLastStatus.putAll(PLAYER_LAST_STATUS);

		data.setDirty();
	}

	public static final class ParCoolApiWeightSavedData extends SavedData {
		private double defaultItemWeight = 1.0D;
		private double defaultMaxCarryWeight = 64.0D;

		private final Map<ResourceLocation, Double> itemWeights = new ConcurrentHashMap<>();
		private final Map<UUID, Double> playerMaxWeights = new ConcurrentHashMap<>();
		private final Map<UUID, Boolean> playerAutoEnabled = new ConcurrentHashMap<>();
		private final Map<UUID, Integer> playerLastStatus = new ConcurrentHashMap<>();

		public static ParCoolApiWeightSavedData load(CompoundTag tag, HolderLookup.Provider provider) {
			ParCoolApiWeightSavedData data = new ParCoolApiWeightSavedData();

			data.defaultItemWeight = tag.contains("DefaultItemWeight") ? Math.max(0.0D, tag.getDouble("DefaultItemWeight")) : 1.0D;
			data.defaultMaxCarryWeight = tag.contains("DefaultMaxCarryWeight") ? Math.max(2.0D, tag.getDouble("DefaultMaxCarryWeight")) : 64.0D;

			ListTag itemWeightsTag = tag.getList("ItemWeights", Tag.TAG_COMPOUND);
			for (int i = 0; i < itemWeightsTag.size(); i++) {
				CompoundTag entry = itemWeightsTag.getCompound(i);
				ResourceLocation id = ResourceLocation.tryParse(entry.getString("Id"));

				if (id != null) {
					data.itemWeights.put(id, Math.max(0.0D, entry.getDouble("Weight")));
				}
			}

			ListTag playerMaxWeightsTag = tag.getList("PlayerMaxWeights", Tag.TAG_COMPOUND);
			for (int i = 0; i < playerMaxWeightsTag.size(); i++) {
				CompoundTag entry = playerMaxWeightsTag.getCompound(i);

				try {
					UUID uuid = UUID.fromString(entry.getString("UUID"));
					data.playerMaxWeights.put(uuid, Math.max(2.0D, entry.getDouble("Value")));
				} catch (Throwable ignored) {
				}
			}

			ListTag playerAutoEnabledTag = tag.getList("PlayerAutoEnabled", Tag.TAG_COMPOUND);
			for (int i = 0; i < playerAutoEnabledTag.size(); i++) {
				CompoundTag entry = playerAutoEnabledTag.getCompound(i);

				try {
					UUID uuid = UUID.fromString(entry.getString("UUID"));
					data.playerAutoEnabled.put(uuid, entry.getBoolean("Value"));
				} catch (Throwable ignored) {
				}
			}

			ListTag playerLastStatusTag = tag.getList("PlayerLastStatus", Tag.TAG_COMPOUND);
			for (int i = 0; i < playerLastStatusTag.size(); i++) {
				CompoundTag entry = playerLastStatusTag.getCompound(i);

				try {
					UUID uuid = UUID.fromString(entry.getString("UUID"));
					data.playerLastStatus.put(uuid, entry.getInt("Value"));
				} catch (Throwable ignored) {
				}
			}

			return data;
		}

		@Override
		public CompoundTag save(CompoundTag tag, HolderLookup.Provider provider) {
			tag.putDouble("DefaultItemWeight", defaultItemWeight);
			tag.putDouble("DefaultMaxCarryWeight", defaultMaxCarryWeight);

			ListTag itemWeightsTag = new ListTag();
			for (Map.Entry<ResourceLocation, Double> entry : itemWeights.entrySet()) {
				CompoundTag itemTag = new CompoundTag();
				itemTag.putString("Id", entry.getKey().toString());
				itemTag.putDouble("Weight", Math.max(0.0D, entry.getValue()));
				itemWeightsTag.add(itemTag);
			}
			tag.put("ItemWeights", itemWeightsTag);

			ListTag playerMaxWeightsTag = new ListTag();
			for (Map.Entry<UUID, Double> entry : playerMaxWeights.entrySet()) {
				CompoundTag playerTag = new CompoundTag();
				playerTag.putString("UUID", entry.getKey().toString());
				playerTag.putDouble("Value", Math.max(2.0D, entry.getValue()));
				playerMaxWeightsTag.add(playerTag);
			}
			tag.put("PlayerMaxWeights", playerMaxWeightsTag);

			ListTag playerAutoEnabledTag = new ListTag();
			for (Map.Entry<UUID, Boolean> entry : playerAutoEnabled.entrySet()) {
				CompoundTag playerTag = new CompoundTag();
				playerTag.putString("UUID", entry.getKey().toString());
				playerTag.putBoolean("Value", entry.getValue());
				playerAutoEnabledTag.add(playerTag);
			}
			tag.put("PlayerAutoEnabled", playerAutoEnabledTag);

			ListTag playerLastStatusTag = new ListTag();
			for (Map.Entry<UUID, Integer> entry : playerLastStatus.entrySet()) {
				CompoundTag playerTag = new CompoundTag();
				playerTag.putString("UUID", entry.getKey().toString());
				playerTag.putInt("Value", entry.getValue());
				playerLastStatusTag.add(playerTag);
			}
			tag.put("PlayerLastStatus", playerLastStatusTag);

			return tag;
		}
	}
}