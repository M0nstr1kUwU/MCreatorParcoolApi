<#if input$ENTITY?? && input$SHOW_SELF?? && input$X?? && input$Y??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.initializeOverlayLayout(_serverPlayer, ${input$SHOW_SELF}, ${opt.toInt(input$X)}, ${opt.toInt(input$Y)});
}
</#if>
