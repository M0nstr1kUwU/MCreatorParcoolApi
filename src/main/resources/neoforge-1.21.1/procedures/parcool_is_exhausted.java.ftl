<#if input$ENTITY??>
(${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player
    ? com.alrex.parcool.api.Stamina.get(_player).isExhausted()
    : false)
<#else>
false
</#if>