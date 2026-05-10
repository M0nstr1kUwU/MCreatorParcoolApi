<#if input$entity??>
((${input$entity}) instanceof net.minecraft.world.entity.player.Player
	? ${package}.weight.ParCoolApiWeightSystem.getMaxCarryWeight((net.minecraft.world.entity.player.Player) (${input$entity}))
	: 0)
<#else>
0
</#if>