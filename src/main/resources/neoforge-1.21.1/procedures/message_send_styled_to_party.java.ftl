<#if input$ENTITY?? && input$TEXT?? && input$COLOR?? && input$BOLD?? && input$ITALIC?? && input$UNDERLINE?? && input$STRIKETHROUGH?? && input$OBFUSCATED??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.sendPartyChatStyled(
		_serverPlayer,
		${package}.message.MessageApiHelper.styled(
			String.valueOf(${input$TEXT}),
			String.valueOf(${input$COLOR}),
			${input$BOLD},
			${input$ITALIC},
			${input$UNDERLINE},
			${input$STRIKETHROUGH},
			${input$OBFUSCATED}
		)
	);
}
</#if>s