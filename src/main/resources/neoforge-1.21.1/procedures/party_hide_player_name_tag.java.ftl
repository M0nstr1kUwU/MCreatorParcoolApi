<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiNameVisibility.hideNameTag(_serverPlayer);
}
</#if>
