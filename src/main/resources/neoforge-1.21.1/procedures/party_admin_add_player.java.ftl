<#if input$ENTITY?? && input$TARGET?? && input$IGNORE_LIMIT??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _partyMember && ${input$TARGET} instanceof net.minecraft.server.level.ServerPlayer _targetPlayer) {
	${package}.party.PartyApiSystem.adminAddPlayerToParty(_partyMember, _targetPlayer, ${input$IGNORE_LIMIT});
}
</#if>
