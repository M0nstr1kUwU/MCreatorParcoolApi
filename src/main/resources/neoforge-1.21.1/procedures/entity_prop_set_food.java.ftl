<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.setFoodLevel(${input$ENTITY}, ${input$VALUE});
</#if>
