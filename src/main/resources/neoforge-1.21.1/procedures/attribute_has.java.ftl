<#if input$ENTITY?? && input$ATTRIBUTE_ID??>
${package}.attributes.AttributeApiBridge.hasAttribute(${input$ENTITY}, String.valueOf(${input$ATTRIBUTE_ID}))
<#else>
false
</#if>
