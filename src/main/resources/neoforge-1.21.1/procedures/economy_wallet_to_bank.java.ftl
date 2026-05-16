<#if input$ENTITY?? && input$AMOUNT??>
${package}.economy.EconomyApiSystem.moveWalletToBank(${input$ENTITY}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"));
</#if>
