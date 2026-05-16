<#if input$ENTITY?? && input$MESSAGE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.sendMessageToParty(_serverPlayer, ${input$MESSAGE});
}
</#if>
