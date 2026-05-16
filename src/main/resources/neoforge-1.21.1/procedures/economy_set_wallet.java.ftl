<#if input$ENTITY?? && input$AMOUNT??>
${package}.economy.EconomyApiSystem.setWallet(${input$ENTITY}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"));
</#if>
