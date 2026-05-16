<#if input$ENTITY?? && input$AMOUNT?? && input$MULTIPLIER??>
${package}.economy.EconomyApiSystem.giveCasinoPayout(${input$ENTITY}, ${package}.economy.EconomyApiSystem.toCopper(${input$AMOUNT}, "${field$COIN}"), ${input$MULTIPLIER})
<#else>
0
</#if>
