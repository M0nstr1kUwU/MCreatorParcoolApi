<#-- @formatter:off -->
<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer __parcoolStaminaServerPlayer) {
	if (${package}.parcool.ParCoolApiStaminaMonitor.shouldRunEmptyUntilFull(__parcoolStaminaServerPlayer)) {
		${statement$do}
	}
}
</#if>
<#-- @formatter:on -->