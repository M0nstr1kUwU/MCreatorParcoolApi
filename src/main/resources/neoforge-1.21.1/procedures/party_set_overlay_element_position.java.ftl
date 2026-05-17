<#if input$ENTITY?? && input$ELEMENT_ID?? && input$X?? && input$Y??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setOverlayElementPosition(_serverPlayer, String.valueOf(${input$ELEMENT_ID}), ${opt.toInt(input$X)}, ${opt.toInt(input$Y)});
}
</#if>
