<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
	try {
		com.alrex.parcool.common.info.ServerLimitation _serverLimitation =
			com.alrex.parcool.common.info.ServerLimitation.get(_serverPlayer);

		if (_serverLimitation.isPermitted(com.alrex.parcool.common.action.impl.FastRun.class)) {
			com.alrex.parcool.server.limitation.Limitation _limitation =
				com.alrex.parcool.server.limitation.Limitations.createLimitationOf(
					_serverPlayer.getUUID(),
					new com.alrex.parcool.server.limitation.Limitation.ID("parcool_api", "mcreator_bridge")
				);

			_limitation.setEnabled(true);
			_limitation.setPossibilityOf(com.alrex.parcool.common.action.impl.FastRun.class, false);

			try {
				Class<?> _limitationsClass = Class.forName("com.alrex.parcool.server.limitation.Limitations");

				try {
					_limitationsClass
						.getMethod("updateOnlyLimitation", net.minecraft.server.level.ServerPlayer.class)
						.invoke(null, _serverPlayer);
				} catch (NoSuchMethodException _missingUpdateOnlyLimitation) {
					_limitationsClass
						.getMethod("update", net.minecraft.server.level.ServerPlayer.class)
						.invoke(null, _serverPlayer);
				}
			} catch (Throwable ignoredSync) {
			}
		}
	} catch (Throwable ignored) {
	}
}
</#if>