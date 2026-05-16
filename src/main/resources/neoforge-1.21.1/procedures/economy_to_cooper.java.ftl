<#if input$AMOUNT??>
${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}")
<#else>
0
</#if>
