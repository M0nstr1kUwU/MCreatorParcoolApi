<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getHealth(${input$ENTITY})
<#else>
0
</#if>
