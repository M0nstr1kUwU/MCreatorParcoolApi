<#if input$entity?? && input$enabled??>
if (${input$entity} instanceof net.minecraft.world.entity.player.Player _player) {
	${package}.weight.ParCoolApiWeightSystem.setAutoEnabled(_player, ${input$enabled});
}
</#if>