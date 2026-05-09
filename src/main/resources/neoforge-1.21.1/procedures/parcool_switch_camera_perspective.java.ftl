<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	try {
		${package}.network.ParCoolApiCameraNetwork.sendToPlayer(_serverPlayer, "${field$PERSPECTIVE}");
	} catch (Throwable ignored) {
	}
}
</#if>