<#if input$MIN?? && input$MAX??>
${package}.economy.EconomyApiCasino.rollDouble(${input$MIN}, ${input$MAX})
<#else>
0
</#if>