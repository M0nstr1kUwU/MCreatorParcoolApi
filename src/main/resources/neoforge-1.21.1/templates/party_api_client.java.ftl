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
	private static int overlayY = 74;
	private static int nicknameScalePercent = 80;
	private static boolean showSelf = false;
	private static boolean isAdmin = false;

	private static final List<${package}.network.PartyApiNetwork.MemberSyncData> MEMBERS = new ArrayList<>();
	private static final List<${package}.network.PartyApiNetwork.OverlayElementPositionSyncData> ELEMENT_POSITIONS = new ArrayList<>();
	private static final List<${package}.network.PartyApiNetwork.CustomOverlayEntrySyncData> CUSTOM_ENTRIES = new ArrayList<>();
	private static final List<${package}.network.PartyApiNetwork.OnlinePlayerSyncData> ONLINE_PLAYERS = new ArrayList<>();

	private static final Map<ResourceLocation, Boolean> TEXTURE_EXISTS_CACHE = new HashMap<>();

	private static final ResourceLocation OVERLAY_MEMBER_FRAME = partyTexture("overlay_member_frame.png");
	private static final ResourceLocation OVERLAY_HP_EMPTY = partyTexture("overlay_hp_empty.png");
	private static final ResourceLocation OVERLAY_HP_FULL = partyTexture("overlay_hp_full.png");
	private static final ResourceLocation OVERLAY_ABSORPTION = partyTexture("overlay_absorption.png");
	private static final ResourceLocation OVERLAY_FOOD_EMPTY = partyTexture("overlay_food_empty.png");
	private static final ResourceLocation OVERLAY_FOOD_FULL = partyTexture("overlay_food_full.png");

	private static final ResourceLocation GUI_BACKGROUND = partyTexture("gui_background.png");
	private static final ResourceLocation GUI_MEMBER_FRAME = partyTexture("gui_member_frame.png");
	private static final ResourceLocation GUI_BUTTON = partyTexture("gui_button.png");
	private static final ResourceLocation GUI_BUTTON_HOVER = partyTexture("gui_button_hover.png");

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
		if (!textureExists(texture)) {
			return false;
		}

		try {
			graphics.blit(texture, x, y, 0, 0, width, height, textureWidth, textureHeight);
			return true;
		} catch (Throwable ignored) {
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
		boolean customFrame = drawTexture(graphics, OVERLAY_MEMBER_FRAME, x, y, width, 19, 96, 19);

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

		int barX = x + 4;
		int hpY = y + 11;
		int foodY = y + 14; // 1px higher than previous 15
		int barWidth = width - 8;

		float hpRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.health() / member.maxHealth()));
		float absorptionRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.absorption() / member.maxHealth()));
		float foodRatio = Math.max(0.0F, Math.min(1.0F, member.food() / 20.0F));

		int hpWidth = (int) (barWidth * hpRatio);
		int absorptionWidth = (int) (barWidth * absorptionRatio);
		int foodWidth = (int) (barWidth * foodRatio);

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

			graphics.fill(x, y, x + w, y + h, 0xAA222222);
			graphics.fill(x, y, x + Math.max(0, Math.min(w, Math.round(w * (current / max)))), y + h, 0xFF55AAFF);
			graphics.drawString(minecraft.font, entry.label(), x, y - 9, 0xFFFFFFFF, false);
		} else {
			graphics.drawString(minecraft.font, entry.label() + ": " + entry.value(), x, y, 0xFFFFFFFF, false);
		}
	}

	private static float parseFloat(String value, float fallback) {
		try {
			return Float.parseFloat(value);
		} catch (Throwable ignored) {
			return fallback;
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
			graphics.fill(0, 0, this.width, this.height, 0x22000000);
		}

		protected void drawTopButtons() {
			addRenderableWidget(Button.builder(Component.literal("Main"), b -> ${package}.network.PartyApiNetwork.sendClientAction("open_main", "", "")).bounds(8, 8, 54, 20).build());
			addRenderableWidget(Button.builder(Component.literal("Invite"), b -> ${package}.network.PartyApiNetwork.sendClientAction("open_invite", "", "")).bounds(66, 8, 58, 20).build());
			addRenderableWidget(Button.builder(Component.literal("Settings"), b -> ${package}.network.PartyApiNetwork.sendClientAction("open_settings", "", "")).bounds(128, 8, 72, 20).build());

			if (isAdmin) {
				addRenderableWidget(Button.builder(Component.literal("Admin"), b -> ${package}.network.PartyApiNetwork.sendClientAction("open_admin", "", "")).bounds(204, 8, 58, 20).build());
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
			int rowHeight = 32;
			int x = this.width / 2 - 140;
			int rowWidth = 280;

			for (int i = 0; i < MEMBERS.size(); i++) {
				int visibleIndex = i - scroll;
				int y = startY + visibleIndex * rowHeight;

				if (y < 36 || y > this.height - 30) {
					continue;
				}

				var member = MEMBERS.get(i);
				int pinX = x + rowWidth - 104;
				int kickX = x + rowWidth - 52;

				addRenderableWidget(Button.builder(Component.literal(member.pinned() ? "Unpin" : "Pin"), b -> ${package}.network.PartyApiNetwork.sendClientAction(member.pinned() ? "unpin" : "pin", member.uuid(), "")).bounds(pinX, y + 5, 48, 18).build());
				addRenderableWidget(Button.builder(Component.literal("Kick"), b -> ${package}.network.PartyApiNetwork.sendClientAction("kick", member.uuid(), "")).bounds(kickX, y + 5, 48, 18).build());
			}
		}

		@Override
		public boolean mouseScrolled(double mouseX, double mouseY, double deltaX, double deltaY) {
			scroll = Math.max(0, scroll - (int) Math.signum(deltaY));
			rebuildWidgets();
			return true;
		}

		private void rebuildWidgets() {
			clearWidgets();
			init();
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			super.render(graphics, mouseX, mouseY, partialTick);
			graphics.drawCenteredString(this.font, "Party", this.width / 2, 20, 0xFFFFFFFF);
			graphics.drawCenteredString(this.font, "PvP: " + (pvpEnabled ? "ON" : "OFF"), this.width / 2, 34, pvpEnabled ? 0xFFFF7777 : 0xFF77FF77);

			if (MEMBERS.isEmpty()) {
				graphics.drawCenteredString(this.font, "No online party members", this.width / 2, 58, 0xFFFFFFFF);
				return;
			}

			int startY = 50;
			int rowHeight = 32;
			int x = this.width / 2 - 140;
			int rowWidth = 280;

			for (int i = scroll; i < MEMBERS.size(); i++) {
				int visibleIndex = i - scroll;
				int y = startY + visibleIndex * rowHeight;

				if (y > this.height - 30) {
					break;
				}

				var member = MEMBERS.get(i);
				boolean customMemberFrame = drawTexture(graphics, GUI_MEMBER_FRAME, x, y, rowWidth, 28, 280, 28);

				if (!customMemberFrame) {
					graphics.fill(x, y, x + rowWidth, y + 28, 0x99000000);
				}

				graphics.drawString(this.font, member.name() + (member.leader() ? " ★" : ""), x + 8, y + 5, 0xFFFFFFFF, false);
				graphics.drawString(this.font, "HP " + Math.round(member.health()) + "/" + Math.round(member.maxHealth()) + " Food " + member.food(), x + 8, y + 17, 0xFFCCCCCC, false);
			}
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
					addRenderableWidget(Button.builder(Component.literal(label), b -> {
						if (!player.inMyParty()) {
							${package}.network.PartyApiNetwork.sendClientAction(action, player.uuid(), "");
						}
					}).bounds(this.width - 96, y - 4, 78, 20).build());
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
			super.render(graphics, mouseX, mouseY, partialTick);
			graphics.drawCenteredString(this.font, "Invite Players", this.width / 2, 20, 0xFFFFFFFF);

			String filter = search == null ? "" : search.getValue().toLowerCase(Locale.ROOT);
			int row = 0;

			for (var player : ONLINE_PLAYERS) {
				if (!player.name().toLowerCase(Locale.ROOT).contains(filter)) {
					continue;
				}

				int y = 70 + (row - scroll) * 24;

				if (y >= 64 && y < this.height - 24) {
					graphics.drawString(this.font, player.name(), 20, y, player.inMyParty() ? 0xFFAAAAAA : 0xFFFFFFFF, false);
				}

				row++;
			}
		}
	}

	private static final class PartySettingsScreen extends PartyBaseScreen {
		private PartySettingsScreen() {
			super("Party Settings");
		}

		@Override
		protected void init() {
			drawTopButtons();
			addRenderableWidget(Button.builder(Component.literal("Show self: ON"), b -> ${package}.network.PartyApiNetwork.sendClientAction("show_self_on", "", "")).bounds(20, 52, 120, 20).build());
			addRenderableWidget(Button.builder(Component.literal("Show self: OFF"), b -> ${package}.network.PartyApiNetwork.sendClientAction("show_self_off", "", "")).bounds(145, 52, 120, 20).build());
			addRenderableWidget(Button.builder(Component.literal("PvP: ON"), b -> ${package}.network.PartyApiNetwork.sendClientAction("pvp_on", "", "")).bounds(20, 78, 120, 20).build());
			addRenderableWidget(Button.builder(Component.literal("PvP: OFF"), b -> ${package}.network.PartyApiNetwork.sendClientAction("pvp_off", "", "")).bounds(145, 78, 120, 20).build());
			addRenderableWidget(Button.builder(Component.literal("Reset overlay position"), b -> ${package}.network.PartyApiNetwork.sendClientAction("position_xy", "", "8,74")).bounds(20, 104, 180, 20).build());
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			super.render(graphics, mouseX, mouseY, partialTick);
			graphics.drawCenteredString(this.font, "Party Settings", this.width / 2, 20, 0xFFFFFFFF);
			graphics.drawString(this.font, "Show self: " + showSelf, 20, 136, 0xFFFFFFFF, false);
			graphics.drawString(this.font, "Overlay: x=" + overlayX + " y=" + overlayY, 20, 150, 0xFFFFFFFF, false);
		}
	}

	private static final class PartyAdminScreen extends PartyBaseScreen {
		private PartyAdminScreen() {
			super("Party Admin");
		}

		@Override
		protected void init() {
			drawTopButtons();
			addRenderableWidget(Button.builder(Component.literal("Admin tools are command-backed"), b -> {}).bounds(20, 52, 180, 20).build());
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			super.render(graphics, mouseX, mouseY, partialTick);
			graphics.drawCenteredString(this.font, "Party Admin", this.width / 2, 20, 0xFFFFFFFF);
			graphics.drawString(this.font, "Use /party admin ... for target-specific actions.", 20, 84, 0xFFFFFFFF, false);
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
			graphics.fill(0, 0, this.width, this.height, 0x22000000);
		}

		@Override
		protected void init() {
			int boxWidth = 220;
			int boxHeight = 88;
			int boxX = (this.width - boxWidth) / 2;
			int boxY = (this.height - boxHeight) / 2;
			int buttonY = boxY + 58;

			addRenderableWidget(Button.builder(Component.literal("Accept"), b -> {
				${package}.network.PartyApiNetwork.sendClientAction("accept_invite", "", "");
				this.minecraft.setScreen(null);
			}).bounds(boxX + 22, buttonY, 70, 20).build());

			addRenderableWidget(Button.builder(Component.literal("Decline"), b -> {
				${package}.network.PartyApiNetwork.sendClientAction("decline_invite", "", "");
				this.minecraft.setScreen(null);
			}).bounds(boxX + boxWidth - 92, buttonY, 70, 20).build());
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			super.render(graphics, mouseX, mouseY, partialTick);
			int boxWidth = 220;
			int boxHeight = 88;
			int boxX = (this.width - boxWidth) / 2;
			int boxY = (this.height - boxHeight) / 2;

			graphics.fill(boxX, boxY, boxX + boxWidth, boxY + boxHeight, 0xCC000000);
			graphics.drawCenteredString(this.font, "Party Invite", this.width / 2, boxY + 10, 0xFFFFFFFF);
			graphics.drawCenteredString(this.font, inviterName + " invited you to a party", this.width / 2, boxY + 30, 0xFFDCDCDC);
		}
	}
}
