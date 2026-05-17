<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getAirSupply(${input$ENTITY})
<#else>
0
</#if>
