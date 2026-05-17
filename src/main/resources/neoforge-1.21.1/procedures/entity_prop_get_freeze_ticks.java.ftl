<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getTicksFrozen(${input$ENTITY})
<#else>
0
</#if>
