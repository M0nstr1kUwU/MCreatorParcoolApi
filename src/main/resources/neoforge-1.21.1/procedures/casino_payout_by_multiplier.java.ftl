<#if input$BET?? && input$MULTIPLIER?? && input$HOUSE_EDGE??>
${package}.economy.EconomyApiCasino.payoutByMultiplier((long) ${input$BET}, ${input$MULTIPLIER}, ${input$HOUSE_EDGE})
<#else>
0
</#if>