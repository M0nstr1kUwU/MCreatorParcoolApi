<#if input$entity??>
((${input$entity}) instanceof net.minecraft.world.entity.player.Player
	? ${package}.weight.ParCoolApiWeightSystem.isOverloaded((net.minecraft.world.entity.player.Player) (${input$entity}))
	: false)
<#else>
false
</#if>