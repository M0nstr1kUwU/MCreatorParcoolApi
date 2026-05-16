package ${package}.party;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.ServerChatEvent;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiChatGuard {
	private PartyApiChatGuard() {
	}

	@SubscribeEvent
	public static void onServerChat(ServerChatEvent event) {
		if (!PartyApiServerConfig.partyChatEnabled()) {
			return;
		}

		String prefix = PartyApiServerConfig.partyChatPrefix();

		if (prefix == null || prefix.isEmpty()) {
			return;
		}

		String raw = event.getRawText();

		if (raw == null || !raw.startsWith(prefix)) {
			return;
		}

		event.setCanceled(true);

		String message = raw.substring(prefix.length()).trim();

		if (message.isEmpty()) {
			event.getPlayer().displayClientMessage(net.minecraft.network.chat.Component.literal("Party chat message is empty"), false);
			return;
		}

		boolean sent = PartyApiSystem.sendPartyChat(event.getPlayer(), message);

		if (!sent) {
			event.getPlayer().displayClientMessage(net.minecraft.network.chat.Component.literal("You are not in a party"), false);
		}
	}
}
