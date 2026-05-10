<#if input$entity?? && input$decimals??>
((java.util.function.Supplier<Double>) () -> {
	try {
		if (!((${input$entity}) instanceof net.minecraft.world.entity.player.Player)) {
			return 0.0;
		}

		net.minecraft.world.entity.player.Player __parcoolApiWeightPercentPlayer =
			(net.minecraft.world.entity.player.Player) (${input$entity});

		double __parcoolApiWeightPercent =
			${package}.weight.ParCoolApiWeightSystem.getLoadPercent(__parcoolApiWeightPercentPlayer);

		int __parcoolApiDecimals = (int) Math.max(0, Math.min(10, Math.round(${input$decimals})));
		double __parcoolApiScale = Math.pow(10.0, __parcoolApiDecimals);

		return Math.round(__parcoolApiWeightPercent * __parcoolApiScale) / __parcoolApiScale;
	} catch (Throwable ignored) {
		return 0.0;
	}
}).get()
<#else>
0
</#if>