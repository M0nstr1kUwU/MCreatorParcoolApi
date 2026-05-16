<#if input$DICE?? && input$SIDES??>
${package}.economy.EconomyApiCasino.diceSum(${opt.toInt(input$DICE)}, ${opt.toInt(input$SIDES)})
<#else>
0
</#if>