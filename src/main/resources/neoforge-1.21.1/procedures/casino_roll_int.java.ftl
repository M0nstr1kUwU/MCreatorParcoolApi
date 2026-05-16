<#if input$MIN?? && input$MAX??>
${package}.economy.EconomyApiCasino.rollInt(${opt.toInt(input$MIN)}, ${opt.toInt(input$MAX)})
<#else>
0
</#if>