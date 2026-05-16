<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent
	public static void onParCoolWeightHeavyOverloadStarted(${package}.events.ParCoolApiBridgeEvents.WeightHeavyOverloadStartedEvent event) {
		<#assign dependenciesCode>
			<@procedureDependenciesCode dependencies, {
				"entity": "event.getPlayer()",
				"world": "event.getWorld()",
				"current_weight": "event.getCurrentWeight()",
				"max_weight": "event.getMaxWeight()",
				"load_percent": "event.getLoadPercent()",
				"event": "event"
			}/>
		</#assign>
		execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
	}