<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.createParty(_serverPlayer, "${field$SHOW_SELF}" == "TRUE");
}
</#if>