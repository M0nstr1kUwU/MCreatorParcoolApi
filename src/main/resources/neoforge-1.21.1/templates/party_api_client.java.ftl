package ${package}.client;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
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
	private static String overlayPosition = "LEFT_CENTER";
	private static final List<${package}.network.PartyApiNetwork.MemberSyncData> MEMBERS = new ArrayList<>();

	private static final Map<ResourceLocation, Boolean> TEXTURE_EXISTS_CACHE = new HashMap<>();

	private static final ResourceLocation OVERLAY_MEMBER_FRAME = partyTexture("overlay_member_frame.png");
	private static final ResourceLocation OVERLAY_HP_EMPTY = partyTexture("overlay_hp_empty.png");
	private static final ResourceLocation OVERLAY_HP_FULL = partyTexture("overlay_hp_full.png");
	private static final ResourceLocation OVERLAY_ABSORPTION = partyTexture("overlay_absorption.png");
	private static final ResourceLocation OVERLAY_FOOD_EMPTY = partyTexture("overlay_food_empty.png");
	private static final ResourceLocation OVERLAY_FOOD_FULL = partyTexture("overlay_food_full.png");
	private static final ResourceLocation OVERLAY_SATURATION = partyTexture("overlay_saturation.png");

	private static final ResourceLocation GUI_BACKGROUND = partyTexture("gui_background.png");
	private static final ResourceLocation GUI_MEMBER_FRAME = partyTexture("gui_member_frame.png");
	private static final ResourceLocation GUI_HP_EMPTY = partyTexture("gui_hp_empty.png");
	private static final ResourceLocation GUI_HP_FULL = partyTexture("gui_hp_full.png");
	private static final ResourceLocation GUI_ABSORPTION = partyTexture("gui_absorption.png");
	private static final ResourceLocation GUI_FOOD_EMPTY = partyTexture("gui_food_empty.png");
	private static final ResourceLocation GUI_FOOD_FULL = partyTexture("gui_food_full.png");
	private static final ResourceLocation GUI_SATURATION = partyTexture("gui_saturation.png");
	private static final ResourceLocation GUI_BUTTON_PIN = partyTexture("button_pin.png");
	private static final ResourceLocation GUI_BUTTON_UNPIN = partyTexture("button_unpin.png");

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

		MEMBERS.clear();
		MEMBERS.addAll(payload.members());
	}

	public static void openPartyScreen() {
		Minecraft minecraft = Minecraft.getInstance();

		if (minecraft != null) {
			minecraft.setScreen(new PartyScreen());
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

		int screenWidth = minecraft.getWindow().getGuiScaledWidth();
		int screenHeight = minecraft.getWindow().getGuiScaledHeight();

		int panelWidth = 96;
		int rowHeight = 22;
		int totalHeight = pinned.size() * rowHeight;

		int x = switch (overlayPosition) {
			case "RIGHT_CENTER", "RIGHT_TOP", "RIGHT_BOTTOM" -> screenWidth - panelWidth - 6;
			default -> 6;
		};

		int y = switch (overlayPosition) {
			case "LEFT_TOP", "RIGHT_TOP" -> 22;
			case "LEFT_BOTTOM", "RIGHT_BOTTOM" -> screenHeight - totalHeight - 22;
			default -> (screenHeight / 2) - (totalHeight / 2);
		};

		for (int i = 0; i < pinned.size(); i++) {
			renderOverlayMember(graphics, minecraft, pinned.get(i), x, y + i * rowHeight, panelWidth);
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

		graphics.drawString(minecraft.font, name, x + 4, y + 2, 0xFFFFFFFF, false);

		int barX = x + 4;
		int hpY = y + 11;
		int foodY = y + 16;
		int barWidth = width - 8;

		float hpRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.health() / member.maxHealth()));
		float absorptionRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.absorption() / member.maxHealth()));
		float foodRatio = Math.max(0.0F, Math.min(1.0F, member.food() / 20.0F));
		float saturationRatio = Math.max(0.0F, Math.min(1.0F, member.saturation() / 20.0F));

		int hpWidth = (int) (barWidth * hpRatio);
		int absorptionWidth = (int) (barWidth * absorptionRatio);
		int foodWidth = (int) (barWidth * foodRatio);
		int saturationWidth = (int) (barWidth * saturationRatio);

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

		if (saturationWidth > 0) {
			if (!drawTexturePart(graphics, OVERLAY_SATURATION, barX, foodY, Math.min(barWidth, saturationWidth), 2, 88, 2)) {
				graphics.fill(barX, foodY, barX + Math.min(barWidth, saturationWidth), foodY + 1, 0xAAE8D27A);
			}
		}
	}

	private static final class PartyScreen extends Screen {
		private int scroll = 0;

		private PartyScreen() {
			super(Component.literal("Party"));
		}

		@Override
		public boolean isPauseScreen() {
			return false;
		}

		@Override
		public void renderBackground(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			// Disabled intentionally: no vanilla blur, no dirt background, no menu background.
		}

		protected void renderBlurredBackground(float partialTick) {
			// Disabled intentionally.
		}

		@Override
		public boolean mouseScrolled(double mouseX, double mouseY, double deltaX, double deltaY) {
			scroll = Math.max(0, scroll - (int) Math.signum(deltaY));
			return true;
		}

		@Override
		public boolean mouseClicked(double mouseX, double mouseY, int button) {
			int startY = 40;
			int rowHeight = 32;

			for (int i = 0; i < MEMBERS.size(); i++) {
				int visibleIndex = i - scroll;
				int rowY = startY + visibleIndex * rowHeight;

				if (rowY < 36 || rowY > this.height - 30) {
					continue;
				}

				int pinX = this.width / 2 + 96;

				if (mouseX >= pinX && mouseX <= pinX + 44 && mouseY >= rowY + 6 && mouseY <= rowY + 22) {
					var member = MEMBERS.get(i);
					${package}.network.PartyApiNetwork.sendClientAction(member.pinned() ? "unpin" : "pin", member.uuid(), "");
					return true;
				}
			}

			return false;
		}

		@Override
		public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
			boolean customBackground = false;

			if (textureExists(GUI_BACKGROUND)) {
				int bgWidth = 320;
				int bgHeight = 220;
				int bgX = (this.width - bgWidth) / 2;
				int bgY = Math.max(8, (this.height - bgHeight) / 2);

				customBackground = drawTexture(graphics, GUI_BACKGROUND, bgX, bgY, bgWidth, bgHeight, 320, 220);
			}

			if (!customBackground) {
				graphics.fill(0, 0, this.width, this.height, 0x22000000);
			}

			graphics.drawCenteredString(this.font, "Party", this.width / 2, 10, 0xFFFFFFFF);
			graphics.drawCenteredString(this.font, "PvP: " + (pvpEnabled ? "ON" : "OFF"), this.width / 2, 22, pvpEnabled ? 0xFFFF7777 : 0xFF77FF77);

			int startY = 40;
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

				float hpRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.health() / member.maxHealth()));
				float absorptionRatio = member.maxHealth() <= 0 ? 0.0F : Math.max(0.0F, Math.min(1.0F, member.absorption() / member.maxHealth()));
				float foodRatio = Math.max(0.0F, Math.min(1.0F, member.food() / 20.0F));
				float saturationRatio = Math.max(0.0F, Math.min(1.0F, member.saturation() / 20.0F));

				int barX = x + 8;
				int hpY = y + 17;
				int foodY = y + 23;
				int barWidth = 90;

				int hpWidth = (int) (barWidth * hpRatio);
				int absorptionWidth = (int) (barWidth * absorptionRatio);
				int foodWidth = (int) (barWidth * foodRatio);
				int saturationWidth = (int) (barWidth * saturationRatio);

				if (!drawTexture(graphics, GUI_HP_EMPTY, barX, hpY, barWidth, 4, 90, 4)) {
					graphics.fill(barX, hpY, barX + barWidth, hpY + 4, 0xFF321010);
				}

				if (!drawTexturePart(graphics, GUI_HP_FULL, barX, hpY, hpWidth, 4, 90, 4)) {
					graphics.fill(barX, hpY, barX + hpWidth, hpY + 4, 0xFFB93A3A);
				}

				if (absorptionWidth > 0) {
					if (!drawTexturePart(graphics, GUI_ABSORPTION, barX, hpY, Math.min(barWidth, absorptionWidth), 4, 90, 4)) {
						graphics.fill(barX, hpY, barX + Math.min(barWidth, absorptionWidth), hpY + 4, 0x55FFD966);
						graphics.fill(barX, hpY, barX + Math.min(barWidth, absorptionWidth), hpY + 1, 0xAAFFD966);
					}
				}

				if (!drawTexture(graphics, GUI_FOOD_EMPTY, barX, foodY, barWidth, 3, 90, 3)) {
					graphics.fill(barX, foodY, barX + barWidth, foodY + 3, 0xFF2B1B0B);
				}

				if (!drawTexturePart(graphics, GUI_FOOD_FULL, barX, foodY, foodWidth, 3, 90, 3)) {
					graphics.fill(barX, foodY, barX + foodWidth, foodY + 3, 0xFFC9823A);
				}

				if (saturationWidth > 0) {
					if (!drawTexturePart(graphics, GUI_SATURATION, barX, foodY, Math.min(barWidth, saturationWidth), 3, 90, 3)) {
						graphics.fill(barX, foodY, barX + Math.min(barWidth, saturationWidth), foodY + 1, 0xAAE8D27A);
					}
				}

				int pinX = x + rowWidth - 52;
				String buttonText = member.pinned() ? "Unpin" : "Pin";
				ResourceLocation buttonTexture = member.pinned() ? GUI_BUTTON_UNPIN : GUI_BUTTON_PIN;
				boolean customButton = drawTexture(graphics, buttonTexture, pinX, y + 6, 44, 16, 44, 16);

				if (!customButton) {
					graphics.fill(pinX, y + 6, pinX + 44, y + 22, 0xFF333333);
				}

				graphics.drawCenteredString(this.font, buttonText, pinX + 22, y + 10, 0xFFFFFFFF);
			}
		}
	}
}
