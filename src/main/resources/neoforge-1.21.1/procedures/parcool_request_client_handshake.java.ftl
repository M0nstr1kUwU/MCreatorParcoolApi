<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.network.ParCoolApiCameraNetwork.requestParCoolClientHandshake(_serverPlayer);
}
</#if>