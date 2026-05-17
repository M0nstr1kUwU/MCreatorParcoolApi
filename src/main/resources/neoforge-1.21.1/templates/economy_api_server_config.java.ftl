package ${package}.economy;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import net.neoforged.fml.loading.FMLPaths;

public final class EconomyApiServerConfig {
	private static final Path CONFIG_PATH = FMLPaths.CONFIGDIR.get().resolve("${modid}-economy-server.toml");

	private static Config cached;

	private EconomyApiServerConfig() {
	}

	public static Config get() {
		if (cached == null) {
			reload();
		}

		return cached;
	}

	public static void reload() {
		Config config = new Config();

		try {
			if (!Files.exists(CONFIG_PATH)) {
				writeDefault(config);
			}

			for (String rawLine : Files.readAllLines(CONFIG_PATH, StandardCharsets.UTF_8)) {
				String line = stripComment(rawLine).trim();

				if (line.isEmpty() || !line.contains("=")) {
					continue;
				}

				String key = line.substring(0, line.indexOf('=')).trim();
				String value = unquote(line.substring(line.indexOf('=') + 1).trim());

				switch (key) {
					case "economy_enabled" -> config.economyEnabled = parseBoolean(value, config.economyEnabled);
					case "casino_enabled" -> config.casinoEnabled = parseBoolean(value, config.casinoEnabled);
					case "auto_compact_display" -> config.autoCompactDisplay = parseBoolean(value, config.autoCompactDisplay);
					case "death_wallet_loss_percent" -> config.deathWalletLossPercent = clamp(parseDouble(value, config.deathWalletLossPercent), 0.0D, 100.0D);
					case "transfer_fee_percent" -> config.transferFeePercent = clamp(parseDouble(value, config.transferFeePercent), 0.0D, 100.0D);
					case "casino_house_edge_percent" -> config.casinoHouseEdgePercent = clamp(parseDouble(value, config.casinoHouseEdgePercent), 0.0D, 99.0D);
					case "casino_min_bet_cooper" -> config.casinoMinBetCooper = Math.max(0L, parseLong(value, config.casinoMinBetCooper));
					case "casino_max_bet_cooper" -> config.casinoMaxBetCooper = Math.max(config.casinoMinBetCooper, parseLong(value, config.casinoMaxBetCooper));
					case "coin_item_cooper" -> config.coinItemCooper = normalizeItemId(value, config.coinItemCooper);
					case "coin_item_iron" -> config.coinItemIron = normalizeItemId(value, config.coinItemIron);
					case "coin_item_gold" -> config.coinItemGold = normalizeItemId(value, config.coinItemGold);
					case "coin_item_platine" -> config.coinItemPlatine = normalizeItemId(value, config.coinItemPlatine);
					default -> {
					}
				}
			}
		} catch (Throwable ignored) {
		}

		cached = config;
	}

	public static boolean setEconomyEnabled(boolean enabled) {
		Config config = get();
		config.economyEnabled = enabled;
		return save(config);
	}

	public static boolean setCasinoEnabled(boolean enabled) {
		Config config = get();
		config.casinoEnabled = enabled;
		return save(config);
	}

	public static boolean setTransferFeePercent(double percent) {
		Config config = get();
		config.transferFeePercent = clamp(percent, 0.0D, 100.0D);
		return save(config);
	}

	public static boolean setDeathWalletLossPercent(double percent) {
		Config config = get();
		config.deathWalletLossPercent = clamp(percent, 0.0D, 100.0D);
		return save(config);
	}

	public static boolean setCasinoHouseEdgePercent(double percent) {
		Config config = get();
		config.casinoHouseEdgePercent = clamp(percent, 0.0D, 99.0D);
		return save(config);
	}

	public static boolean setCasinoBetLimits(long minBetCooper, long maxBetCooper) {
		Config config = get();
		config.casinoMinBetCooper = Math.max(0L, minBetCooper);
		config.casinoMaxBetCooper = Math.max(config.casinoMinBetCooper, maxBetCooper);
		return save(config);
	}

	public static boolean setCoinItem(String coin, String itemId) {
		Config config = get();
		String normalized = normalizeItemId(itemId, "");

		if (normalized.isBlank()) {
			return false;
		}

		switch (normalizeCoin(coin)) {
			case "COOPER" -> config.coinItemCooper = normalized;
			case "IRON" -> config.coinItemIron = normalized;
			case "GOLD" -> config.coinItemGold = normalized;
			case "PLATINE" -> config.coinItemPlatine = normalized;
			default -> {
				return false;
			}
		}

		return save(config);
	}

	public static String getCoinItem(String coin) {
		Config config = get();

		return switch (normalizeCoin(coin)) {
			case "COOPER" -> config.coinItemCooper;
			case "IRON" -> config.coinItemIron;
			case "GOLD" -> config.coinItemGold;
			case "PLATINE" -> config.coinItemPlatine;
			default -> "";
		};
	}

	private static boolean save(Config config) {
		try {
			writeDefault(config);
			cached = config;
			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	private static void writeDefault(Config config) throws IOException {
		Files.createDirectories(CONFIG_PATH.getParent());

		String text = """
			# ${modid} Economy Server Config
			# Currency rates:
			# 100 Cooper = 1 Iron
			# 100 Iron = 1 Gold
			# 1000 Gold = 1 Platine
			#
			# All internal balances are stored in Cooper units.
			# Coin item ids are used by deposit/withdraw item coin blocks and commands.

			economy_enabled=%s
			casino_enabled=%s
			auto_compact_display=%s

			death_wallet_loss_percent=%.4f
			transfer_fee_percent=%.4f

			casino_house_edge_percent=%.4f
			casino_min_bet_cooper=%d
			casino_max_bet_cooper=%d

			coin_item_cooper="%s"
			coin_item_iron="%s"
			coin_item_gold="%s"
			coin_item_platine="%s"
			""".formatted(
				config.economyEnabled,
				config.casinoEnabled,
				config.autoCompactDisplay,
				config.deathWalletLossPercent,
				config.transferFeePercent,
				config.casinoHouseEdgePercent,
				config.casinoMinBetCooper,
				config.casinoMaxBetCooper,
				config.coinItemCooper,
				config.coinItemIron,
				config.coinItemGold,
				config.coinItemPlatine
			);

		Files.writeString(CONFIG_PATH, text, StandardCharsets.UTF_8);
	}

	private static String stripComment(String line) {
		boolean quoted = false;

		for (int i = 0; i < line.length(); i++) {
			char c = line.charAt(i);

			if (c == '"') {
				quoted = !quoted;
			}

			if (!quoted && c == '#') {
				return line.substring(0, i);
			}
		}

		return line;
	}

	private static String unquote(String value) {
		String trimmed = value.trim();

		if (trimmed.length() >= 2 && trimmed.startsWith("\"") && trimmed.endsWith("\"")) {
			return trimmed.substring(1, trimmed.length() - 1);
		}

		return trimmed;
	}

	private static boolean parseBoolean(String value, boolean fallback) {
		if ("true".equalsIgnoreCase(value)) {
			return true;
		}

		if ("false".equalsIgnoreCase(value)) {
			return false;
		}

		return fallback;
	}

	private static double parseDouble(String value, double fallback) {
		try {
			return Double.parseDouble(value);
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	private static long parseLong(String value, long fallback) {
		try {
			return Long.parseLong(value);
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	private static double clamp(double value, double min, double max) {
		return Math.max(min, Math.min(max, value));
	}

	private static String normalizeCoin(String coin) {
		if (coin == null) {
			return "";
		}

		String normalized = coin.trim().toUpperCase(java.util.Locale.ROOT);

		if ("COPPER".equals(normalized)) {
			return "COOPER";
		}

		if ("PLATINUM".equals(normalized) || "PLATIN".equals(normalized)) {
			return "PLATINE";
		}

		return normalized;
	}

	private static String normalizeItemId(String value, String fallback) {
		if (value == null || value.isBlank()) {
			return fallback;
		}

		String trimmed = value.trim().toLowerCase(java.util.Locale.ROOT);

		if (!trimmed.contains(":")) {
			trimmed = "minecraft:" + trimmed;
		}

		return trimmed;
	}

	public static final class Config {
		public boolean economyEnabled = true;
		public boolean casinoEnabled = true;
		public boolean autoCompactDisplay = true;

		public double deathWalletLossPercent = 25.0D;
		public double transferFeePercent = 10.0D;
		public double casinoHouseEdgePercent = 5.0D;

		public long casinoMinBetCooper = 100L;
		public long casinoMaxBetCooper = 1_000_000L;

		public String coinItemCooper = "minecraft:copper_coin_item";
		public String coinItemIron = "minecraft:iron_coin_item";
		public String coinItemGold = "minecraft:gold_coin_item";
		public String coinItemPlatine = "minecraft:netherite_coin_item";
	}
}
