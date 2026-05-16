<#if input$WEIGHTS?? && input$MULTIPLIERS?? && input$FALLBACK??>
${package}.economy.EconomyApiCasino.weightedMultiplier(String.valueOf(${input$WEIGHTS}), String.valueOf(${input$MULTIPLIERS}), ${input$FALLBACK})
<#else>
0
</#if>