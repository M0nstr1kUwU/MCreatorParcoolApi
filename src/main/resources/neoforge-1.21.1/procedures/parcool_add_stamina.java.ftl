<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.parcool.ParCoolApiStaminaBridge.addStamina(_serverPlayer, (double) ${input$VALUE});
}
</#if>