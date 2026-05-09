<#if input$ENTITY?? && input$DECIMALS??>
(${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player
	? ((java.util.function.Supplier<Double>) () -> {
		try {
			int _value = com.alrex.parcool.api.Stamina.get(_player).getValue();
			int _max = com.alrex.parcool.api.Stamina.get(_player).getMaxValue();

			if (_max <= 0) {
				return 0.0;
			}

			int _decimals = (int) Math.max(0, Math.min(10, Math.round(${input$DECIMALS})));
			double _scale = Math.pow(10.0, _decimals);
			double _percent = ((double) _value / (double) _max) * 100.0;

			return Math.round(_percent * _scale) / _scale;
		} catch (Throwable ignored) {
			return 0.0;
		}
	}).get()
	: 0)
<#else>
0
</#if>