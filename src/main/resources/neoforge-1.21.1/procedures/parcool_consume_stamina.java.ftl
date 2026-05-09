<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
	try {
		final Object _attachment = com.alrex.parcool.common.attachment.Attachments.STAMINA.get();

		final java.lang.reflect.Method _getData = _player.getClass().getMethod(
			"getData",
			net.neoforged.neoforge.attachment.AttachmentType.class
		);
		final Object _current = _getData.invoke(_player, _attachment);

		final int _amount = (int) Math.max(0, Math.round(${input$VALUE}));
		final Object _newStamina = _current.getClass().getMethod("consumed", int.class).invoke(_current, _amount);

		final java.lang.reflect.Method _setData = _player.getClass().getMethod(
			"setData",
			net.neoforged.neoforge.attachment.AttachmentType.class,
			Object.class
		);
		_setData.invoke(_player, _attachment, _newStamina);

		if (!_player.level().isClientSide()) {
			try {
				Class<?> _broadcasterClass = Class.forName("com.alrex.parcool.common.network.StaminaSynchronizationBroadcaster");
				_broadcasterClass
					.getMethod("add", java.util.UUID.class, _newStamina.getClass())
					.invoke(null, _player.getUUID(), _newStamina);
			} catch (Throwable ignoredSync) {
			}
		}
	} catch (Throwable ignored) {
	}
}
</#if>