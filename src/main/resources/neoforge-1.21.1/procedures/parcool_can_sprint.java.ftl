<#if input$ENTITY??>
((java.util.function.Supplier<Boolean>) () -> {
	try {
		if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
			return com.alrex.parcool.common.info.ServerLimitation.get(_serverPlayer)
				.isPermitted(com.alrex.parcool.common.action.impl.FastRun.class);
		}
		if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
			return com.alrex.parcool.common.attachment.common.Parkourability.get(_player)
				.getActionInfo()
				.can(com.alrex.parcool.common.action.impl.FastRun.class);
		}
	} catch (Throwable ignored) {
	}
	return false;
}).get()
<#else>
false
</#if>