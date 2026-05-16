<#if input$DICE?? && input$SIDES??>
${package}.economy.EconomyApiCasino.diceCsv(${opt.toInt(input$DICE)}, ${opt.toInt(input$SIDES)})
<#else>
""
</#if>