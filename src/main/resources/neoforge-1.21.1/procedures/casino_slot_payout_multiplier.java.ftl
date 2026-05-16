<#if input$RESULT?? && input$JACKPOT?? && input$PAIR?? && input$MISS??>
${package}.economy.EconomyApiCasino.slotPayoutMultiplier(String.valueOf(${input$RESULT}), ${input$JACKPOT}, ${input$PAIR}, ${input$MISS})
<#else>
0
</#if>