<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setHealth(${input$ENTITY}, ${input$VALUE});
</#if>
