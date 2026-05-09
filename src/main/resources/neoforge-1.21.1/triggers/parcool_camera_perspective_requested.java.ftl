@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolCameraPerspectiveRequested(${package}.events.ParCoolApiBridgeEvents.CameraPerspectiveRequestedEvent event) {
		execute(
			event,
			event.getPlayer(),
			event.getWorld(),
			event.getPerspectiveId()
		);
	}