<#if input$FROM?? && input$TO?? && input$AMOUNT??>
${package}.economy.EconomyApiSystem.transferWallet(${input$FROM}, ${input$TO}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"));
</#if>
