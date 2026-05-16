<#if input$RANK??>
${package}.economy.EconomyApiCasino.cardName(${opt.toInt(input$RANK)}, "${field$SUIT}")
<#else>
"ACE_OF_SPADES"
</#if>