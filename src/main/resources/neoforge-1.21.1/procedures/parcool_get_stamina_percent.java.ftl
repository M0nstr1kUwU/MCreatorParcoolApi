<#if input$ENTITY?? && input$DECIMALS??>
((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player
	? ${package}.parcool.ParCoolApiStaminaBridge.getStaminaPercent((net.minecraft.world.entity.player.Player) (${input$ENTITY}), (double) ${input$DECIMALS})
	: 0)
<#else>
0
</#if>