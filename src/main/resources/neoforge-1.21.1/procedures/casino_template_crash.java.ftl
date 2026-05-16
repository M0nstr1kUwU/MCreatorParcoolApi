<#if input$ENTITY?? && input$AMOUNT?? && input$CASHOUT?? && input$MAX?? && input$SEND_MESSAGES??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer)
	&& ${package}.economy.EconomyApiCasinoTemplates.playCrash(_serverPlayer, (double) ${input$AMOUNT}, "${field$COIN}", (double) ${input$CASHOUT}, (double) ${input$MAX}, ${input$SEND_MESSAGES}))
<#else>
false
</#if>
