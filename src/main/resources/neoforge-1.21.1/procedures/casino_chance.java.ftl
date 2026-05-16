<#if input$PERCENT?? && input$HOUSE_EDGE??>
${package}.economy.EconomyApiCasino.chance(${input$PERCENT}, ${input$HOUSE_EDGE})
<#else>
false
</#if>