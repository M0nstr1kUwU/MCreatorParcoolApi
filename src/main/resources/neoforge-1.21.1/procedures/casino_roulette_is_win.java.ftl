<#if input$CHOICE?? && input$NUMBER??>
${package}.economy.EconomyApiCasino.rouletteIsWin("${field$BET_TYPE}", String.valueOf(${input$CHOICE}), ${opt.toInt(input$NUMBER)})
<#else>
false
</#if>