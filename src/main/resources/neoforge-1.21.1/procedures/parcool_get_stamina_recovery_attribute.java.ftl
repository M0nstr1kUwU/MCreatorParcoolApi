<#if input$ENTITY??>
((java.util.function.Supplier<Double>) () -> {
	try {
		if (!((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player)) {
			return 0.0;
		}

		net.minecraft.world.entity.player.Player __parcoolApiRecoveryPlayer =
			(net.minecraft.world.entity.player.Player) (${input$ENTITY});

		net.minecraft.world.entity.ai.attributes.AttributeInstance __parcoolApiRecoveryAttribute =
			__parcoolApiRecoveryPlayer.getAttribute(com.alrex.parcool.api.Attributes.STAMINA_RECOVERY);

		return __parcoolApiRecoveryAttribute != null ? __parcoolApiRecoveryAttribute.getValue() : 0.0;
	} catch (Throwable ignored) {
		return 0.0;
	}
}).get()
<#else>
0
</#if>