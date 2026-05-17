<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setAirSupply(${input$ENTITY}, ${input$VALUE});
</#if>
