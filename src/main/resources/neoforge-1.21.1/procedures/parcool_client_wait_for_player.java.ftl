<#-- @formatter:off -->
<#if input$ENTITY?? && input$TICKS??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _clientWaitPlayer) {
	${package}.client.ParCoolApiClientScheduler.queueClientWorkForLocalPlayer(
		_clientWaitPlayer.getUUID(),
		${opt.toInt(input$TICKS)},
		() -> {
			${statement$do}
		}
	);
}
</#if>
<#-- @formatter:on -->