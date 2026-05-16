<#if input$ENTITY?? && input$X1?? && input$Y1?? && input$Z1?? && input$X2?? && input$Y2?? && input$Z2??>
if (${input$ENTITY} != null) {
	double _minX = Math.min(${input$X1}, ${input$X2});
	double _minY = Math.min(${input$Y1}, ${input$Y2});
	double _minZ = Math.min(${input$Z1}, ${input$Z2});
	double _maxX = Math.max(${input$X1}, ${input$X2});
	double _maxY = Math.max(${input$Y1}, ${input$Y2});
	double _maxZ = Math.max(${input$Z1}, ${input$Z2});

	double _entityX = ${input$ENTITY}.getX();
	double _entityY = ${input$ENTITY}.getY();
	double _entityZ = ${input$ENTITY}.getZ();

	if (_entityX >= _minX && _entityX <= _maxX
			&& _entityY >= _minY && _entityY <= _maxY
			&& _entityZ >= _minZ && _entityZ <= _maxZ) {
		${statement$DO}
	}
}
</#if>