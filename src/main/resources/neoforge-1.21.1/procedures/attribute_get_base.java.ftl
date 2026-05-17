<#if input$ENTITY?? && input$ATTRIBUTE_ID??>
${package}.attributes.AttributeApiBridge.getAttributeBase(${input$ENTITY}, String.valueOf(${input$ATTRIBUTE_ID}))
<#else>
0
</#if>
