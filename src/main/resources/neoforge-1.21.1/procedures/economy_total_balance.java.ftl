<#if input$ENTITY??>
${package}.economy.EconomyApiSystem.getTotal(${input$ENTITY})
<#else>
0
</#if>
