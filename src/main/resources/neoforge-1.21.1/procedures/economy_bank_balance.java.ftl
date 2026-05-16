<#if input$ENTITY??>
${package}.economy.EconomyApiSystem.getBank(${input$ENTITY})
<#else>
0
</#if>
