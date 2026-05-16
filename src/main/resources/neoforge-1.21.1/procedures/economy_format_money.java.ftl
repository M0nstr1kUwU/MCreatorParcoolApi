<#if input$AMOUNT??>
${package}.economy.EconomyApiSystem.formatMoney((long) ${input$AMOUNT})
<#else>
"0 Cooper"
</#if>
