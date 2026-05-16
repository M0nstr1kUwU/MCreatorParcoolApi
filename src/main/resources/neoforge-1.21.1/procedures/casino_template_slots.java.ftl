<#if input$ENTITY?? && input$AMOUNT?? && input$SYMBOLS?? && input$JACKPOT?? && input$PAIR?? && input$MISS?? && input$SEND_MESSAGES??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer)
	&& ${package}.economy.EconomyApiCasinoTemplates.playSlots(_serverPlayer, (double) ${input$AMOUNT}, "${field$COIN}", ${opt.toInt(input$SYMBOLS)}, (double) ${input$JACKPOT}, (double) ${input$PAIR}, (double) ${input$MISS}, ${input$SEND_MESSAGES}))
<#else>
false
</#if>
