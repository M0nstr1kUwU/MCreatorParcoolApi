package ${package}.weight;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import net.neoforged.fml.loading.FMLPaths;

public final class ParCoolApiWeightConfig {
	private static final Path CONFIG_PATH = FMLPaths.CONFIGDIR.get().resolve("${modid}-weight-server.toml");
	private static Config cached;

	private ParCoolApiWeightConfig() {
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
				write(config);
			}

			for (String raw : Files.readAllLines(CONFIG_PATH, StandardCharsets.UTF_8)) {
				String line = raw.split("#", 2)[0].trim();

				if (line.isEmpty() || !line.contains("=")) {
					continue;
				}

				String key = line.substring(0, line.indexOf("=")).trim();
				String value = line.substring(line.indexOf("=") + 1).trim().replace("\"", "");

				switch (key) {
					case "weight_enabled" -> config.weightEnabled = Boolean.parseBoolean(value);
					case "use_default_punishments" -> config.useDefaultPunishments = Boolean.parseBoolean(value);
					case "stage_1_percent" -> config.stage1Percent = parseDouble(value, config.stage1Percent);
					case "stage_2_percent" -> config.stage2Percent = parseDouble(value, config.stage2Percent);
					case "stage_3_percent" -> config.stage3Percent = parseDouble(value, config.stage3Percent);
					case "stage_4_percent" -> config.stage4Percent = parseDouble(value, config.stage4Percent);
					case "stage_1_disable_jump" -> config.stage1DisableJump = Boolean.parseBoolean(value);
					case "stage_2_disable_jump" -> config.stage2DisableJump = Boolean.parseBoolean(value);
					case "stage_3_disable_jump" -> config.stage3DisableJump = Boolean.parseBoolean(value);
					case "stage_4_disable_jump" -> config.stage4DisableJump = Boolean.parseBoolean(value);
					case "stage_4_darkness" -> config.stage4Darkness = Boolean.parseBoolean(value);
					default -> {
					}
				}
			}
		} catch (Throwable ignored) {
		}

		cached = config;
	}

	public static boolean setWeightEnabled(boolean enabled) {
		Config config = get();
		config.weightEnabled = enabled;
		boolean ok = save(config);

		if (ok) {
			try {
				ParCoolApiWeightSystem.onWeightConfigChanged();
			} catch (Throwable ignored) {
			}
		}

		return ok;
	}

	public static boolean setUseDefaultPunishments(boolean enabled) {
		Config config = get();
		config.useDefaultPunishments = enabled;
		boolean ok = save(config);

		if (ok) {
			try {
				ParCoolApiWeightSystem.onWeightConfigChanged();
			} catch (Throwable ignored) {
			}
		}

		return ok;
	}

	public static boolean setPunishmentStage(int stage, double percent, boolean disableJump, boolean darkness) {
		Config config = get();
		double safePercent = Math.max(0.0D, percent);

		switch (stage) {
			case 1 -> {
				config.stage1Percent = safePercent;
				config.stage1DisableJump = disableJump;
			}
			case 2 -> {
				config.stage2Percent = safePercent;
				config.stage2DisableJump = disableJump;
			}
			case 3 -> {
				config.stage3Percent = safePercent;
				config.stage3DisableJump = disableJump;
			}
			case 4 -> {
				config.stage4Percent = safePercent;
				config.stage4DisableJump = disableJump;
				config.stage4Darkness = darkness;
			}
			default -> {
				return false;
			}
		}

		boolean ok = save(config);

		if (ok) {
			try {
				ParCoolApiWeightSystem.onWeightConfigChanged();
			} catch (Throwable ignored) {
			}
		}

		return ok;
	}

	private static boolean save(Config config) {
		try {
			write(config);
			cached = config;
			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	private static void write(Config c) throws IOException {
		Files.createDirectories(CONFIG_PATH.getParent());

		String text = """
# ${modid} Weight Server Config

# false = the weight system is fully disabled:
# - no inventory weight calculation for gameplay state
# - no load percent/status
# - no default punishments
# - no ParCool restrictions
# - no vanilla jump restriction
weight_enabled=%s

# true = built-in punishment logic from plugin
# false = plugin only calculates weight/status; you implement punishments through procedure blocks/triggers
use_default_punishments=%s

stage_1_percent=%.2f
stage_2_percent=%.2f
stage_3_percent=%.2f
stage_4_percent=%.2f

stage_1_disable_jump=%s
stage_2_disable_jump=%s
stage_3_disable_jump=%s
stage_4_disable_jump=%s
stage_4_darkness=%s
""".formatted(
			c.weightEnabled,
			c.useDefaultPunishments,
			c.stage1Percent,
			c.stage2Percent,
			c.stage3Percent,
			c.stage4Percent,
			c.stage1DisableJump,
			c.stage2DisableJump,
			c.stage3DisableJump,
			c.stage4DisableJump,
			c.stage4Darkness
		);

		Files.writeString(CONFIG_PATH, text, StandardCharsets.UTF_8);
	}

	private static double parseDouble(String value, double fallback) {
		try {
			return Double.parseDouble(value);
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	public static final class Config {
		public boolean weightEnabled = true;
		public boolean useDefaultPunishments = true;

		public double stage1Percent = 75.0D;
		public double stage2Percent = 125.0D;
		public double stage3Percent = 175.0D;
		public double stage4Percent = 200.0D;

		public boolean stage1DisableJump = false;
		public boolean stage2DisableJump = true;
		public boolean stage3DisableJump = true;
		public boolean stage4DisableJump = true;
		public boolean stage4Darkness = true;
	}
}