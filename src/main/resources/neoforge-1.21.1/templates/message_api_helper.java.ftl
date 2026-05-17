package ${package}.message;

import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.MutableComponent;
import net.minecraft.network.chat.Style;
import net.minecraft.network.chat.TextColor;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;

import net.neoforged.neoforge.server.ServerLifecycleHooks;

public final class MessageApiHelper {
	private MessageApiHelper() {
	}

	public static MutableComponent styled(
		String text,
		String color,
		boolean bold,
		boolean italic,
		boolean underlined,
		boolean strikethrough,
		boolean obfuscated
	) {
		Style style = Style.EMPTY
			.withBold(bold)
			.withItalic(italic)
			.withUnderlined(underlined)
			.withStrikethrough(strikethrough)
			.withObfuscated(obfuscated);

		TextColor parsedColor = parseColor(color);

		if (parsedColor != null) {
			style = style.withColor(parsedColor);
		}

		return Component.literal(text == null ? "" : text).setStyle(style);
	}

	public static boolean sendToEntity(Entity entity, Component message, boolean actionBar) {
		if (entity instanceof ServerPlayer serverPlayer) {
			serverPlayer.displayClientMessage(message, actionBar);
			return true;
		}

		return false;
	}

	public static int broadcast(Component message, boolean actionBar) {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return 0;
		}

		int sent = 0;

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			player.displayClientMessage(message, actionBar);
			sent++;
		}

		return sent;
	}

	public static int sendToOperators(Component message, boolean actionBar, int permissionLevel) {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return 0;
		}

		int sent = 0;
		int level = Math.max(1, Math.min(4, permissionLevel));

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			if (player.hasPermissions(level)) {
				player.displayClientMessage(message, actionBar);
				sent++;
			}
		}

		return sent;
	}

	public static int sendNearby(Entity center, double radius, Component message, boolean actionBar) {
		if (center == null || center.level().isClientSide()) {
			return 0;
		}

		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return 0;
		}

		double safeRadius = Math.max(0.0D, radius);
		double radiusSq = safeRadius * safeRadius;
		int sent = 0;

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			if (player.level() == center.level() && player.distanceToSqr(center) <= radiusSq) {
				player.displayClientMessage(message, actionBar);
				sent++;
			}
		}

		return sent;
	}

	public static MutableComponent prefix(Component prefix, Component message) {
		MutableComponent result = Component.empty();

		if (prefix != null) {
			result.append(prefix);
		}

		if (message != null) {
			result.append(message);
		}

		return result;
	}

	private static TextColor parseColor(String color) {
		if (color == null || color.isBlank()) {
			return null;
		}

		String value = color.trim();

		if (value.startsWith("#")) {
			value = value.substring(1);
		}

		if (value.startsWith("0x") || value.startsWith("0X")) {
			value = value.substring(2);
		}

		if (value.length() != 6) {
			return null;
		}

		try {
			return TextColor.fromRgb(Integer.parseInt(value, 16));
		} catch (Throwable ignored) {
			return null;
		}
	}
}