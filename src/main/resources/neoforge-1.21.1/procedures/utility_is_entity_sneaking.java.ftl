<#if input$ENTITY??>
((${input$ENTITY}) != null && (${input$ENTITY}).isShiftKeyDown())
<#else>
false
</#if>