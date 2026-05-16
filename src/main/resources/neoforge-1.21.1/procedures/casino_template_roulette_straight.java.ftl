<#if input$ENTITY?? && input$AMOUNT?? && input$NUMBER?? && input$SEND_MESSAGES??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer)
	&& ${package}.economy.EconomyApiCasinoTemplates.playRouletteStraight(_serverPlayer, (double) ${input$AMOUNT}, "${field$COIN}", ${opt.toInt(input$NUMBER)}, ${input$SEND_MESSAGES}))
<#else>
false
</#if>
