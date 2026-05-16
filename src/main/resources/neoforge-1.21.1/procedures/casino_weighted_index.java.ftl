<#if input$WEIGHTS??>
${package}.economy.EconomyApiCasino.weightedIndex(String.valueOf(${input$WEIGHTS}))
<#else>
-1
</#if>