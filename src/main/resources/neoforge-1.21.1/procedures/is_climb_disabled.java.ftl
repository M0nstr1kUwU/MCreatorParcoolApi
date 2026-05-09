<#if input$ENTITY??>
    (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player
        ? _player.getPersistentData().getBoolean("parcool_climb_disabled")
        : false)
<#else>
    false
</#if>