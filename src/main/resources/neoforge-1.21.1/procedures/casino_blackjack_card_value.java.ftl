<#if input$RANK??>
${package}.economy.EconomyApiCasino.blackjackCardValue(${opt.toInt(input$RANK)})
<#else>
0
</#if>