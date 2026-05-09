<#if input$ENTITY??>
((java.util.function.Supplier<Boolean>) () -> {
	try {
		if (${input$ENTITY} instanceof net.minecraft.server.level.ServerPlayer _serverPlayer) {
			com.alrex.parcool.common.info.ServerLimitation _limitation =
				com.alrex.parcool.common.info.ServerLimitation.get(_serverPlayer);
			return _limitation.isPermitted(com.alrex.parcool.common.action.impl.ClimbUp.class)
				|| _limitation.isPermitted(com.alrex.parcool.common.action.impl.ClimbPoles.class);
		}
		if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
			com.alrex.parcool.common.info.ActionInfo _info =
				com.alrex.parcool.common.attachment.common.Parkourability.get(_player).getActionInfo();
			return _info.can(com.alrex.parcool.common.action.impl.ClimbUp.class)
				|| _info.can(com.alrex.parcool.common.action.impl.ClimbPoles.class);
		}
	} catch (Throwable ignored) {
	}
	return false;
}).get()
<#else>
false
</#if>