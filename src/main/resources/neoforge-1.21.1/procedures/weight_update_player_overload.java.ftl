<#if input$entity??>
if (${input$entity} instanceof net.minecraft.world.entity.player.Player _player) {
	${package}.weight.ParCoolApiWeightSystem.updatePlayerWeightState(_player);
}
</#if>