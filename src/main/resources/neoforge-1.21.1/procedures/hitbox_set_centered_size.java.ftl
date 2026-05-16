<#if input$ENTITY?? && input$WIDTH?? && input$HEIGHT??>
if (${input$ENTITY} != null) {
	${package}.hitbox.HitboxApiBridge.setCenteredBox(${input$ENTITY}, ${input$WIDTH}, ${input$HEIGHT});
}
</#if>