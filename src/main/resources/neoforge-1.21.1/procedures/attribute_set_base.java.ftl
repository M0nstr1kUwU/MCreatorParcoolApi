<#if input$ENTITY?? && input$ATTRIBUTE_ID?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setAttributeBase(${input$ENTITY}, String.valueOf(${input$ATTRIBUTE_ID}), ${input$VALUE});
</#if>
