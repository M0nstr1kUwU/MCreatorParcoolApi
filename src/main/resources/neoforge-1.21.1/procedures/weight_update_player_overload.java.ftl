<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.weight.ParCoolApiWeightSystem.updatePlayerWeightState(_serverPlayer);
}
</#if>