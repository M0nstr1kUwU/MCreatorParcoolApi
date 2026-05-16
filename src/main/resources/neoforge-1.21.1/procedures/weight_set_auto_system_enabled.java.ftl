<#if input$ENTITY?? && input$ENABLED??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.weight.ParCoolApiWeightSystem.setAutoEnabled(_serverPlayer, ${input$ENABLED});
}
</#if>