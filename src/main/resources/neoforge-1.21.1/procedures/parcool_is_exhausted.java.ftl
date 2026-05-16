<#if input$ENTITY??>
((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player
	? ${package}.parcool.ParCoolApiStaminaBridge.isExhausted((net.minecraft.world.entity.player.Player) (${input$ENTITY}))
	: false)
<#else>
false
</#if>