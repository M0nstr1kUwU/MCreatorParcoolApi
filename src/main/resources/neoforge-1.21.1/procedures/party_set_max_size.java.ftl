<#if input$ENTITY?? && input$SIZE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setPartyMaxMembers(_serverPlayer, ${opt.toInt(input$SIZE)});
}
</#if>