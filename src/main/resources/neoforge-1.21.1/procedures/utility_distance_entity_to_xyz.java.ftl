<#if input$ENTITY?? && input$X?? && input$Y?? && input$Z??>
((${input$ENTITY}) != null
	? Math.sqrt(
		Math.pow((${input$ENTITY}).getX() - (${input$X}), 2)
			+ Math.pow((${input$ENTITY}).getY() - (${input$Y}), 2)
			+ Math.pow((${input$ENTITY}).getZ() - (${input$Z}), 2)
	)
	: 0)
<#else>
0
</#if>