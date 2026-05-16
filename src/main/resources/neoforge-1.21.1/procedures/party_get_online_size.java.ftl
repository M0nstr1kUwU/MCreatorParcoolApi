<#if input$ENTITY??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) ? ${package}.party.PartyApiSystem.getOnlinePartySize(_serverPlayer) : 0)
<#else>
0
</#if>