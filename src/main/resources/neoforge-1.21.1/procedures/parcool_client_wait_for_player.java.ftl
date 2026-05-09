<#-- @formatter:off -->
<#if input$entity?? && input$ticks??>
if (${input$entity} instanceof net.minecraft.world.entity.player.Player _clientWaitPlayer) {
	${package}.client.ParCoolApiClientScheduler.queueClientWorkForLocalPlayer(
		_clientWaitPlayer.getUUID(),
		${opt.toInt(input$ticks)},
		() -> {
			${statement$do}
		}
	);
}
</#if>
<#-- @formatter:on -->