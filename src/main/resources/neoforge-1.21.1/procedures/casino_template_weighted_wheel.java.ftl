<#if input$ENTITY?? && input$AMOUNT?? && input$WEIGHTS?? && input$MULTIPLIERS?? && input$SEND_MESSAGES??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer)
	&& ${package}.economy.EconomyApiCasinoTemplates.playWeightedWheel(_serverPlayer, (double) ${input$AMOUNT}, "${field$COIN}", String.valueOf(${input$WEIGHTS}), String.valueOf(${input$MULTIPLIERS}), ${input$SEND_MESSAGES}))
<#else>
false
</#if>
