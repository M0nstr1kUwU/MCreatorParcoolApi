<#if input$ENTITY?? && input$AMOUNT??>
${package}.economy.EconomyApiSystem.addWallet(${input$ENTITY}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"));
</#if>
