<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
    var _attr = _player.getAttribute(com.alrex.parcool.api.Attributes.MAX_STAMINA);
    if (_attr != null) {
        _attr.setBaseValue(Math.max(0, Math.round(${input$VALUE})));
    }
}
</#if>