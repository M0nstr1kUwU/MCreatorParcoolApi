<#if input$entity?? && input$weight??>
if (${input$entity} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.weight.ParCoolApiWeightSystem.setMaxCarryWeight(_serverPlayer, (double) ${input$weight});
}
</#if>