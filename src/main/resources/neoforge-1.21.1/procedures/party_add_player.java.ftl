<#if input$TARGET?? && input$LEADER??>
if (${input$LEADER} instanceof net.minecraft.server.level.ServerPlayer _leader && ${input$TARGET} instanceof net.minecraft.server.level.ServerPlayer _target) {
	${package}.party.PartyApiSystem.invitePlayer(_leader, _target);
	${package}.party.PartyApiSystem.acceptInvite(_target);
}
</#if>