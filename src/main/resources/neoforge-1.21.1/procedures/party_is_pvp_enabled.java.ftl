<#if input$ENTITY??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) ? ${package}.party.PartyApiSystem.isPartyPvpEnabled(_serverPlayer) : true)
<#else>
true
</#if>
