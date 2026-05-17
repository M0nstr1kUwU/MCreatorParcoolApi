<#if input$ENTITY?? && input$VALUE??>
${package}.attributes.AttributeApiBridge.heal(${input$ENTITY}, ${input$VALUE});
</#if>
