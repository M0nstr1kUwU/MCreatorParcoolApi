<#if input$entity??>
if ((<#if input$condition??>${input$condition}<#else>false</#if>) && ${input$entity} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.parcool.ParCoolApiMovementBridge.disableAllMovements(_serverPlayer);
}
</#if>