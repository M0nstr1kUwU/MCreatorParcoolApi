<#if input$ENTITY?? && input$DECIMALS??>
((java.util.function.Supplier<Double>) () -> {
	try {
		if (!((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player)) {
			return 0.0;
		}

		net.minecraft.world.entity.player.Player __parcoolApiStaminaPercentPlayer =
			(net.minecraft.world.entity.player.Player) (${input$ENTITY});

		int __parcoolApiStaminaValue = com.alrex.parcool.api.Stamina.get(__parcoolApiStaminaPercentPlayer).getValue();
		int __parcoolApiStaminaMax = com.alrex.parcool.api.Stamina.get(__parcoolApiStaminaPercentPlayer).getMaxValue();

		if (__parcoolApiStaminaMax <= 0) {
			return 0.0;
		}

		int __parcoolApiDecimals = (int) Math.max(0, Math.min(10, Math.round(${input$DECIMALS})));
		double __parcoolApiScale = Math.pow(10.0, __parcoolApiDecimals);
		double __parcoolApiPercent = ((double) __parcoolApiStaminaValue / (double) __parcoolApiStaminaMax) * 100.0;

		return Math.round(__parcoolApiPercent * __parcoolApiScale) / __parcoolApiScale;
	} catch (Throwable ignored) {
		return 0.0;
	}
}).get()
<#else>
0
</#if>