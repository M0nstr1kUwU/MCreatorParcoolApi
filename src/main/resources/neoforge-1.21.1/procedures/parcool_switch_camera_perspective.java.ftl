<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.network.ParCoolApiCameraNetwork.sendToPlayer(_serverPlayer, "${field$PERSPECTIVE}");
}
</#if>