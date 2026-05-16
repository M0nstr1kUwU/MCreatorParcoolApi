<#if input$ENTITY??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) && ${package}.party.PartyApiSystem.isPartyLeader(_serverPlayer))
<#else>
false
</#if>
