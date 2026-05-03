<#if input$ENTITY?? && input$DECIMALS??>
(${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player
    ? (
        com.alrex.parcool.api.Stamina.get(_player).getMaxValue() <= 0
            ? 0
            : (
                Math.round(
                    (
                        (double) com.alrex.parcool.api.Stamina.get(_player).getValue()
                        / (double) com.alrex.parcool.api.Stamina.get(_player).getMaxValue()
                        * 100.0
                    )
                    * Math.pow(10, (int) ${input$DECIMALS})
                ) / Math.pow(10, (int) ${input$DECIMALS})
              )
      )
    : 0)
<#else>
0
</#if>