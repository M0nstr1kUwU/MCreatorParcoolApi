<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setOverlayPosition(_serverPlayer, "${field$POSITION}");
}
</#if>