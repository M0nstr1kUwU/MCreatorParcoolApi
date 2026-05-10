<#if input$ENTITY??>
((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player
	? com.alrex.parcool.api.Stamina.get((net.minecraft.world.entity.player.Player) (${input$ENTITY})).getValue()
	: 0)
<#else>
0
</#if>