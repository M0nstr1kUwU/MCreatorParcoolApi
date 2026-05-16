<#if input$GENERATED?? && input$CASHOUT??>
${package}.economy.EconomyApiCasino.crashCashoutWins(${input$GENERATED}, ${input$CASHOUT})
<#else>
false
</#if>