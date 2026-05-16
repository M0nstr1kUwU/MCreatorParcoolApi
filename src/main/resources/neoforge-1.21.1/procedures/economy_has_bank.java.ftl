<#if input$ENTITY?? && input$AMOUNT??>
${package}.economy.EconomyApiSystem.hasBank(${input$ENTITY}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"))
<#else>
false
</#if>
