<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent
	public static void onParCoolMovementAbilityChanged(${package}.events.ParCoolApiBridgeEvents.MovementAbilityChangedEvent event) {
		<#assign dependenciesCode>
			<@procedureDependenciesCode dependencies, {
				"entity": "event.getPlayer()",
				"world": "event.getWorld()",
				"ability_id": "event.getAbilityId()",
				"enabled": "event.isEnabled()",
				"event": "event"
			}/>
		</#assign>
		execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
	}