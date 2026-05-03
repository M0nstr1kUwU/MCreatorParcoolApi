<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
    var _attr = _player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY);
    if (_attr != null) {
        _attr.setBaseValue((double) ${input$VALUE});
    }
}
</#if>