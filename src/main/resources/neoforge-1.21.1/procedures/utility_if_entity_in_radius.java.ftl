<#if input$ENTITY?? && input$RADIUS?? && input$X?? && input$Y?? && input$Z??>
if (${input$ENTITY} != null) {
	double _dx = ${input$ENTITY}.getX() - (${input$X});
	double _dy = ${input$ENTITY}.getY() - (${input$Y});
	double _dz = ${input$ENTITY}.getZ() - (${input$Z});
	double _radius = Math.max(0.0D, ${input$RADIUS});

	if ((_dx * _dx + _dy * _dy + _dz * _dz) <= (_radius * _radius)) {
		${statement$DO}
	}
}
</#if>