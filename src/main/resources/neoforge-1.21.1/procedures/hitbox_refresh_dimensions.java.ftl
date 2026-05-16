<#if input$ENTITY??>
if (${input$ENTITY} != null) {
	${package}.hitbox.HitboxApiBridge.refreshDimensions(${input$ENTITY});
}
</#if>