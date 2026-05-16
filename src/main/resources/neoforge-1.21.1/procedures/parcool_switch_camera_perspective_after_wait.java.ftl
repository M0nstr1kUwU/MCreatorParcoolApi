<#if input$ENTITY?? && input$TICKS??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.network.ParCoolApiCameraNetwork.sendToPlayer(
		_serverPlayer,
		"${field$PERSPECTIVE}",
		${opt.toInt(input$TICKS)}
	);
}
</#if>