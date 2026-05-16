<#if input$ENTITY?? && input$ENABLED??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.parcool.ParCoolApiVanillaJumpBridge.setVanillaJumpDisabled(_serverPlayer, ${input$ENABLED});
}
</#if>