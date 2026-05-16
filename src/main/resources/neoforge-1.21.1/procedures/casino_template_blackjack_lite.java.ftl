<#if input$ENTITY?? && input$AMOUNT?? && input$SEND_MESSAGES??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer)
	&& ${package}.economy.EconomyApiCasinoTemplates.playBlackjackLite(_serverPlayer, (double) ${input$AMOUNT}, "${field$COIN}", ${input$SEND_MESSAGES}))
<#else>
false
</#if>
