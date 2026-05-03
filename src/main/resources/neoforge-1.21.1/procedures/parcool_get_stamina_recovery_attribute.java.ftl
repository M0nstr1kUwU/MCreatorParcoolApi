<#if input$ENTITY??>
(${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player
    ? (_player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY) != null
        ? _player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY).getValue()
        : 0)
    : 0)
<#else>
0
</#if>