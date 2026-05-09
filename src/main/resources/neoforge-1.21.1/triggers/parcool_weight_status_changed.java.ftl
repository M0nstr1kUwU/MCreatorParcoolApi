@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolWeightStatusChanged(${package}.events.ParCoolApiBridgeEvents.WeightStatusChangedEvent event) {
		execute(
			event,
			event.getPlayer(),
			event.getWorld(),
			event.getOldStatus(),
			event.getNewStatus(),
			event.getCurrentWeight(),
			event.getMaxWeight(),
			event.getLoadPercent()
		);
	}