<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getFoodLevel(${input$ENTITY})
<#else>
0
</#if>
