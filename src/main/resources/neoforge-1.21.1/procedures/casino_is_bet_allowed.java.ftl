<#if input$AMOUNT??>
${package}.economy.EconomyApiSystem.isCasinoBetAllowed(${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"))
<#else>
false
</#if>