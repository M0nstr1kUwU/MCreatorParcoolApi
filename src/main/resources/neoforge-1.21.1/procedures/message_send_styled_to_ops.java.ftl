<#if input$PERMISSION_LEVEL?? && input$TEXT?? && input$COLOR?? && input$BOLD?? && input$ITALIC?? && input$UNDERLINE?? && input$STRIKETHROUGH?? && input$OBFUSCATED?? && input$ACTIONBAR??>
${package}.message.MessageApiHelper.sendToOperators(
	${package}.message.MessageApiHelper.styled(
		String.valueOf(${input$TEXT}),
		String.valueOf(${input$COLOR}),
		${input$BOLD},
		${input$ITALIC},
		${input$UNDERLINE},
		${input$STRIKETHROUGH},
		${input$OBFUSCATED}
	),
	${input$ACTIONBAR},
	${opt.toInt(input$PERMISSION_LEVEL)}
);
</#if>