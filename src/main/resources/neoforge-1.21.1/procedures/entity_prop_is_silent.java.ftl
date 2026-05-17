<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.isSilent(${input$ENTITY})
<#else>
false
</#if>
