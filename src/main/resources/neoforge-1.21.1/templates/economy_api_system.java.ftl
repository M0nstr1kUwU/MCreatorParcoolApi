package ${package}.economy;

import java.util.ArrayList;
import java.util.List;
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
import net.minecraft.world.entity.Entity;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.saveddata.SavedData;

import net.neoforged.neoforge.server.ServerLifecycleHooks;

public final class EconomyApiSystem {
	private static final String DATA_NAME = "${modid}_economy_system_v1";

	public static final long COOPER_VALUE = 1L;
	public static final long IRON_VALUE = 100L;
	public static final long GOLD_VALUE = 10_000L;
	public static final long PLATINE_VALUE = 10_000_000L;

	private EconomyApiSystem() {
	}

	public static boolean isEconomyEnabled() {
		return EconomyApiServerConfig.get().economyEnabled;
	}

	public static boolean setEconomyEnabled(boolean enabled) {
		return EconomyApiServerConfig.setEconomyEnabled(enabled);
	}

	public static boolean isCasinoEnabled() {
		return EconomyApiServerConfig.get().casinoEnabled;
	}

	public static boolean setCasinoEnabled(boolean enabled) {
		return EconomyApiServerConfig.setCasinoEnabled(enabled);
	}

	public static long toCopper(double amount, String unit) {
		if (Double.isNaN(amount) || Double.isInfinite(amount) || amount <= 0.0D) {
			return 0L;
		}

		double multiplier = coinValue(unit);
		double value = amount * multiplier;

		if (value >= Long.MAX_VALUE) {
			return Long.MAX_VALUE;
		}

		return Math.max(0L, Math.round(value));
	}

	public static long coinValue(String unit) {
		return switch (normalizeCoin(unit)) {
			case "IRON" -> IRON_VALUE;
			case "GOLD" -> GOLD_VALUE;
			case "PLATINE" -> PLATINE_VALUE;
			default -> COOPER_VALUE;
		};
	}

	public static String normalizeCoin(String coin) {
		if (coin == null) {
			return "COOPER";
		}

		String normalized = coin.trim().toUpperCase(java.util.Locale.ROOT);

		if ("COPPER".equals(normalized)) {
			return "COOPER";
		}

		if ("PLATINUM".equals(normalized) || "PLATIN".equals(normalized)) {
			return "PLATINE";
		}

		return switch (normalized) {
			case "COOPER", "IRON", "GOLD", "PLATINE" -> normalized;
			default -> "COOPER";
		};
	}

	public static String formatMoney(long cooper) {
		long value = Math.max(0L, cooper);

		long platine = value / PLATINE_VALUE;
		value %= PLATINE_VALUE;

		long gold = value / GOLD_VALUE;
		value %= GOLD_VALUE;

		long iron = value / IRON_VALUE;
		value %= IRON_VALUE;

		long copper = value;

		List<String> parts = new ArrayList<>();

		if (platine > 0) {
			parts.add(platine + " Platine");
		}

		if (gold > 0) {
			parts.add(gold + " Gold");
		}

		if (iron > 0) {
			parts.add(iron + " Iron");
		}

		if (copper > 0 || parts.isEmpty()) {
			parts.add(copper + " Cooper");
		}

		return String.join(" ", parts);
	}

	public static long getWallet(Entity entity) {
		if (!(entity instanceof ServerPlayer player)) {
			return 0L;
		}

		EconomySavedData data = getSavedData();

		return data != null ? data.getAccount(player.getUUID()).wallet : 0L;
	}

	public static long getBank(Entity entity) {
		if (!(entity instanceof ServerPlayer player)) {
			return 0L;
		}

		EconomySavedData data = getSavedData();

		return data != null ? data.getAccount(player.getUUID()).bank : 0L;
	}

	public static long getTotal(Entity entity) {
		return safeAdd(getWallet(entity), getBank(entity));
	}

	public static boolean setWallet(Entity entity, long cooper) {
		if (!(entity instanceof ServerPlayer player)) {
			return false;
		}

		EconomySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		AccountData account = data.getAccount(player.getUUID());
		account.wallet = Math.max(0L, cooper);

		data.setDirty();
		return true;
	}

	public static boolean setBank(Entity entity, long cooper) {
		if (!(entity instanceof ServerPlayer player)) {
			return false;
		}

		EconomySavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		AccountData account = data.getAccount(player.getUUID());
		account.bank = Math.max(0L, cooper);

		data.setDirty();
		return true;
	}

	public static boolean addWallet(Entity entity, long cooper) {
		if (cooper <= 0L) {
			return false;
		}

		return setWallet(entity, safeAdd(getWallet(entity), cooper));
	}

	public static boolean addBank(Entity entity, long cooper) {
		if (cooper <= 0L) {
			return false;
		}

		return setBank(entity, safeAdd(getBank(entity), cooper));
	}

	public static boolean takeWallet(Entity entity, long cooper) {
		if (cooper <= 0L || getWallet(entity) < cooper) {
			return false;
		}

		return setWallet(entity, getWallet(entity) - cooper);
	}

	public static boolean takeBank(Entity entity, long cooper) {
		if (cooper <= 0L || getBank(entity) < cooper) {
			return false;
		}

		return setBank(entity, getBank(entity) - cooper);
	}

	public static boolean hasWallet(Entity entity, long cooper) {
		return cooper <= 0L || getWallet(entity) >= cooper;
	}

	public static boolean hasBank(Entity entity, long cooper) {
		return cooper <= 0L || getBank(entity) >= cooper;
	}

	public static boolean transferWallet(Entity from, Entity to, long amountCooper) {
		if (!(from instanceof ServerPlayer fromPlayer) || !(to instanceof ServerPlayer toPlayer)) {
			return false;
		}

		if (!isEconomyEnabled() || amountCooper <= 0L || fromPlayer.getUUID().equals(toPlayer.getUUID())) {
			return false;
		}

		if (!takeWallet(fromPlayer, amountCooper)) {
			return false;
		}

		long fee = calculateTransferFee(amountCooper);
		long received = Math.max(0L, amountCooper - fee);

		addWallet(toPlayer, received);

		fromPlayer.displayClientMessage(net.minecraft.network.chat.Component.literal(
			"Transferred " + formatMoney(amountCooper) + " to " + toPlayer.getGameProfile().getName() + " (fee: " + formatMoney(fee) + ")"
		), false);

		toPlayer.displayClientMessage(net.minecraft.network.chat.Component.literal(
			"Received " + formatMoney(received) + " from " + fromPlayer.getGameProfile().getName()
		), false);

		return true;
	}

	public static long calculateTransferFee(long amountCooper) {
		double percent = EconomyApiServerConfig.get().transferFeePercent;
		return Math.max(0L, Math.round(Math.max(0L, amountCooper) * (percent / 100.0D)));
	}

	public static boolean moveWalletToBank(Entity entity, long amountCooper) {
		if (amountCooper <= 0L || !takeWallet(entity, amountCooper)) {
			return false;
		}

		return addBank(entity, amountCooper);
	}

	public static boolean moveBankToWallet(Entity entity, long amountCooper) {
		if (amountCooper <= 0L || !takeBank(entity, amountCooper)) {
			return false;
		}

		return addWallet(entity, amountCooper);
	}

	public static int depositCoinItemsToBank(Entity entity, String coin, int requestedItems) {
		if (!(entity instanceof ServerPlayer player) || !isEconomyEnabled()) {
			return 0;
		}

		String itemId = EconomyApiServerConfig.getCoinItem(coin);
		Item item = resolveItem(itemId);

		if (item == Items.AIR) {
			return 0;
		}

		int available = countItem(player, item);
		int toRemove = requestedItems <= 0 ? available : Math.min(available, requestedItems);

		if (toRemove <= 0) {
			return 0;
		}

		int removed = removeItem(player, item, toRemove);

		if (removed <= 0) {
			return 0;
		}

		addBank(player, safeMultiply(coinValue(coin), removed));
		return removed;
	}

	public static int withdrawCoinItemsFromBank(Entity entity, String coin, int requestedItems) {
		if (!(entity instanceof ServerPlayer player) || !isEconomyEnabled()) {
			return 0;
		}

		if (requestedItems <= 0) {
			return 0;
		}

		String itemId = EconomyApiServerConfig.getCoinItem(coin);
		Item item = resolveItem(itemId);

		if (item == Items.AIR) {
			return 0;
		}

		long valuePerItem = coinValue(coin);
		long maxAffordable = getBank(player) / valuePerItem;
		int toGive = (int) Math.min(Math.min(Integer.MAX_VALUE, maxAffordable), requestedItems);

		if (toGive <= 0) {
			return 0;
		}

		long cost = safeMultiply(valuePerItem, toGive);

		if (!takeBank(player, cost)) {
			return 0;
		}

		giveItem(player, item, toGive);
		return toGive;
	}

	public static boolean applyDeathPenalty(ServerPlayer player) {
		if (player == null || !isEconomyEnabled()) {
			return false;
		}

		double percent = EconomyApiServerConfig.get().deathWalletLossPercent;

		if (percent <= 0.0D) {
			return false;
		}

		long wallet = getWallet(player);
		long loss = Math.max(0L, Math.round(wallet * (percent / 100.0D)));

		if (loss <= 0L) {
			return false;
		}

		setWallet(player, wallet - loss);

		player.displayClientMessage(net.minecraft.network.chat.Component.literal(
			"You lost " + formatMoney(loss) + " from your personal wallet. Bank account is safe."
		), false);

		return true;
	}

	public static boolean takeCasinoBet(Entity entity, long betCooper) {
		if (!(entity instanceof ServerPlayer) || !isEconomyEnabled() || !isCasinoEnabled()) {
			return false;
		}

		long clamped = clampCasinoBet(betCooper);

		if (clamped != betCooper || clamped <= 0L) {
			return false;
		}

		return takeWallet(entity, betCooper);
	}

	public static long giveCasinoPayout(Entity entity, long betCooper, double multiplier) {
		if (!(entity instanceof ServerPlayer) || !isEconomyEnabled() || !isCasinoEnabled()) {
			return 0L;
		}

		long payout = calculateCasinoPayout(betCooper, multiplier, true);

		if (payout > 0L) {
			addWallet(entity, payout);
		}

		return payout;
	}

	public static long calculateCasinoPayout(long betCooper, double multiplier, boolean applyHouseEdge) {
		if (betCooper <= 0L || Double.isNaN(multiplier) || Double.isInfinite(multiplier) || multiplier <= 0.0D) {
			return 0L;
		}

		double effectiveMultiplier = multiplier;

		if (applyHouseEdge) {
			effectiveMultiplier *= Math.max(0.0D, 1.0D - EconomyApiServerConfig.get().casinoHouseEdgePercent / 100.0D);
		}

		double payout = betCooper * effectiveMultiplier;

		if (payout >= Long.MAX_VALUE) {
			return Long.MAX_VALUE;
		}

		return Math.max(0L, Math.round(payout));
	}

	public static long clampCasinoBet(long betCooper) {
		EconomyApiServerConfig.Config config = EconomyApiServerConfig.get();

		return Math.max(config.casinoMinBetCooper, Math.min(config.casinoMaxBetCooper, betCooper));
	}

	public static boolean isCasinoBetAllowed(long betCooper) {
		EconomyApiServerConfig.Config config = EconomyApiServerConfig.get();

		return isEconomyEnabled() && isCasinoEnabled() && betCooper >= config.casinoMinBetCooper && betCooper <= config.casinoMaxBetCooper;
	}

	public static double getTransferFeePercent() {
		return EconomyApiServerConfig.get().transferFeePercent;
	}

	public static boolean setTransferFeePercent(double percent) {
		return EconomyApiServerConfig.setTransferFeePercent(percent);
	}

	public static boolean setDeathWalletLossPercent(double percent) {
		return EconomyApiServerConfig.setDeathWalletLossPercent(percent);
	}

	public static boolean setCasinoHouseEdgePercent(double percent) {
		return EconomyApiServerConfig.setCasinoHouseEdgePercent(percent);
	}

	public static boolean setCasinoBetLimits(long minBetCooper, long maxBetCooper) {
		return EconomyApiServerConfig.setCasinoBetLimits(minBetCooper, maxBetCooper);
	}

	public static boolean setCoinItem(String coin, String itemId) {
		return EconomyApiServerConfig.setCoinItem(coin, itemId);
	}

	private static int countItem(ServerPlayer player, Item item) {
		int count = 0;

		for (ItemStack stack : player.getInventory().items) {
			if (!stack.isEmpty() && stack.is(item)) {
				count += stack.getCount();
			}
		}

		return count;
	}

	private static int removeItem(ServerPlayer player, Item item, int amount) {
		int remaining = amount;
		int removed = 0;

		for (ItemStack stack : player.getInventory().items) {
			if (remaining <= 0) {
				break;
			}

			if (stack.isEmpty() || !stack.is(item)) {
				continue;
			}

			int take = Math.min(remaining, stack.getCount());
			stack.shrink(take);
			remaining -= take;
			removed += take;
		}

		player.getInventory().setChanged();
		return removed;
	}

	private static void giveItem(ServerPlayer player, Item item, int amount) {
		int remaining = amount;

		while (remaining > 0) {
			ItemStack stack = new ItemStack(item);
			int stackSize = Math.min(remaining, stack.getMaxStackSize());
			stack.setCount(stackSize);

			boolean added = player.getInventory().add(stack);

			if (!added && !stack.isEmpty()) {
				player.drop(stack, false);
			}

			remaining -= stackSize;
		}

		player.getInventory().setChanged();
	}

	private static Item resolveItem(String itemId) {
		try {
			ResourceLocation location = ResourceLocation.parse(normalizeItemId(itemId));
			return BuiltInRegistries.ITEM.getOptional(location).orElse(Items.AIR);
		} catch (Throwable ignored) {
			return Items.AIR;
		}
	}

	private static String normalizeItemId(String itemId) {
		if (itemId == null || itemId.isBlank()) {
			return "minecraft:air";
		}

		String normalized = itemId.trim().toLowerCase(java.util.Locale.ROOT);

		if (!normalized.contains(":")) {
			normalized = "minecraft:" + normalized;
		}

		return normalized;
	}

	private static long safeAdd(long a, long b) {
		if (Long.MAX_VALUE - a < b) {
			return Long.MAX_VALUE;
		}

		return Math.max(0L, a + b);
	}

	private static long safeMultiply(long a, long b) {
		if (a <= 0L || b <= 0L) {
			return 0L;
		}

		if (a > Long.MAX_VALUE / b) {
			return Long.MAX_VALUE;
		}

		return a * b;
	}

	private static EconomySavedData getSavedData() {
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
				new SavedData.Factory<>(EconomySavedData::new, EconomySavedData::load, null),
				DATA_NAME
			);
		} catch (Throwable ignored) {
			return null;
		}
	}

	public static final class AccountData {
		private long wallet = 0L;
		private long bank = 0L;
	}

	public static final class EconomySavedData extends SavedData {
		private final Map<UUID, AccountData> accounts = new ConcurrentHashMap<>();

		private AccountData getAccount(UUID playerId) {
			return accounts.computeIfAbsent(playerId, id -> new AccountData());
		}

		public static EconomySavedData load(CompoundTag tag, HolderLookup.Provider provider) {
			EconomySavedData data = new EconomySavedData();

			ListTag accountsTag = tag.getList("Accounts", Tag.TAG_COMPOUND);

			for (int i = 0; i < accountsTag.size(); i++) {
				CompoundTag accountTag = accountsTag.getCompound(i);

				try {
					UUID playerId = UUID.fromString(accountTag.getString("Player"));
					AccountData account = new AccountData();

					account.wallet = Math.max(0L, accountTag.getLong("Wallet"));
					account.bank = Math.max(0L, accountTag.getLong("Bank"));

					data.accounts.put(playerId, account);
				} catch (Throwable ignored) {
				}
			}

			return data;
		}

		@Override
		public CompoundTag save(CompoundTag tag, HolderLookup.Provider provider) {
			ListTag accountsTag = new ListTag();

			for (Map.Entry<UUID, AccountData> entry : accounts.entrySet()) {
				CompoundTag accountTag = new CompoundTag();
				accountTag.putString("Player", entry.getKey().toString());
				accountTag.putLong("Wallet", Math.max(0L, entry.getValue().wallet));
				accountTag.putLong("Bank", Math.max(0L, entry.getValue().bank));
				accountsTag.add(accountTag);
			}

			tag.put("Accounts", accountsTag);
			return tag;
		}
	}
}
