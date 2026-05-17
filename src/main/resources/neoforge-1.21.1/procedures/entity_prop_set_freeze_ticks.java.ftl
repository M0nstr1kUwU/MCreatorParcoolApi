<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setTicksFrozen(${input$ENTITY}, ${input$VALUE});
</#if>
