<#if input$ENTITY??>
((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player
	? ${package}.parcool.ParCoolApiStaminaBridge.getStamina((net.minecraft.world.entity.player.Player) (${input$ENTITY}))
	: 0)
<#else>
0
</#if>