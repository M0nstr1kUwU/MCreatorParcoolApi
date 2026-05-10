<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent
	public static void onParCoolWeightStatusChanged(${package}.events.ParCoolApiBridgeEvents.WeightStatusChangedEvent event) {
		<#assign dependenciesCode>
			<@procedureDependenciesCode dependencies, {
				"entity": "event.getPlayer()",
				"world": "event.getWorld()",
				"old_status": "event.getOldStatus()",
				"new_status": "event.getNewStatus()",
				"current_weight": "event.getCurrentWeight()",
				"max_weight": "event.getMaxWeight()",
				"load_percent": "event.getLoadPercent()",
				"event": "event"
			}/>
		</#assign>
		execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
	}