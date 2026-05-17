<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getSaturation(${input$ENTITY})
<#else>
0
</#if>
