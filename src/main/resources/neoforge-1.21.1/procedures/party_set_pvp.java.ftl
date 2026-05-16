<#if input$ENTITY?? && input$ENABLED??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setPvp(_serverPlayer, ${input$ENABLED});
}
</#if>