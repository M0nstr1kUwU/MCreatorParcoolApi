<#if input$ENTITY?? && input$X?? && input$Y??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setOverlayPosition(_serverPlayer, ${opt.toInt(input$X)}, ${opt.toInt(input$Y)});
}
</#if>
