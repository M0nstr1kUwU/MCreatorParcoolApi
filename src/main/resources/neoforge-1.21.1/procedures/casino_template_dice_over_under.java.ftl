<#if input$ENTITY?? && input$AMOUNT?? && input$DICE?? && input$SIDES?? && input$THRESHOLD?? && input$MULTIPLIER?? && input$PUSH_ON_EQUAL?? && input$SEND_MESSAGES??>
((${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer)
	&& ${package}.economy.EconomyApiCasinoTemplates.playDiceOverUnder(_serverPlayer, (double) ${input$AMOUNT}, "${field$COIN}", "${field$CHOICE}", ${opt.toInt(input$DICE)}, ${opt.toInt(input$SIDES)}, ${opt.toInt(input$THRESHOLD)}, (double) ${input$MULTIPLIER}, ${input$PUSH_ON_EQUAL}, ${input$SEND_MESSAGES}))
<#else>
false
</#if>
