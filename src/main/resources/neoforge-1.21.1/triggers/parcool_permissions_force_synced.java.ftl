@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolPermissionsForceSynced(${package}.events.ParCoolApiBridgeEvents.PermissionsForceSyncedEvent event) {
		execute(
			event,
			event.getPlayer(),
			event.getWorld()
		);
	}