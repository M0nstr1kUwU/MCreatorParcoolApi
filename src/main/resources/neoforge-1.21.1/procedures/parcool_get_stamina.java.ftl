<#if input$ENTITY??>
(${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player
	? com.alrex.parcool.api.Stamina.get(_player).getValue()
	: 0)
<#else>
0
</#if>