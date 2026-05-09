<#if input$ENTITY?? && input$VALUE??>
    if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
        _player.getPersistentData().putBoolean("parcool_climb_disabled", ${input$VALUE});
    }
</#if>