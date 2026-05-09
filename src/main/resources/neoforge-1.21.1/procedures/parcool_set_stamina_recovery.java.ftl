<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
	try {
		net.minecraft.world.entity.ai.attributes.AttributeInstance _attribute =
			_player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY);

		if (_attribute != null) {
			_attribute.setBaseValue(Math.max(0.0, Math.min(10000.0, (double) ${input$VALUE})));
		}
	} catch (Throwable ignored) {
	}
}
</#if>