<#if input$ENTITY?? && input$DECIMALS??>
((${input$ENTITY}) instanceof net.minecraft.world.entity.player.Player
	? ((java.util.function.Supplier<Double>) () -> {
		try {
			double _percent = ${package}.weight.ParCoolApiWeightSystem.getLoadPercent((net.minecraft.world.entity.player.Player) (${input$ENTITY}));
			int _decimals = (int) Math.max(0, Math.min(10, Math.round((double) ${input$DECIMALS})));
			double _scale = Math.pow(10.0D, _decimals);

			return Math.round(_percent * _scale) / _scale;
		} catch (Throwable ignored) {
			return 0.0D;
		}
	}).get()
	: 0)
<#else>
0
</#if>