<#if input$ENTITY?? && input$TARGET??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _partyLeader && ${input$TARGET} instanceof net.minecraft.server.level.ServerPlayer _newLeader) {
	${package}.party.PartyApiSystem.transferLeadership(_partyLeader, _newLeader);
}
</#if>
