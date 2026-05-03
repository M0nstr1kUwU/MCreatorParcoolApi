<#include "procedures.java.ftl">

@net.neoforged.bus.api.SubscribeEvent
public static void onParcoolActionTryToStart(com.alrex.parcool.api.event.ParcoolActionEvent.TryStart event) {

    if (!(event.getEntity() instanceof net.minecraft.world.entity.player.Player player))
        return;

    <#assign dependenciesCode><#compress>
        <@procedureDependenciesCode dependencies, {
            "entity": "player",
            "event": "event"
        }/>
    </#compress></#assign>

    boolean cancel = execute(player<#if dependenciesCode?has_content>,</#if>${dependenciesCode});

    if (cancel) {
        event.setCanceled(true);
    }
}