<#if input$entity?? && input$ticks??>
if (${input$entity} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	try {
		${package}.network.ParCoolApiCameraNetwork.sendToPlayer(
			_serverPlayer,
			"${field$PERSPECTIVE}",
			${opt.toInt(input$ticks)}
		);
	} catch (Throwable ignored) {
	}
}
</#if>