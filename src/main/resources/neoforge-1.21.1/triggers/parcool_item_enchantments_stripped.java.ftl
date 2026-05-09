@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolItemEnchantmentsStripped(${package}.events.ParCoolApiBridgeEvents.ItemEnchantmentsStrippedEvent event) {
		execute(
			event,
			event.getItemStack()
		);
	}