<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent
	public static void onParCoolItemEnchantmentsStripped(${package}.events.ParCoolApiBridgeEvents.ItemEnchantmentsStrippedEvent event) {
		<#assign dependenciesCode>
			<@procedureDependenciesCode dependencies, {
				"itemstack": "event.getItemStack()",
				"event": "event"
			}/>
		</#assign>
		execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
	}