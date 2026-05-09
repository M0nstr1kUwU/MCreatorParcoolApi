<#if input$entity??>
(${input$entity} instanceof net.minecraft.world.entity.player.Player _player
	? ${package}.weight.ParCoolApiWeightSystem.isOverloaded(_player)
	: false)
<#else>
false
</#if>