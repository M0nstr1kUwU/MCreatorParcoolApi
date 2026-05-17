package ${package}.party;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import net.neoforged.fml.loading.FMLPaths;

public final class PartyApiServerConfig {
	private static final Path CONFIG_PATH = FMLPaths.CONFIGDIR.get().resolve("${modid}-party-server.toml");
	private static Config cached;

	private PartyApiServerConfig() {
	}

	public static Config get() {
		if (cached == null) {
			reload();
		}
		return cached;
	}

	public static void reload() {
		Config c = new Config();

		try {
			if (!Files.exists(CONFIG_PATH)) {
				write(c);
			}

			for (String raw : Files.readAllLines(CONFIG_PATH, StandardCharsets.UTF_8)) {
				String line = stripComment(raw).trim();

				if (line.isEmpty() || !line.contains("=")) {
					continue;
				}

				String k = line.substring(0, line.indexOf('=')).trim();
				String v = unquote(line.substring(line.indexOf('=') + 1).trim());

				switch (k) {
					case "party_enabled" -> c.partyEnabled = parseBool(v, c.partyEnabled);
					case "default_show_self" -> c.defaultShowSelf = parseBool(v, c.defaultShowSelf);
					case "default_overlay_x" -> c.defaultOverlayX = parseInt(v, c.defaultOverlayX);
					case "default_overlay_y" -> c.defaultOverlayY = parseInt(v, c.defaultOverlayY);
					case "overlay_nickname_font_scale_percent" -> c.overlayNicknameFontScalePercent = clamp(parseInt(v, c.overlayNicknameFontScalePercent), 40, 200);
					case "invite_cooldown_seconds" -> c.inviteCooldownSeconds = Math.max(0, parseInt(v, c.inviteCooldownSeconds));
					case "invite_gui_enabled" -> c.inviteGuiEnabled = parseBool(v, c.inviteGuiEnabled);
					case "default_max_members" -> c.defaultMaxMembers = clamp(parseInt(v, c.defaultMaxMembers), 1, c.hardMaxMembers);
					case "hard_max_members" -> c.hardMaxMembers = clamp(parseInt(v, c.hardMaxMembers), 1, 200);
					case "admin_permission_level" -> c.adminPermissionLevel = clamp(parseInt(v, c.adminPermissionLevel), 1, 4);
					case "pvp_protection_enabled" -> c.pvpProtectionEnabled = parseBool(v, c.pvpProtectionEnabled);
					case "party_chat_enabled" -> c.partyChatEnabled = parseBool(v, c.partyChatEnabled);
					case "party_chat_prefix" -> c.partyChatPrefix = v;

					case "asset_overlay_panel" -> c.assetOverlayPanel = v;
					case "asset_overlay_member_frame" -> c.assetOverlayMemberFrame = v;
					case "asset_overlay_hp_bar_empty" -> c.assetOverlayHpBarEmpty = v;
					case "asset_overlay_hp_bar_full" -> c.assetOverlayHpBarFull = v;
					case "asset_overlay_absorption_bar_full" -> c.assetOverlayAbsorptionBarFull = v;
					case "asset_overlay_food_bar_empty" -> c.assetOverlayFoodBarEmpty = v;
					case "asset_overlay_food_bar_full" -> c.assetOverlayFoodBarFull = v;
					case "asset_gui_background" -> c.assetGuiBackground = v;
					case "asset_gui_button" -> c.assetGuiButton = v;
					case "asset_gui_button_hover" -> c.assetGuiButtonHover = v;
					case "asset_gui_search" -> c.assetGuiSearch = v;
					case "asset_gui_scrollbar" -> c.assetGuiScrollbar = v;
					case "asset_gui_member_row" -> c.assetGuiMemberRow = v;
					case "asset_gui_button_invite" -> c.assetGuiButtonInvite = v;
					case "asset_gui_button_revoke" -> c.assetGuiButtonRevoke = v;
					case "asset_gui_button_kick" -> c.assetGuiButtonKick = v;
					case "asset_gui_button_pin" -> c.assetGuiButtonPin = v;
					case "asset_gui_button_unpin" -> c.assetGuiButtonUnpin = v;
				}
			}
		} catch (Throwable ignored) {
		}

		c.defaultMaxMembers = clamp(c.defaultMaxMembers, 1, c.hardMaxMembers);
		cached = c;
	}

	public static boolean setPartyEnabled(boolean enabled) {
		Config c = get();
		c.partyEnabled = enabled;
		return save(c);
	}

	public static boolean setDefaultShowSelf(boolean showSelf) {
		Config c = get();
		c.defaultShowSelf = showSelf;
		return save(c);
	}

	public static boolean setDefaultOverlayPosition(int x, int y) {
		Config c = get();
		c.defaultOverlayX = x;
		c.defaultOverlayY = y;
		return save(c);
	}

	public static boolean setInviteCooldownSeconds(int seconds) {
		Config c = get();
		c.inviteCooldownSeconds = Math.max(0, seconds);
		return save(c);
	}

	public static boolean partyEnabled() {
		return get().partyEnabled;
	}

	public static boolean defaultShowSelf() {
		return get().defaultShowSelf;
	}

	public static int defaultOverlayX() {
		return get().defaultOverlayX;
	}

	public static int defaultOverlayY() {
		return get().defaultOverlayY;
	}

	public static int overlayNicknameFontScalePercent() {
		return get().overlayNicknameFontScalePercent;
	}

	public static int inviteCooldownSeconds() {
		return get().inviteCooldownSeconds;
	}

	public static int inviteLifetimeSeconds() {
		return get().inviteCooldownSeconds;
	}

	public static boolean inviteGuiEnabled() {
		return get().inviteGuiEnabled;
	}

	public static int defaultMaxMembers() {
		return get().defaultMaxMembers;
	}

	public static int hardMaxMembers() {
		return get().hardMaxMembers;
	}

	public static int adminPermissionLevel() {
		return get().adminPermissionLevel;
	}

	public static boolean pvpProtectionEnabled() {
		return get().pvpProtectionEnabled;
	}

	public static boolean partyChatEnabled() {
		return get().partyChatEnabled;
	}

	public static String partyChatPrefix() {
		return get().partyChatPrefix;
	}

	private static boolean save(Config c) {
		try {
			write(c);
			cached = c;
			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	private static void write(Config c) throws IOException {
		Files.createDirectories(CONFIG_PATH.getParent());

		String text = """
# ${modid} Party Server Config

party_enabled=%s

# false = player does not see themselves in their own overlay by default.
default_show_self=%s

# Absolute overlay coordinates.
# Default y=74 is about 50px above the old left-center placement.
default_overlay_x=%d
default_overlay_y=%d

# 80 = nickname renders at 80%% scale.
overlay_nickname_font_scale_percent=%d

# While invite is pending, another invite to same target is blocked.
# It can be accepted, declined, revoked, or expired after this time.
invite_cooldown_seconds=%d
invite_gui_enabled=%s

default_max_members=%d
hard_max_members=%d
admin_permission_level=%d

# Guards used by PartyApiPvpGuard / PartyApiChatGuard.
pvp_protection_enabled=%s
party_chat_enabled=%s
party_chat_prefix="%s"

# Optional assets. Empty string = fallback rendering.
# Place in assets/<modid>/textures/gui/party/
asset_overlay_panel="%s"
asset_overlay_member_frame="%s"
asset_overlay_hp_bar_empty="%s"
asset_overlay_hp_bar_full="%s"
asset_overlay_absorption_bar_full="%s"
asset_overlay_food_bar_empty="%s"
asset_overlay_food_bar_full="%s"

asset_gui_background="%s"
asset_gui_button="%s"
asset_gui_button_hover="%s"
asset_gui_search="%s"
asset_gui_scrollbar="%s"
asset_gui_member_row="%s"
asset_gui_button_invite="%s"
asset_gui_button_revoke="%s"
asset_gui_button_kick="%s"
asset_gui_button_pin="%s"
asset_gui_button_unpin="%s"
""".formatted(
			c.partyEnabled,
			c.defaultShowSelf,
			c.defaultOverlayX,
			c.defaultOverlayY,
			c.overlayNicknameFontScalePercent,
			c.inviteCooldownSeconds,
			c.inviteGuiEnabled,
			c.defaultMaxMembers,
			c.hardMaxMembers,
			c.adminPermissionLevel,
			c.pvpProtectionEnabled,
			c.partyChatEnabled,
			c.partyChatPrefix,
			c.assetOverlayPanel,
			c.assetOverlayMemberFrame,
			c.assetOverlayHpBarEmpty,
			c.assetOverlayHpBarFull,
			c.assetOverlayAbsorptionBarFull,
			c.assetOverlayFoodBarEmpty,
			c.assetOverlayFoodBarFull,
			c.assetGuiBackground,
			c.assetGuiButton,
			c.assetGuiButtonHover,
			c.assetGuiSearch,
			c.assetGuiScrollbar,
			c.assetGuiMemberRow,
			c.assetGuiButtonInvite,
			c.assetGuiButtonRevoke,
			c.assetGuiButtonKick,
			c.assetGuiButtonPin,
			c.assetGuiButtonUnpin
		);

		Files.writeString(CONFIG_PATH, text, StandardCharsets.UTF_8);
	}

	private static String stripComment(String s) {
		boolean q = false;

		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);

			if (c == '"') {
				q = !q;
			}

			if (!q && c == '#') {
				return s.substring(0, i);
			}
		}

		return s;
	}

	private static String unquote(String v) {
		v = v.trim();
		return v.length() >= 2 && v.startsWith("\"") && v.endsWith("\"") ? v.substring(1, v.length() - 1) : v;
	}

	private static boolean parseBool(String v, boolean f) {
		if ("true".equalsIgnoreCase(v)) {
			return true;
		}

		if ("false".equalsIgnoreCase(v)) {
			return false;
		}

		return f;
	}

	private static int parseInt(String v, int f) {
		try {
			return Integer.parseInt(v.trim());
		} catch (Throwable ignored) {
			return f;
		}
	}

	private static int clamp(int v, int a, int b) {
		return Math.max(a, Math.min(b, v));
	}

	public static final class Config {
		public boolean partyEnabled = true;
		public boolean defaultShowSelf = false;
		public int defaultOverlayX = 8;
		public int defaultOverlayY = 58;
		public int overlayNicknameFontScalePercent = 80;
		public int inviteCooldownSeconds = 120;
		public boolean inviteGuiEnabled = true;
		public int defaultMaxMembers = 4;
		public int hardMaxMembers = 200;
		public int adminPermissionLevel = 2;
		public boolean pvpProtectionEnabled = true;
		public boolean partyChatEnabled = true;
		public String partyChatPrefix = "!p ";

		public String assetOverlayPanel = "";
		public String assetOverlayMemberFrame = "";
		public String assetOverlayHpBarEmpty = "";
		public String assetOverlayHpBarFull = "";
		public String assetOverlayAbsorptionBarFull = "";
		public String assetOverlayFoodBarEmpty = "";
		public String assetOverlayFoodBarFull = "";

		public String assetGuiBackground = "";
		public String assetGuiButton = "";
		public String assetGuiButtonHover = "";
		public String assetGuiSearch = "";
		public String assetGuiScrollbar = "";
		public String assetGuiMemberRow = "";
		public String assetGuiButtonInvite = "";
		public String assetGuiButtonRevoke = "";
		public String assetGuiButtonKick = "";
		public String assetGuiButtonPin = "";
		public String assetGuiButtonUnpin = "";
	}
}
