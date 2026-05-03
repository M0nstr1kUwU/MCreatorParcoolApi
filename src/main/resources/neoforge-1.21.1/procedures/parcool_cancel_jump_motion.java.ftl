<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.Entity _e) {
    var _motion = _e.getDeltaMovement();
    if (_motion.y > 0) {
        _e.setDeltaMovement(_motion.x, 0, _motion.z);
        _e.fallDistance = 0;
    }
}
</#if>