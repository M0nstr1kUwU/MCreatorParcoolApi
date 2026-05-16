<#if input$ENTITY?? && input$AMOUNT??>
${package}.economy.EconomyApiSystem.moveBankToWallet(${input$ENTITY}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"));
</#if>
