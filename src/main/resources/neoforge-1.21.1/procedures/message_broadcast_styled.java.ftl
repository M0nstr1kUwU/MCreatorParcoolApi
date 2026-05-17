<#if input$TEXT?? && input$COLOR?? && input$BOLD?? && input$ITALIC?? && input$UNDERLINE?? && input$STRIKETHROUGH?? && input$OBFUSCATED?? && input$ACTIONBAR??>
${package}.message.MessageApiHelper.broadcast(
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