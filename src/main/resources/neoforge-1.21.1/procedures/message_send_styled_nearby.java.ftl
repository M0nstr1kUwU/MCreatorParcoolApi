<#if input$ENTITY?? && input$RADIUS?? && input$TEXT?? && input$COLOR?? && input$BOLD?? && input$ITALIC?? && input$UNDERLINE?? && input$STRIKETHROUGH?? && input$OBFUSCATED?? && input$ACTIONBAR??>
${package}.message.MessageApiHelper.sendNearby(
	${input$ENTITY},
	${input$RADIUS},
	${package}.message.MessageApiHelper.styled(
		String.valueOf(${input$TEXT}),
		String.valueOf(${input$COLOR}),
		${input$BOLD},
		${input$ITALIC},
		${input$UNDERLINE},
		${input$STRIKETHROUGH},
		${input$OBFUSCATED}
	),
	${input$ACTIONBAR}
);
</#if>