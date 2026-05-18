<#if input$ENTITY?? && input$KEY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.clearPlayerStat(_serverPlayer, String.valueOf(${input$KEY}));
}
</#if>
