<#if input$ENTITY??>
((java.util.function.Supplier<Double>) () -> {
	try {
		if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
			net.minecraft.world.entity.ai.attributes.AttributeInstance _attribute =
				_player.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY);

			return _attribute != null ? _attribute.getValue() : 0.0;
		}
	} catch (Throwable ignored) {
	}
	return 0.0;
}).get()
<#else>
0
</#if>