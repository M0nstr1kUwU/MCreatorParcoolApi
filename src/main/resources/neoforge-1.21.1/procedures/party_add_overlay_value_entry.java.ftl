<#if input$ENTITY?? && input$ID?? && input$LABEL?? && input$VALUE?? && input$X?? && input$Y?? && input$WIDTH?? && input$HEIGHT?? && input$TEXTURE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.addOverlayValueEntry(_serverPlayer, String.valueOf(${input$ID}), String.valueOf(${input$LABEL}), String.valueOf(${input$VALUE}), ${opt.toInt(input$X)}, ${opt.toInt(input$Y)}, ${opt.toInt(input$WIDTH)}, ${opt.toInt(input$HEIGHT)}, String.valueOf(${input$TEXTURE}));
}
</#if>
