package ${package}.party;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public final class PartyApiServerConfig {
	private static final Path CONFIG_PATH = java.nio.file.Paths.get("config", "${modid}-party-server.toml");

	private static boolean loaded = false;

	private static boolean defaultPartySystemEnabled = true;
	private static boolean inviteGuiEnabled = true;
	private static boolean pvpProtectionEnabled = true;
	private static boolean partyChatEnabled = true;

	private static int defaultMaxMembers = 4;
	private static int hardMaxMembers = 200;
	private static int adminPermissionLevel = 2;
	private static int inviteLifetimeSeconds = 120;

	private static String partyChatPrefix = "!";

	private PartyApiServerConfig() {
	}

	public static synchronized void reload() {
		loaded = false;
		loadIfNeeded();
	}

	public static synchronized void loadIfNeeded() {
		if (loaded) {
			return;
		}

		loaded = true;

		try {
			if (!Files.exists(CONFIG_PATH)) {
				writeDefaultConfig();
				return;
			}

			for (String originalLine : Files.readAllLines(CONFIG_PATH, StandardCharsets.UTF_8)) {
				String line = stripComment(originalLine).trim();

				if (line.isEmpty() || !line.contains("=")) {
					continue;
				}

				String[] parts = line.split("=", 2);
				String key = parts[0].trim();
				String value = parts[1].trim();

				switch (key) {
					case "default_party_system_enabled" -> defaultPartySystemEnabled = parseBoolean(value, defaultPartySystemEnabled);
					case "invite_gui_enabled" -> inviteGuiEnabled = parseBoolean(value, inviteGuiEnabled);
					case "pvp_protection_enabled" -> pvpProtectionEnabled = parseBoolean(value, pvpProtectionEnabled);
					case "party_chat_enabled" -> partyChatEnabled = parseBoolean(value, partyChatEnabled);

					case "default_max_members" -> defaultMaxMembers = clamp(parseInt(value, defaultMaxMembers), 1, hardMaxMembers);
					case "hard_max_members" -> hardMaxMembers = Math.max(1, parseInt(value, hardMaxMembers));
					case "admin_permission_level" -> adminPermissionLevel = clamp(parseInt(value, adminPermissionLevel), 0, 4);
					case "invite_lifetime_seconds" -> inviteLifetimeSeconds = clamp(parseInt(value, inviteLifetimeSeconds), 5, 3600);

					case "party_chat_prefix" -> partyChatPrefix = parseString(value, partyChatPrefix);
					default -> {
					}
				}
			}

			defaultMaxMembers = clamp(defaultMaxMembers, 1, hardMaxMembers);
		} catch (Throwable ignored) {
		}
	}

	public static boolean defaultPartySystemEnabled() {
		loadIfNeeded();
		return defaultPartySystemEnabled;
	}

	public static boolean inviteGuiEnabled() {
		loadIfNeeded();
		return inviteGuiEnabled;
	}

	public static boolean pvpProtectionEnabled() {
		loadIfNeeded();
		return pvpProtectionEnabled;
	}

	public static boolean partyChatEnabled() {
		loadIfNeeded();
		return partyChatEnabled;
	}

	public static int defaultMaxMembers() {
		loadIfNeeded();
		return defaultMaxMembers;
	}

	public static int hardMaxMembers() {
		loadIfNeeded();
		return hardMaxMembers;
	}

	public static int adminPermissionLevel() {
		loadIfNeeded();
		return adminPermissionLevel;
	}

	public static int inviteLifetimeSeconds() {
		loadIfNeeded();
		return inviteLifetimeSeconds;
	}

	public static String partyChatPrefix() {
		loadIfNeeded();
		return partyChatPrefix == null ? "!" : partyChatPrefix;
	}

	private static void writeDefaultConfig() throws IOException {
		Files.createDirectories(CONFIG_PATH.getParent());

		String text = """
			# ${modid} Party Server Config
			#
			# This file is loaded from the server/game config folder.
			# Change values, then restart server or run /party admin reloadconfig.

			default_party_system_enabled = true
			invite_gui_enabled = true
			pvp_protection_enabled = true
			party_chat_enabled = true

			default_max_members = 4
			hard_max_members = 200
			admin_permission_level = 2
			invite_lifetime_seconds = 120

			# Messages starting with this prefix are sent only to party members.
			# Example: !hello party
			party_chat_prefix = "!"
			""";

		Files.writeString(CONFIG_PATH, text, StandardCharsets.UTF_8);
	}

	private static String stripComment(String line) {
		int index = line.indexOf('#');
		return index >= 0 ? line.substring(0, index) : line;
	}

	private static boolean parseBoolean(String value, boolean fallback) {
		String normalized = value.trim().toLowerCase(java.util.Locale.ROOT);

		return switch (normalized) {
			case "true", "yes", "1", "on" -> true;
			case "false", "no", "0", "off" -> false;
			default -> fallback;
		};
	}

	private static int parseInt(String value, int fallback) {
		try {
			return Integer.parseInt(value.trim());
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	private static String parseString(String value, String fallback) {
		String trimmed = value.trim();

		if (trimmed.length() >= 2 && trimmed.startsWith("\"") && trimmed.endsWith("\"")) {
			return trimmed.substring(1, trimmed.length() - 1);
		}

		return trimmed.isEmpty() ? fallback : trimmed;
	}

	private static int clamp(int value, int min, int max) {
		return Math.max(min, Math.min(max, value));
	}
}
