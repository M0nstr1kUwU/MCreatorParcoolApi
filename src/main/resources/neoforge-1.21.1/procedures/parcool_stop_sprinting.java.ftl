<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
    _player.setSprinting(false);
}
</#if>