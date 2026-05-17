<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setShowSelf(_serverPlayer, ${input$VALUE});
}
</#if>
