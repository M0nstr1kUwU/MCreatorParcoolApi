<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setAbsorption(${input$ENTITY}, ${input$VALUE});
</#if>
