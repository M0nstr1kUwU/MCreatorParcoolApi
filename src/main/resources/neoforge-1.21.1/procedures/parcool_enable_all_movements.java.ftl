<#if input$entity??>
if (${input$entity} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.parcool.ParCoolApiMovementBridge.enableAllMovements(_serverPlayer);
}
</#if>