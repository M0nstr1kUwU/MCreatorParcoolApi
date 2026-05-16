<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent
	public static void onParCoolCameraPerspectiveRequested(${package}.events.ParCoolApiBridgeEvents.CameraPerspectiveRequestedEvent event) {
		<#assign dependenciesCode>
			<@procedureDependenciesCode dependencies, {
				"entity": "event.getPlayer()",
				"world": "event.getWorld()",
				"perspective_id": "event.getPerspectiveId()",
				"event": "event"
			}/>
		</#assign>
		execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
	}