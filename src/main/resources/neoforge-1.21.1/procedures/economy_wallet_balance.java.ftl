<#if input$ENTITY??>
${package}.economy.EconomyApiSystem.getWallet(${input$ENTITY})
<#else>
0
</#if>
