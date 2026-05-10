<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent
	public static void onParCoolPermissionsForceSynced(${package}.events.ParCoolApiBridgeEvents.PermissionsForceSyncedEvent event) {
		<#assign dependenciesCode>
			<@procedureDependenciesCode dependencies, {
				"entity": "event.getPlayer()",
				"world": "event.getWorld()",
				"event": "event"
			}/>
		</#assign>
		execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
	}