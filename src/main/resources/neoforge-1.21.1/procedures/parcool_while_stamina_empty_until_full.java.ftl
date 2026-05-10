<#-- @formatter:off -->
<#if input$entity??>
if (${input$entity} instanceof net.minecraft.server.level.ServerPlayer __parcoolStaminaServerPlayer) {
	if (${package}.parcool.ParCoolApiStaminaMonitor.shouldRunEmptyUntilFull(__parcoolStaminaServerPlayer)) {
		${statement$do}
	}
}
</#if>
<#-- @formatter:on -->