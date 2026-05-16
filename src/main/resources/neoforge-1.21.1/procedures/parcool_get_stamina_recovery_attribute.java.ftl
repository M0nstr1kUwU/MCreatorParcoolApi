<#if input$ENTITY??>
((${input$ENTITY}) instanceof net.minecraft.server.level.ServerPlayer
	? ${package}.parcool.ParCoolApiStaminaBridge.getStaminaRecovery((net.minecraft.server.level.ServerPlayer) (${input$ENTITY}))
	: 0)
<#else>
0
</#if>