<#if input$ENTITY??>
((java.util.function.Supplier<Boolean>) () -> {
	try {
		if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
			return com.alrex.parcool.common.attachment.common.Parkourability.get(_player)
				.isDoingAny(
					com.alrex.parcool.common.action.impl.HangDown.class,
					com.alrex.parcool.common.action.impl.ClingToCliff.class
				);
		}
	} catch (Throwable ignored) {
	}
	return false;
}).get()
<#else>
false
</#if>