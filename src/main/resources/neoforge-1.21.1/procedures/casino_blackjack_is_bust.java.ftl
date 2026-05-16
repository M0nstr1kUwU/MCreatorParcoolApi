<#if input$RANKS??>
${package}.economy.EconomyApiCasino.blackjackIsBust(String.valueOf(${input$RANKS}))
<#else>
false
</#if>