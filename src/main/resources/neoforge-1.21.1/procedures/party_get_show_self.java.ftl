<#if input$ENTITY??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) && ${package}.party.PartyApiSystem.getShowSelf(_serverPlayer))
<#else>
false
</#if>
