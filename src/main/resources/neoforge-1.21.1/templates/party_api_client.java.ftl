package ${package}.client;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.components.Renderable;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;

import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.RegisterGuiLayersEvent;

@EventBusSubscriber(modid = "${modid}", value = Dist.CLIENT, bus = EventBusSubscriber.Bus.MOD)
public final class PartyApiClient {
	private static String partyId = "";
	private static String leaderId = "";
	private static boolean pvpEnabled = false;
	private static String overlayPosition = "CUSTOM";
	private static int overlayX = 8;
	private static int overlayY = 58;
	private static int nicknameScalePercent = 80;
	private static boolean showSelf = false;
	private static boolean isAdmin = false;

	private static final List<${package}.network.PartyApiNetwork.MemberSyncData> MEMBERS = new ArrayList<>();
	private static final List<${package}.network.PartyApiNetwork.OverlayElementPositionSyncData> ELEMENT_POSITIONS = new ArrayList<>();
	private static final List<${package}.network.PartyApiNetwork.CustomOverlayEntrySyncData> CUSTOM_ENTRIES = new ArrayList<>();
	private static final List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> ONLINE_PLAYERS = new ArrayList<>();

	private static final Map<ResourceLocation, Boolean> TEXTURE_EXISTS_CACHE = new HashMap<>();

	// Overlay assets.
	private static final ResourceLocation OVERLAY_MEMBER_FRAME = partyTexture("overlay_member_frame.png");
	private static final ResourceLocation OVERLAY_MEMBER_FRAME_LEADER = partyTexture("overlay_member_frame_leader.png");
	private static final ResourceLocation OVERLAY_HP_EMPTY = partyTexture("overlay_hp_empty.png");
	private static final ResourceLocation OVERLAY_HP_FULL = partyTexture("overlay_hp_full.png");
	private static final ResourceLocation OVERLAY_ABSORPTION = partyTexture("overlay_absorption.png");
	private static final ResourceLocation OVERLAY_FOOD_EMPTY = partyTexture("overlay_food_empty.png");
	private static final ResourceLocation OVERLAY_FOOD_FULL = partyTexture("overlay_food_full.png");
	private static final ResourceLocation OVERLAY_CUSTOM_BAR_EMPTY = partyTexture("overlay_custom_bar_empty.png");
	private static final ResourceLocation OVERLAY_CUSTOM_BAR_FULL = partyTexture("overlay_custom_bar_full.png");
	private static final ResourceLocation OVERLAY_VALUE_FRAME = partyTexture("overlay_value_frame.png");

	// Screen backgrounds.
	private static final ResourceLocation GUI_BACKGROUND = partyTexture("gui_background.png");
	private static final ResourceLocation GUI_MAIN_BACKGROUND = partyTexture("gui_main_background.png");
	private static final ResourceLocation GUI_INVITE_BACKGROUND = partyTexture("gui_invite_background.png");
	private static final ResourceLocation GUI_SETTINGS_BACKGROUND = partyTexture("gui_settings_background.png");
	private static final ResourceLocation GUI_ADMIN_BACKGROUND = partyTexture("gui_admin_background.png");
	private static final ResourceLocation GUI_INVITE_POPUP_BACKGROUND = partyTexture("gui_invite_popup_background.png");

	// Rows / fields.
	private static final ResourceLocation GUI_MEMBER_FRAME = partyTexture("gui_member_frame.png");
	private static final ResourceLocation GUI_ONLINE_PLAYER_ROW = partyTexture("gui_online_player_row.png");
	private static final ResourceLocation GUI_ADMIN_PLAYER_ROW = partyTexture("gui_admin_player_row.png");
	private static final ResourceLocation GUI_SEARCH = partyTexture("gui_search.png");
	private static final ResourceLocation GUI_SCROLLBAR_TRACK = partyTexture("gui_scrollbar_track.png");
	private static final ResourceLocation GUI_SCROLLBAR_THUMB = partyTexture("gui_scrollbar_thumb.png");

	// Generic buttons.
	private static final ResourceLocation GUI_BUTTON = partyTexture("gui_button.png");
	private static final ResourceLocation GUI_BUTTON_HOVER = partyTexture("gui_button_hover.png");
	private static final ResourceLocation GUI_BUTTON_DISABLED = partyTexture("gui_button_disabled.png");

	private PartyApiClient() {
	}

	@SubscribeEvent
	public static void registerGuiLayers(RegisterGuiLayersEvent event) {
		event.registerAboveAll(
			ResourceLocation.fromNamespaceAndPath("${modid}", "party_overlay"),
			(guiGraphics, deltaTracker) -> renderOverlay(guiGraphics)
		);
	}

	public static void acceptSync(${package}.network.PartyApiNetwork.SyncPartyPayload payload) {
		partyId = payload.partyId();
		leaderId = payload.leaderId();
		pvpEnabled = payload.pvpEnabled();
		overlayPosition = payload.overlayPosition();
		overlayX = payload.overlayX();
		overlayY = payload.overlayY();
		nicknameScalePercent = Math.max(40, Math.min(200, payload.nicknameScalePercent()));
		showSelf = payload.showSelf();
		isAdmin = payload.admin();

		MEMBERS.clear();
		MEMBERS.addAll(payload.members() == null ? List.of() : payload.members());

		ELEMENT_POSITIONS.clear();
		ELEMENT_POSITIONS.addAll(payload.elementPositions() == null ? List.of() : payload.elementPositions());

		CUSTOM_ENTRIES.clear();
		CUSTOM_ENTRIES.addAll(payload.customEntries() == null ? List.of() : payload.customEntries());
	}

	public static void acceptOnlinePlayers(List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> players) {
		ONLINE_PLAYERS.clear();
		ONLINE_PLAYERS.addAll(players == null ? List.of() : players);
	}

	public static void openPartyScreen() {
		openPartyScreen("MAIN");
	}

	public static void openPartyScreen(String screen) {
		Minecraft minecraft = Minecraft.getInstance();

		if (minecraft == null) {
			return;
		}

		String normalized = screen == null ? "MAIN" : screen.toUpperCase(Locale.ROOT);

		switch (normalized) {
			case "INVITE" -> minecraft.setScreen(new PartyInviteListScreen());
			case "SETTINGS" -> minecraft.setScreen(new PartySettingsScreen());
			case "ADMIN" -> minecraft.setScreen(new PartyAdminScreen());
			default -> minecraft.setScreen(new PartyMainScreen());
		}
	}

	public static void openPartyInviteScreen(String inviterName) {
		Minecraft minecraft = Minecraft.getInstance();

		if (minecraft != null) {
			minecraft.setScreen(new PartyInvitePopupScreen(inviterName == null ? "Unknown" : inviterName));
		}
	}

	private static ResourceLocation partyTexture(String fileName) {
		return ResourceLocation.fromNamespaceAndPath("${modid}", "textures/gui/party/" + fileName);
	}

	private static ResourceLocation buttonTexture(String id) {
		return partyTexture("button_" + id + ".png");
	}

	private static ResourceLocation buttonHoverTexture(String id) {
		return partyTexture("button_" + id + "_hover.png");
	}

	private static ResourceLocation buttonDisabledTexture(String id) {
		return partyTexture("button_" + id + "_disabled.png");
	}

	private static boolean textureExists(ResourceLocation location) {
		try {
			if (TEXTURE_EXISTS_CACHE.containsKey(location)) {
				return TEXTURE_EXISTS_CACHE.get(location);
			}

			Minecraft minecraft = Minecraft.getInstance();
			boolean exists = minecraft != null && minecraft.getResourceManager().getResource(location).isPresent();

			TEXTURE_EXISTS_CACHE.put(location, exists);
			return exists;
		} catch (Throwable ignored) {
			TEXTURE_EXISTS_CACHE.put(location, false);
			return false;
		}
	}

	private static boolean drawTexture(GuiGraphics graphics, ResourceLocation texture, int x, int y, int width, int height, int textureWidth, int textureHeight) {
		if (width <= 0 || height <= 0 || textureWidth <= 0 || textureHeight <= 0 || !textureExists(texture)) {
			return false;
		}

		boolean pushed = false;

		try {
			/*
			 * IMPORTANT:
			 * GuiGraphics#blit(ResourceLocation, x, y, u, v, width, height, textureWidth, textureHeight)
			 * uses "width" and "height" both as the drawn size and as the sampled source size.
			 *
			 * If we pass a drawn size larger than the real PNG size, the UV area becomes larger than
			 * the texture itself. Depending on texture wrapping this looks like repeated / clipped
			 * fragments instead of a stretched image.
			 *
			 * So for GUI backgrounds, rows and scalable panels we draw the PNG at its real native size
			 * and stretch it with the pose matrix. The sampled source area always stays exactly:
			 * 0..textureWidth, 0..textureHeight.
			 */
			float scaleX = width / (float) textureWidth;
			float scaleY = height / (float) textureHeight;

			graphics.pose().pushPose();
			pushed = true;
			graphics.pose().translate(x, y, 0.0F);
			graphics.pose().scale(scaleX, scaleY, 1.0F);
			graphics.blit(texture, 0, 0, 0, 0, textureWidth, textureHeight, textureWidth, textureHeight);
			graphics.pose().popPose();
			pushed = false;
			return true;
		} catch (Throwable ignored) {
			if (pushed) {
				try {
					graphics.pose().popPose();
				} catch (Throwable ignoredAgain) {
				}
			}

			return false;
		}
	}

	private static boolean drawTexturePart(GuiGraphics graphics, ResourceLocation texture, int x, int y, int width, int height, int textureWidth, int textureHeight) {
		if (width <= 0 || height <= 0 || !textureExists(texture)) {
			return false;
		}

		try {
			graphics.blit(texture, x, y, 0, 0, width, height, textureWidth, textureHeight);
			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	private static boolean drawScreenBackground(GuiGraphics graphics, ResourceLocation specificTexture, int screenWidth, int screenHeight) {
		// Background textures are authored as 320x180 and stretched to the current scaled GUI size.
		// This keeps one predictable asset size while still supporting different screen resolutions.
		if (drawTexture(graphics, specificTexture, 0, 0, screenWidth, screenHeight, 320, 180)) {
			return true;
		}

		if (drawTexture(graphics, GUI_BACKGROUND, 0, 0, screenWidth, screenHeight, 320, 180)) {
			return true;
		}

		graphics.fill(0, 0, screenWidth, screenHeight, 0xAA050507);
		return false;
	}

	private static boolean drawButtonTexture(GuiGraphics graphics, ResourceLocation texture, int x, int y, int width, int height) {
		return drawTexture(graphics, texture, x, y, width, height, width, height);
	}

	private static float parseFloat(String value, float fallback) {
		try {
			return Float.parseFloat(value);
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	private static int clampWidthByRatio(int width, float ratio) {
		return Math.max(0, Math.min(width, Math.round(width * Math.max(0.0F, Math.min(1.0F, ratio)))));
	}

	private static void renderOverlay(GuiGraphics graphics) {
		Minecraft minecraft = Minecraft.getInstance();

		if (minecraft == null || minecraft.player == null || minecraft.options.hideGui || MEMBERS.isEmpty()) {
			return;
		}

		List<${package}.network.PartyApiNetwork.MemberSyncData> pinned = MEMBERS.stream()
			.filter(${package}.network.PartyApiNetwork.MemberSyncData::pinned)
			.limit(4)
			.toList();

		if (pinned.isEmpty()) {
			pinned = MEMBERS.stream().limit(4).toList();
		}

		int panelWidth = 96;
		int rowHeight = 22;
		int x = overlayX;
		int y = overlayY;

		for (int i = 0; i < pinned.size(); i++) {
			renderOverlayMember(graphics, minecraft, pinned.get(i), x, y + i * rowHeight, panelWidth);
		}

		for (${package}.network.PartyApiNetwork.CustomOverlayEntrySyncData entry : CUSTOM_ENTRIES) {
			renderCustomEntry(graphics, minecraft, entry, x, y);
		}
	}

	private static void renderOverlayMember(GuiGraphics graphics, Minecraft minecraft, ${package}.network.PartyApiNetwork.MemberSyncData member, int x, int y, int width) {
		ResourceLocation frame = member.leader() && textureExists(OVERLAY_MEMBER_FRAME_LEADER) ? OVERLAY_MEMBER_FRAME_LEADER : OVERLAY_MEMBER_FRAME;
		boolean customFrame = drawTexture(graphics, frame, x, y, width, 19, 96, 19);

		if (!customFrame) {
			int background = 0x78000000;
			int border = member.leader() ? 0xFFE6C75A : 0xFF555555;

			graphics.fill(x, y, x + width, y + 19, background);
			graphics.fill(x, y, x + width, y + 1, border);
			graphics.fill(x, y + 18, x + width, y + 19, border);
			graphics.fill(x, y, x + 1, y + 19, border);
			graphics.fill(x + width - 1, y, x + width, y + 19, border);
		}

		String name = member.name();

		if (name.length() > 11) {
			name = name.substring(0, 10) + "…";
		}

		float scale = Math.max(0.4F, Math.min(2.0F, nicknameScalePercent / 100.0F));
		graphics.pose().pushPose();
		graphics.pose().translate(x + 4, y + 2, 0);
		graphics.pose().scale(scale, scale, 1.0F);
		graphics.drawString(minecraft.font, name, 0, 0, 0xFFFFFFFF, false);
		graphics.pose().popPose();

		String lvl = member.stats().getOrDefault("LVL", member.stats().getOrDefault("lvl", ""));

		if (!lvl.isBlank()) {
			String lvlText = "LVL " + lvl;
			graphics.drawString(minecraft.font, lvlText, x + width - 4 - minecraft.font.width(lvlText), y + 2, 0xFFE6C75A, false);
		}

		int barX = x + 4;
		int hpY = y + 11;
		int foodY = y + 15;
		int barWidth = width - 8;

		float hpRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.health() / member.maxHealth()));
		float absorptionRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.absorption() / member.maxHealth()));
		float foodRatio = Math.max(0.0F, Math.min(1.0F, member.food() / 20.0F));

		int hpWidth = clampWidthByRatio(barWidth, hpRatio);
		int absorptionWidth = clampWidthByRatio(barWidth, absorptionRatio);
		int foodWidth = clampWidthByRatio(barWidth, foodRatio);

		if (!drawTexture(graphics, OVERLAY_HP_EMPTY, barX, hpY, barWidth, 3, 88, 3)) {
			graphics.fill(barX, hpY, barX + barWidth, hpY + 3, 0xFF321010);
		}

		if (!drawTexturePart(graphics, OVERLAY_HP_FULL, barX, hpY, hpWidth, 3, 88, 3)) {
			graphics.fill(barX, hpY, barX + hpWidth, hpY + 3, 0xFFB93A3A);
		}

		if (absorptionWidth > 0) {
			if (!drawTexturePart(graphics, OVERLAY_ABSORPTION, barX, hpY, Math.min(barWidth, absorptionWidth), 3, 88, 3)) {
				graphics.fill(barX, hpY, barX + Math.min(barWidth, absorptionWidth), hpY + 3, 0x55FFD966);
				graphics.fill(barX, hpY, barX + Math.min(barWidth, absorptionWidth), hpY + 1, 0xAAFFD966);
			}
		}

		if (!drawTexture(graphics, OVERLAY_FOOD_EMPTY, barX, foodY, barWidth, 2, 88, 2)) {
			graphics.fill(barX, foodY, barX + barWidth, foodY + 2, 0xFF2B1B0B);
		}

		if (!drawTexturePart(graphics, OVERLAY_FOOD_FULL, barX, foodY, foodWidth, 2, 88, 2)) {
			graphics.fill(barX, foodY, barX + foodWidth, foodY + 2, 0xFFC9823A);
		}
	}

	private static void renderCustomEntry(GuiGraphics graphics, Minecraft minecraft, ${package}.network.PartyApiNetwork.CustomOverlayEntrySyncData entry, int baseX, int baseY) {
		int x = baseX + entry.x();
		int y = baseY + entry.y();

		if ("BAR".equalsIgnoreCase(entry.type())) {
			float current = parseFloat(entry.value(), 0.0F);
			float max = Math.max(1.0F, parseFloat(entry.max(), 1.0F));
			int w = entry.width();
			int h = entry.height();
			int fill = clampWidthByRatio(w, current / max);

			if (!drawTexture(graphics, OVERLAY_CUSTOM_BAR_EMPTY, x, y, w, h, w, h)) {
				graphics.fill(x, y, x + w, y + h, 0xAA222222);
			}

			if (!drawTexturePart(graphics, OVERLAY_CUSTOM_BAR_FULL, x, y, fill, h, w, h)) {
				graphics.fill(x, y, x + fill, y + h, 0xFF55AAFF);
			}

			graphics.drawString(minecraft.font, entry.label(), x, y - 9, 0xFFFFFFFF, false);
		} else {
			int textWidth = minecraft.font.width(entry.label() + ": " + entry.value());
			drawTexture(graphics, OVERLAY_VALUE_FRAME, x - 2, y - 2, Math.max(entry.width(), textWidth + 4), Math.max(entry.height(), 12), Math.max(entry.width(), textWidth + 4), Math.max(entry.height(), 12));
			graphics.drawString(minecraft.font, entry.label() + ": " + entry.value(), x, y, 0xFFFFFFFF, false);
		}
	}


	private static void renderScrollBar(GuiGraphics graphics, int x, int y, int height, int totalRows, int visibleRows, int scroll) {
		if (totalRows <= visibleRows || height <= 0) {
			return;
		}

		if (!drawTexture(graphics, GUI_SCROLLBAR_TRACK, x, y, 6, height, 6, 120)) {
			graphics.fill(x, y, x + 6, y + height, 0x66000000);
		}

		int thumbHeight = Math.max(12, Math.min(height, Math.round(height * (visibleRows / (float) totalRows))));
		int maxScroll = Math.max(1, totalRows - visibleRows);
		int thumbY = y + Math.round((height - thumbHeight) * (Math.max(0, Math.min(maxScroll, scroll)) / (float) maxScroll));

		if (!drawTexture(graphics, GUI_SCROLLBAR_THUMB, x, thumbY, 6, thumbHeight, 6, 20)) {
			graphics.fill(x, thumbY, x + 6, thumbY + thumbHeight, 0xFFAAAAAA);
		}
	}

	private static void renderSmallBar(GuiGraphics graphics, int x, int y, int width, int height, float ratio, int emptyColor, int fillColor) {
		int w = clampWidthByRatio(width, ratio);
		graphics.fill(x, y, x + width, y + height, emptyColor);
		graphics.fill(x, y, x + w, y + height, fillColor);
	}

	private static Button apiButton(String id, String text, int x, int y, int width, int height, Button.OnPress onPress) {
		return apiButton(id, text, x, y, width, height, onPress, true);
	}

	private static Button apiButton(String id, String text, int x, int y, int width, int height, Button.OnPress onPress, boolean active) {
		TexturedButton button = new TexturedButton(
			x, y, width, height,
			Component.literal(text),
			onPress,
			buttonTexture(id),
			buttonHoverTexture(id),
			buttonDisabledTexture(id)
		);
		button.active = active;
		return button;
	}

	private static final class TexturedButton extends Button {
		private final ResourceLocation normalTexture;
		private final ResourceLocation hoverTexture;
		private final ResourceLocation disabledTexture;

		private TexturedButton(int x, int y, int width, int height, Component message, Button.OnPress onPress, ResourceLocation normalTexture, ResourceLocation hoverTexture, ResourceLocation disabledTexture) {
			super(x, y, width, height, message, onPress, DEFAULT_NARRATION);
			this.normalTexture = normalTexture;
			this.hoverTexture = hoverTexture;
			this.disabledTexture = disabledTexture;
		}

		@Override
		protected void renderWidget(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			ResourceLocation selected = this.active
				? (this.isHovered() && textureExists(this.hoverTexture) ? this.hoverTexture : this.normalTexture)
				: (textureExists(this.disabledTexture) ? this.disabledTexture : this.normalTexture);

			boolean drawn = drawButtonTexture(graphics, selected, this.getX(), this.getY(), this.width, this.height);

			if (!drawn) {
				ResourceLocation generic = this.active
					? (this.isHovered() && textureExists(GUI_BUTTON_HOVER) ? GUI_BUTTON_HOVER : GUI_BUTTON)
					: (textureExists(GUI_BUTTON_DISABLED) ? GUI_BUTTON_DISABLED : GUI_BUTTON);

				drawn = drawButtonTexture(graphics, generic, this.getX(), this.getY(), this.width, this.height);
			}

			if (!drawn) {
				super.renderWidget(graphics, mouseX, mouseY, partialTick);
				return;
			}

			Minecraft minecraft = Minecraft.getInstance();
			int color = this.active ? (this.isHovered() ? 0xFFFFFFA0 : 0xFFFFFFFF) : 0xFF888888;

			if (minecraft != null) {
				graphics.drawCenteredString(
					minecraft.font,
					this.getMessage(),
					this.getX() + this.width / 2,
					this.getY() + (this.height - 8) / 2,
					color
				);
			}
		}
	}

	private static abstract class PartyBaseScreen extends Screen {
		protected PartyBaseScreen(String title) {
			super(Component.literal(title));
		}

		@Override
		public boolean isPauseScreen() {
			return false;
		}

		@Override
		public void renderBackground(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			// Intentionally empty: every party screen draws its own texture-aware background
			// before widgets, so row textures stay behind buttons.
		}

		protected void renderRenderables(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			for (Renderable renderable : this.renderables) {
				renderable.render(graphics, mouseX, mouseY, partialTick);
			}
		}

		protected void drawTopButtons() {
			addRenderableWidget(apiButton("tab_main", "Main", 8, 8, 54, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("open_main", "", "")));
			addRenderableWidget(apiButton("tab_invite", "Invite", 66, 8, 58, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("open_invite", "", "")));
			addRenderableWidget(apiButton("tab_settings", "Settings", 128, 8, 72, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("open_settings", "", "")));

			if (isAdmin) {
				addRenderableWidget(apiButton("tab_admin", "Admin", 204, 8, 58, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("open_admin", "", "")));
			}
		}
	}

	private static final class PartyMainScreen extends PartyBaseScreen {
		private int scroll = 0;

		private PartyMainScreen() {
			super("Party");
		}

		@Override
		protected void init() {
			drawTopButtons();
			int startY = 50;
			int rowHeight = 38;
			int x = this.width / 2 - 150;
			int rowWidth = 300;

			for (int i = 0; i < MEMBERS.size(); i++) {
				int visibleIndex = i - scroll;
				int y = startY + visibleIndex * rowHeight;

				if (y < 36 || y > this.height - 30) {
					continue;
				}

				var member = MEMBERS.get(i);
				int pinX = x + rowWidth - 104;
				int kickX = x + rowWidth - 52;

				addRenderableWidget(apiButton(member.pinned() ? "unpin" : "pin", member.pinned() ? "Unpin" : "Pin", pinX, y + 8, 48, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction(member.pinned() ? "unpin" : "pin", member.uuid(), "")));
				addRenderableWidget(apiButton("kick", "Kick", kickX, y + 8, 48, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("kick", member.uuid(), "")));
			}
		}

		@Override
		public boolean mouseScrolled(double mouseX, double mouseY, double deltaX, double deltaY) {
			scroll = Math.max(0, scroll - (int) Math.signum(deltaY));
			rebuildPartyWidgets();
			return true;
		}

		private void rebuildPartyWidgets() {
			clearWidgets();
			init();
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			drawScreenBackground(graphics, GUI_MAIN_BACKGROUND, this.width, this.height);
			graphics.drawCenteredString(this.font, "Party", (this.width / 2) + 50, 20, 0xFFFFFFFF);
			graphics.drawCenteredString(this.font, "PvP: " + (pvpEnabled ? "ON" : "OFF"), (this.width / 2) + 50, 34, pvpEnabled ? 0xFFFF7777 : 0xFF77FF77);

			if (MEMBERS.isEmpty()) {
				graphics.drawCenteredString(this.font, "No online party members", this.width / 2, 58, 0xFFFFFFFF);
				renderRenderables(graphics, mouseX, mouseY, partialTick);
				return;
			}

			int startY = 50;
			int rowHeight = 38;
			int x = this.width / 2 - 150;
			int rowWidth = 300;

			for (int i = scroll; i < MEMBERS.size(); i++) {
				int visibleIndex = i - scroll;
				int y = startY + visibleIndex * rowHeight;

				if (y > this.height - 30) {
					break;
				}

				var member = MEMBERS.get(i);
				boolean customMemberFrame = drawTexture(graphics, GUI_MEMBER_FRAME, x, y, rowWidth, 34, 300, 34);

				if (!customMemberFrame) {
					graphics.fill(x, y, x + rowWidth, y + 34, 0x99000000);
					graphics.fill(x, y, x + rowWidth, y + 1, member.leader() ? 0xFFE6C75A : 0xFF555555);
					graphics.fill(x, y + 33, x + rowWidth, y + 34, member.leader() ? 0xFFE6C75A : 0xFF555555);
				}

				String extra = member.leader() ? " ★" : "";
				String lvl = member.stats().getOrDefault("LVL", member.stats().getOrDefault("lvl", ""));

				if (!lvl.isBlank()) {
					extra += "   LVL " + lvl;
				}

				graphics.drawString(this.font, member.name() + extra, x + 8, y + 4, 0xFFFFFFFF, false);

				int barX = x + 8;
				int barW = 160;
				float hpRatio = member.maxHealth() <= 0.0F ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.health() / member.maxHealth()));
				float absorptionRatio = member.maxHealth() <= 0.0F ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.absorption() / member.maxHealth()));
				float foodRatio = Math.max(0.0F, Math.min(1.0F, member.food() / 20.0F));

				renderSmallBar(graphics, barX, y + 16, barW, 5, hpRatio, 0xFF321010, 0xFFB93A3A);

				if (absorptionRatio > 0.0F) {
					renderSmallBar(graphics, barX, y + 16, barW, 5, absorptionRatio, 0x00000000, 0x88FFD966);
				}

				renderSmallBar(graphics, barX, y + 24, barW, 4, foodRatio, 0xFF2B1B0B, 0xFFC9823A);

				graphics.drawString(this.font, Math.round(member.health()) + "/" + Math.round(member.maxHealth()), barX + barW + 6, y + 14, 0xFFCCCCCC, false);
				graphics.drawString(this.font, member.food() + "/20", barX + barW + 6, y + 23, 0xFFCCCCCC, false);
			}

			renderScrollBar(graphics, x + rowWidth + 6, startY, Math.max(24, this.height - startY - 30), MEMBERS.size(), Math.max(1, (this.height - startY - 30) / rowHeight), scroll);
			renderRenderables(graphics, mouseX, mouseY, partialTick);
		}
	}

	private static final class PartyInviteListScreen extends PartyBaseScreen {
		private EditBox search;
		private int scroll = 0;

		private PartyInviteListScreen() {
			super("Invite Players");
		}

		@Override
		protected void init() {
			drawTopButtons();
			search = new EditBox(this.font, 16, 38, 180, 20, Component.literal("Search"));
			search.setHint(Component.literal("Search nickname"));
			search.setResponder(value -> rebuild());
			addRenderableWidget(search);
			addPlayerButtons();
		}

		private void rebuild() {
			String oldFilter = search == null ? "" : search.getValue();
			clearWidgets();
			drawTopButtons();
			search = new EditBox(this.font, 16, 38, 180, 20, Component.literal("Search"));
			search.setValue(oldFilter);
			search.setHint(Component.literal("Search nickname"));
			search.setResponder(value -> rebuild());
			addRenderableWidget(search);
			addPlayerButtons();
		}

		private void addPlayerButtons() {
			String filter = search == null ? "" : search.getValue().toLowerCase(Locale.ROOT);
			int row = 0;

			for (var player : ONLINE_PLAYERS) {
				if (!player.name().toLowerCase(Locale.ROOT).contains(filter)) {
					continue;
				}

				int y = 70 + (row - scroll) * 24;
				if (y >= 64 && y < this.height - 24) {
					String label = player.pendingInvite() ? "Revoke" : (player.inMyParty() ? "In party" : "Invite");
					String action = player.pendingInvite() ? "revoke_invite" : "invite";
					String buttonId = player.pendingInvite() ? "revoke" : (player.inMyParty() ? "in_party" : "invite");

					addRenderableWidget(apiButton(buttonId, label, this.width - 96, y - 4, 78, 20, b -> {
						if (!player.inMyParty()) {
							${package}.network.PartyApiNetwork.sendClientAction(action, player.uuid(), "");
						}
					}, !player.inMyParty()));
				}
				row++;
			}
		}

		@Override
		public boolean mouseScrolled(double mouseX, double mouseY, double deltaX, double deltaY) {
			scroll = Math.max(0, scroll - (int) Math.signum(deltaY));
			rebuild();
			return true;
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			drawScreenBackground(graphics, GUI_INVITE_BACKGROUND, this.width, this.height);
			drawTexture(graphics, GUI_SEARCH, 16, 38, 180, 20, 180, 20);
			graphics.drawCenteredString(this.font, "Invite Players", this.width / 2, 20, 0xFFFFFFFF);

			String filter = search == null ? "" : search.getValue().toLowerCase(Locale.ROOT);
			int row = 0;

			for (var player : ONLINE_PLAYERS) {
				if (!player.name().toLowerCase(Locale.ROOT).contains(filter)) {
					continue;
				}

				int y = 70 + (row - scroll) * 24;

				if (y >= 64 && y < this.height - 24) {
					if (!drawTexture(graphics, GUI_ONLINE_PLAYER_ROW, 14, y - 5, this.width - 28, 22, 300, 22)) {
						graphics.fill(14, y - 5, this.width - 14, y + 17, player.inMyParty() ? 0x55222222 : 0x77000000);
					}

					String status = player.inMyParty() ? "already in your party" : (player.inAnyParty() ? "in another party" : "online");
					graphics.drawString(this.font, player.name(), 20, y, player.inMyParty() ? 0xFFAAAAAA : 0xFFFFFFFF, false);
					graphics.drawString(this.font, status, 150, y, 0xFF999999, false);
				}

				row++;
			}

			renderScrollBar(graphics, this.width - 10, 70, Math.max(24, this.height - 94), row, Math.max(1, (this.height - 94) / 24), scroll);
			renderRenderables(graphics, mouseX, mouseY, partialTick);
		}
	}

	private static final class PartySettingsScreen extends PartyBaseScreen {
		private PartySettingsScreen() {
			super("Party Settings");
		}

		@Override
		protected void init() {
			drawTopButtons();
			addRenderableWidget(apiButton("show_self_on", "Show self: ON", 20, 52, 120, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("show_self_on", "", "")));
			addRenderableWidget(apiButton("show_self_off", "Show self: OFF", 145, 52, 120, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("show_self_off", "", "")));
			addRenderableWidget(apiButton("pvp_on", "PvP: ON", 20, 78, 120, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("pvp_on", "", "")));
			addRenderableWidget(apiButton("pvp_off", "PvP: OFF", 145, 78, 120, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("pvp_off", "", "")));
			addRenderableWidget(apiButton("reset_position", "Reset overlay position", 20, 104, 180, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("position_xy", "", "8,58")));
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			drawScreenBackground(graphics, GUI_SETTINGS_BACKGROUND, this.width, this.height);
			graphics.drawCenteredString(this.font, "Party Settings", this.width / 2, 20, 0xFFFFFFFF);
			graphics.drawString(this.font, "Show self: " + showSelf, 20, 136, 0xFFFFFFFF, false);
			graphics.drawString(this.font, "Overlay: x=" + overlayX + " y=" + overlayY, 20, 150, 0xFFFFFFFF, false);
			renderRenderables(graphics, mouseX, mouseY, partialTick);
		}
	}

	private static final class PartyAdminScreen extends PartyBaseScreen {
		private EditBox search;
		private int scroll = 0;

		private PartyAdminScreen() {
			super("Party Admin");
		}

		@Override
		protected void init() {
			drawTopButtons();

			addRenderableWidget(apiButton("admin_system_on", "System ON", 16, 36, 80, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_enable", "", "")));
			addRenderableWidget(apiButton("admin_system_off", "System OFF", 100, 36, 86, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_disable", "", "")));
			addRenderableWidget(apiButton("admin_refresh", "Refresh", 190, 36, 70, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_refresh", "", "")));

			search = new EditBox(this.font, 16, 62, 200, 20, Component.literal("Search"));
			search.setHint(Component.literal("Search player / party leader"));
			search.setResponder(value -> rebuildAdminWidgets());
			addRenderableWidget(search);

			addAdminButtons();
		}

		private void rebuildAdminWidgets() {
			String oldFilter = search == null ? "" : search.getValue();
			clearWidgets();
			drawTopButtons();

			addRenderableWidget(apiButton("admin_system_on", "System ON", 16, 36, 80, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_enable", "", "")));
			addRenderableWidget(apiButton("admin_system_off", "System OFF", 100, 36, 86, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_disable", "", "")));
			addRenderableWidget(apiButton("admin_refresh", "Refresh", 190, 36, 70, 20, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_refresh", "", "")));

			search = new EditBox(this.font, 16, 62, 200, 20, Component.literal("Search"));
			search.setValue(oldFilter);
			search.setHint(Component.literal("Search player / party leader"));
			search.setResponder(value -> rebuildAdminWidgets());
			addRenderableWidget(search);

			addAdminButtons();
		}

		private List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> filteredAdminPlayers() {
			String filter = search == null ? "" : search.getValue().toLowerCase(Locale.ROOT);
			List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> result = new ArrayList<>();

			for (var player : ONLINE_PLAYERS) {
				if (filter.isBlank() || player.name().toLowerCase(Locale.ROOT).contains(filter) || player.leaderName().toLowerCase(Locale.ROOT).contains(filter)) {
					result.add(player);
				}
			}

			result.sort((a, b) -> {
				if (a.inAnyParty() != b.inAnyParty()) {
					return a.inAnyParty() ? -1 : 1;
				}

				int leaderCompare = a.leaderName().compareToIgnoreCase(b.leaderName());
				if (leaderCompare != 0) {
					return leaderCompare;
				}

				if (a.partyLeader() != b.partyLeader()) {
					return a.partyLeader() ? -1 : 1;
				}

				return a.name().compareToIgnoreCase(b.name());
			});

			return result;
		}

		private void addAdminButtons() {
			List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> rows = filteredAdminPlayers();

			for (int i = 0; i < rows.size(); i++) {
				int y = 94 + (i - scroll) * 54;

				if (y < 88 || y >= this.height - 48) {
					continue;
				}

				var player = rows.get(i);
				int right = this.width - 16;

				addRenderableWidget(apiButton("admin_view", "View", right - 314, y + 14, 46, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_view", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_remove", "Remove", right - 264, y + 14, 60, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_remove", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_disband", "Disband", right - 200, y + 14, 64, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_disband", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_pvp_on", "PvP ON", right - 132, y + 4, 62, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_pvp_on", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_pvp_off", "PvP OFF", right - 66, y + 4, 62, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_pvp_off", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_limit_4", "L4", right - 132, y + 26, 30, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_limit_4", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_limit_8", "L8", right - 98, y + 26, 30, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_limit_8", player.uuid(), "")));
				addRenderableWidget(apiButton("admin_limit_16", "L16", right - 64, y + 26, 38, 18, b -> ${package}.network.PartyApiNetwork.sendClientAction("admin_limit_16", player.uuid(), "")));
			}
		}

		@Override
		public boolean mouseScrolled(double mouseX, double mouseY, double deltaX, double deltaY) {
			scroll = Math.max(0, scroll - (int) Math.signum(deltaY));
			rebuildAdminWidgets();
			return true;
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			drawScreenBackground(graphics, GUI_ADMIN_BACKGROUND, this.width, this.height);
			drawTexture(graphics, GUI_SEARCH, 16, 62, 200, 20, 200, 20);
			graphics.drawCenteredString(this.font, "Party Admin", this.width / 2, 20, 0xFFFFFFFF);

			List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> rows = filteredAdminPlayers();
			String lastPartyId = null;

			for (int i = scroll; i < rows.size(); i++) {
				int y = 94 + (i - scroll) * 54;

				if (y >= this.height - 48) {
					break;
				}

				var player = rows.get(i);

				if (player.inAnyParty() && !player.partyId().equals(lastPartyId)) {
					lastPartyId = player.partyId();
					graphics.drawString(this.font, "Party leader: " + player.leaderName() + "  (" + player.partySize() + "/" + player.partyMaxMembers() + ")", 18, y - 10, 0xFFE6C75A, false);
				} else if (!player.inAnyParty() && lastPartyId != null) {
					lastPartyId = null;
				}

				if (!drawTexture(graphics, GUI_ADMIN_PLAYER_ROW, 14, y - 2, this.width - 28, 48, 420, 48)) {
					graphics.fill(14, y - 2, this.width - 14, y + 46, player.inAnyParty() ? 0x88000000 : 0x66222222);
				}

				String marker = player.partyLeader() ? " ★ leader" : "";
				String partyLine = player.inAnyParty()
					? "Party: " + player.leaderName() + " | Size: " + player.partySize() + "/" + player.partyMaxMembers()
					: "No party";

				graphics.drawString(this.font, player.name() + marker, 20, y + 4, player.partyLeader() ? 0xFFE6C75A : 0xFFFFFFFF, false);
				graphics.drawString(this.font, partyLine, 20, y + 16, 0xFFCCCCCC, false);
				graphics.drawString(this.font, "UUID: " + player.uuid(), 20, y + 28, 0xFF999999, false);
			}

			if (rows.isEmpty()) {
				graphics.drawString(this.font, "No online players received. Press Refresh or reopen Admin GUI.", 20, 94, 0xFFFFFFFF, false);
			}

			renderScrollBar(graphics, this.width - 10, 94, Math.max(24, this.height - 142), rows.size(), Math.max(1, (this.height - 142) / 54), scroll);
			renderRenderables(graphics, mouseX, mouseY, partialTick);
		}
	}

	private static final class PartyInvitePopupScreen extends Screen {
		private final String inviterName;

		private PartyInvitePopupScreen(String inviterName) {
			super(Component.literal("Party Invite"));
			this.inviterName = inviterName == null ? "Unknown" : inviterName;
		}

		@Override
		public boolean isPauseScreen() {
			return false;
		}

		@Override
		public void renderBackground(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			// Custom render below.
		}

		@Override
		protected void init() {
			int boxWidth = 220;
			int boxHeight = 88;
			int boxX = (this.width - boxWidth) / 2;
			int boxY = (this.height - boxHeight) / 2;
			int buttonY = boxY + 58;

			addRenderableWidget(apiButton("accept", "Accept", boxX + 22, buttonY, 70, 20, b -> {
				${package}.network.PartyApiNetwork.sendClientAction("accept_invite", "", "");
				this.minecraft.setScreen(null);
			}));

			addRenderableWidget(apiButton("decline", "Decline", boxX + boxWidth - 92, buttonY, 70, 20, b -> {
				${package}.network.PartyApiNetwork.sendClientAction("decline_invite", "", "");
				this.minecraft.setScreen(null);
			}));
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			graphics.fill(0, 0, this.width, this.height, 0x55000000);

			int boxWidth = 220;
			int boxHeight = 88;
			int boxX = (this.width - boxWidth) / 2;
			int boxY = (this.height - boxHeight) / 2;

			if (!drawTexture(graphics, GUI_INVITE_POPUP_BACKGROUND, boxX, boxY, boxWidth, boxHeight, 220, 88)) {
				graphics.fill(boxX, boxY, boxX + boxWidth, boxY + boxHeight, 0xCC000000);
			}

			graphics.drawCenteredString(this.font, "Party Invite", this.width / 2, boxY + 10, 0xFFFFFFFF);
			graphics.drawCenteredString(this.font, inviterName + " invited you to a party", this.width / 2, boxY + 30, 0xFFDCDCDC);

			for (Renderable renderable : this.renderables) {
				renderable.render(graphics, mouseX, mouseY, partialTick);
			}
		}
	}
}
