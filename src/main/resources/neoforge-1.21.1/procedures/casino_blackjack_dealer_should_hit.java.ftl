<#if input$RANKS??>
${package}.economy.EconomyApiCasino.blackjackDealerShouldHit(String.valueOf(${input$RANKS}))
<#else>
false
</#if>