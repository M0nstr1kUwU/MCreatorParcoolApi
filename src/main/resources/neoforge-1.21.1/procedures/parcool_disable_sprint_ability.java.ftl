<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.parcool.ParCoolApiMovementBridge.disableSprint(_serverPlayer);
}
</#if>