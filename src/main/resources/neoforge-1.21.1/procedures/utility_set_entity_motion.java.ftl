<#if input$ENTITY?? && input$X?? && input$Y?? && input$Z??>
if (${input$ENTITY} != null) {
	${input$ENTITY}.setDeltaMovement(new net.minecraft.world.phys.Vec3(${input$X}, ${input$Y}, ${input$Z}));
	${input$ENTITY}.hurtMarked = true;
}
</#if>