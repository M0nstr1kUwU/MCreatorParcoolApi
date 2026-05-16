<#if input$KEY?? && input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	${package}.party.PartyApiSystem.setPlayerStat(_serverPlayer, String.valueOf(${input$KEY}), String.valueOf(${input$VALUE}));
}
</#if>