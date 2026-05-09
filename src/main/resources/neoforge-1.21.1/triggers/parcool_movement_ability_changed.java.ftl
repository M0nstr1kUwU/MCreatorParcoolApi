@net.neoforged.fml.common.EventBusSubscriber(modid = "${modid}")
public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent
	public static void onParCoolMovementAbilityChanged(${package}.events.ParCoolApiBridgeEvents.MovementAbilityChangedEvent event) {
		execute(
			event,
			event.getPlayer(),
			event.getWorld(),
			event.getAbilityId(),
			event.isEnabled()
		);
	}