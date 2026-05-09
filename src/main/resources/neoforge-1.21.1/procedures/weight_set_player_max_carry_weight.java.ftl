<#if input$entity?? && input$weight??>
if (${input$entity} instanceof net.minecraft.world.entity.player.Player _player) {
	${package}.weight.ParCoolApiWeightSystem.setMaxCarryWeight(_player, (double) ${input$weight});
}
</#if>