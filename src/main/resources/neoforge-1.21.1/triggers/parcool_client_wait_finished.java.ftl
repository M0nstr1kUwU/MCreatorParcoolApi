@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolClientWaitFinished(${package}.events.ParCoolApiBridgeEvents.ClientWaitFinishedEvent event) {
		execute(
			event,
			event.getPlayer(),
			event.getWorld()
		);
	}