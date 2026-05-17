<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setSilent(${input$ENTITY}, ${input$VALUE});
</#if>
