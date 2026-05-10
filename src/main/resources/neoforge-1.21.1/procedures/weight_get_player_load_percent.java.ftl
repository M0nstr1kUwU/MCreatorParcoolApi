<#if input$entity?? && input$decimals??>
(${input$entity} instanceof net.minecraft.world.entity.player.Player _player
	? ((java.util.function.Supplier<Double>) () -> {
		try {
			double _percent = ${package}.weight.ParCoolApiWeightSystem.getLoadPercent(_player);

			int _decimals = (int) Math.max(0, Math.min(10, Math.round(${input$decimals})));
			double _scale = Math.pow(10.0, _decimals);

			return Math.round(_percent * _scale) / _scale;
		} catch (Throwable ignored) {
			return 0.0;
		}
	}).get()
	: 0)
<#else>
0
</#if>