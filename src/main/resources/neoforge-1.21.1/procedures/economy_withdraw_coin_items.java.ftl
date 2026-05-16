<#if input$ENTITY?? && input$AMOUNT_ITEMS??>
${package}.economy.EconomyApiSystem.withdrawCoinItemsFromBank(${input$ENTITY}, "${field$COIN}", ${opt.toInt(input$AMOUNT_ITEMS)})
<#else>
0
</#if>
