<#if input$entity??>
(${input$entity} instanceof net.minecraft.world.entity.player.Player _player
	? ${package}.weight.ParCoolApiWeightSystem.getInventoryWeight(_player)
	: 0)
<#else>
0
</#if>