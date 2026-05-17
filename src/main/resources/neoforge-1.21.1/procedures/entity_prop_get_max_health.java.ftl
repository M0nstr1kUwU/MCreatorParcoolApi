<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getMaxHealth(${input$ENTITY})
<#else>
0
</#if>
