<#if input$ENTITY?? && input$WEIGHT??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.weight.ParCoolApiWeightSystem.setMaxCarryWeight(_serverPlayer, (double) ${input$WEIGHT});
}
</#if>