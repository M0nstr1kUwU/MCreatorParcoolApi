<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiNameVisibility.hideFromTab(_serverPlayer);
}
</#if>
