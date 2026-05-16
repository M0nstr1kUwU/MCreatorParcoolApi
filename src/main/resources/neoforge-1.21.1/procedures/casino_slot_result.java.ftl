<#if input$SYMBOLS??>
${package}.economy.EconomyApiCasino.slotResult(${opt.toInt(input$SYMBOLS)})
<#else>
"1,1,1"
</#if>