<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.getAbsorption(${input$ENTITY})
<#else>
0
</#if>
