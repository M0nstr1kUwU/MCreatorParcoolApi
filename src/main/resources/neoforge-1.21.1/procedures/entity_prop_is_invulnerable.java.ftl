<#if input$ENTITY??>
${package}.attributes.AttributeApiBridge.isInvulnerable(${input$ENTITY})
<#else>
false
</#if>
