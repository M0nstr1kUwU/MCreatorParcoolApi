@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolWeightOverloadEnded(${package}.events.ParCoolApiBridgeEvents.WeightOverloadEndedEvent event) {
		execute(
			event,
			event.getPlayer(),
			event.getWorld(),
			event.getCurrentWeight(),
			event.getMaxWeight(),
			event.getLoadPercent()
		);
	}