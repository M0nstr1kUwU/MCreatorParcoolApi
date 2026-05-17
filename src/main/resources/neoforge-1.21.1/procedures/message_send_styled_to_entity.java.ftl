<#if input$ENTITY?? && input$TEXT?? && input$COLOR?? && input$BOLD?? && input$ITALIC?? && input$UNDERLINE?? && input$STRIKETHROUGH?? && input$OBFUSCATED??>
${package}.message.MessageApiHelper.sendToEntity(
	${input$ENTITY},
	${package}.message.MessageApiHelper.styled(
		String.valueOf(${input$TEXT}),
		String.valueOf(${input$COLOR}),
		${input$BOLD},
		${input$ITALIC},
		${input$UNDERLINE},
		${input$STRIKETHROUGH},
		${input$OBFUSCATED}
	),
	false
);
</#if>