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
import net.neoforged.neoforge.event.tick.PlayerTickEvent;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiWeightSystem {
	private static final String DATA_NAME = "${modid}_parcool_api_weight_system";

	private static final Map<ResourceLocation, Double> ITEM_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Double> PLAYER_MAX_WEIGHTS = new ConcurrentHashMap<>();
	private static final Map<UUID, Boolean> PLAYER_AUTO_ENABLED = new ConcurrentHashMap<>();
	private static final Map<UUID, Integer> PLAYER_LAST_STATUS = new ConcurrentHashMap<>();

	private static double defaultItemWeight = 1.0D;
	private static double defaultMaxCarryWeight = 64.0D;
	private static int autoUpdateIntervalTicks = 10;
	private static boolean loadedFromSavedData = false;

	private ParCoolApiWeightSystem() {
	}

	@SubscribeEvent
    public static void onPlayerLoggedIn(net.neoforged.neoforge.event.entity.player.PlayerEvent.PlayerLoggedInEvent event) {
    	if (event.getEntity() instanceof ServerPlayer serverPlayer) {
    		getMaxCarryWeight(serverPlayer);
    		isAutoEnabled(serverPlayer);
    		getLastStatus(serverPlayer);

    		${JavaModName}.queueServerWork(20, () -> updatePlayerWeightState(serverPlayer));
    		${JavaModName}.queueServerWork(40, () -> updatePlayerWeightState(serverPlayer));
    		${JavaModName}.queueServerWork(80, () -> updatePlayerWeightState(serverPlayer));
    	}
    }

	private static void ensurePlayerDefaults(ServerPlayer player) {
		if (player == null) {
			return;
		}

		getMaxCarryWeight(player);
		isAutoEnabled(player);
		getLastStatus(player);
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

		saveGlobalSettings();
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

    	double safeMaxWeight = sanitizeMaxCarryWeight(maxWeight);

    	player.getPersistentData().putDouble("ParCoolApiWeight_MaxCarryWeight", safeMaxWeight);
    	PLAYER_MAX_WEIGHTS.put(player.getUUID(), safeMaxWeight);

    	if (player instanceof ServerPlayer serverPlayer) {
    		updatePlayerWeightState(serverPlayer);
    	}
    }

	public static double getMaxCarryWeight(Player player) {
    	if (player == null) {
    		return defaultMaxCarryWeight;
    	}

    	if (player.getPersistentData().contains("ParCoolApiWeight_MaxCarryWeight")) {
    		double stored = sanitizeMaxCarryWeight(player.getPersistentData().getDouble("ParCoolApiWeight_MaxCarryWeight"));
    		PLAYER_MAX_WEIGHTS.put(player.getUUID(), stored);
    		return stored;
    	}

    	if (PLAYER_MAX_WEIGHTS.containsKey(player.getUUID())) {
    		double stored = sanitizeMaxCarryWeight(PLAYER_MAX_WEIGHTS.get(player.getUUID()));
    		player.getPersistentData().putDouble("ParCoolApiWeight_MaxCarryWeight", stored);
    		return stored;
    	}

    	double fallback = sanitizeMaxCarryWeight(defaultMaxCarryWeight);
    	player.getPersistentData().putDouble("ParCoolApiWeight_MaxCarryWeight", fallback);
    	PLAYER_MAX_WEIGHTS.put(player.getUUID(), fallback);
    	return fallback;
    }

	public static void setDefaultMaxCarryWeight(double maxWeight) {
		ensureLoadedFromSavedData();

		defaultMaxCarryWeight = sanitizeMaxCarryWeight(maxWeight);
		saveGlobalSettings();
	}

	public static double getLoadPercent(Player player) {
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

	public static void setAutoEnabled(Player player, boolean enabled) {
    	if (player == null) {
    		return;
    	}

    	player.getPersistentData().putBoolean("ParCoolApiWeight_HasAutoEnabled", true);
    	player.getPersistentData().putBoolean("ParCoolApiWeight_AutoEnabled", enabled);
    	PLAYER_AUTO_ENABLED.put(player.getUUID(), enabled);

    	if (!enabled && player instanceof ServerPlayer serverPlayer) {
    		clearParCoolWeightRestriction(serverPlayer);
    		setLastStatus(serverPlayer, 0);
    	}
    }

	public static boolean isAutoEnabled(Player player) {
    	if (player == null) {
    		return false;
    	}

    	if (player.getPersistentData().getBoolean("ParCoolApiWeight_HasAutoEnabled")) {
    		boolean stored = player.getPersistentData().getBoolean("ParCoolApiWeight_AutoEnabled");
    		PLAYER_AUTO_ENABLED.put(player.getUUID(), stored);
    		return stored;
    	}

    	player.getPersistentData().putBoolean("ParCoolApiWeight_HasAutoEnabled", true);
    	player.getPersistentData().putBoolean("ParCoolApiWeight_AutoEnabled", true);
    	PLAYER_AUTO_ENABLED.put(player.getUUID(), true);
    	return true;
    }

	public static void setAutoUpdateIntervalTicks(int ticks) {
		autoUpdateIntervalTicks = Math.max(1, ticks);
	}

	private static int getLastStatus(Player player) {
    	if (player == null) {
    		return -1;
    	}

    	if (player.getPersistentData().contains("ParCoolApiWeight_LastStatus")) {
    		int stored = player.getPersistentData().getInt("ParCoolApiWeight_LastStatus");
    		PLAYER_LAST_STATUS.put(player.getUUID(), stored);
    		return stored;
    	}

    	PLAYER_LAST_STATUS.put(player.getUUID(), -1);
    	player.getPersistentData().putInt("ParCoolApiWeight_LastStatus", -1);
    	return -1;
    }

	private static void setLastStatus(Player player, int status) {
    	if (player == null) {
    		return;
    	}

    	PLAYER_LAST_STATUS.put(player.getUUID(), status);
    	player.getPersistentData().putInt("ParCoolApiWeight_LastStatus", status);
    }

	public static void updatePlayerWeightState(Player player) {
		if (!(player instanceof ServerPlayer serverPlayer)) {
			return;
		}

		ensureLoadedFromSavedData();

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

			${package}.parcool.ParCoolApiMovementBridge.schedulePermissionBurst(player);
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

			${package}.parcool.ParCoolApiMovementBridge.schedulePermissionBurst(player);
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

	private static void savePlayerSettings(UUID uuid) {
		if (uuid == null) {
			return;
		}

		ParCoolApiWeightSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		if (PLAYER_MAX_WEIGHTS.containsKey(uuid)) {
			data.playerMaxWeights.put(uuid, sanitizeMaxCarryWeight(PLAYER_MAX_WEIGHTS.get(uuid)));
		}

		if (PLAYER_AUTO_ENABLED.containsKey(uuid)) {
			data.playerAutoEnabled.put(uuid, PLAYER_AUTO_ENABLED.get(uuid));
		}

		if (PLAYER_LAST_STATUS.containsKey(uuid)) {
			data.playerLastStatus.put(uuid, PLAYER_LAST_STATUS.get(uuid));
		}

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

			data.defaultItemWeight = Math.max(0.0D, tag.getDouble("DefaultItemWeight"));
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