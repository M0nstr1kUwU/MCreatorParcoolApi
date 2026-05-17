<#if input$ENTITY?? && input$ID?? && input$LABEL?? && input$CURRENT?? && input$MAX?? && input$X?? && input$Y?? && input$WIDTH?? && input$HEIGHT?? && input$TEXTURE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.addOverlayBarEntry(_serverPlayer, String.valueOf(${input$ID}), String.valueOf(${input$LABEL}), ${input$CURRENT}, ${input$MAX}, ${opt.toInt(input$X)}, ${opt.toInt(input$Y)}, ${opt.toInt(input$WIDTH)}, ${opt.toInt(input$HEIGHT)}, String.valueOf(${input$TEXTURE}));
}
</#if>
