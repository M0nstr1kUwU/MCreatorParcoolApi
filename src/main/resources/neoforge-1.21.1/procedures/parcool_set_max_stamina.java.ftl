<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
	try {
		final int _newMax = (int) Math.max(10, Math.min(10000, Math.round(${input$VALUE})));

		final net.minecraft.world.entity.ai.attributes.AttributeInstance _attribute =
			_player.getAttribute(com.alrex.parcool.api.Attributes.MAX_STAMINA);

		if (_attribute != null) {
			_attribute.setBaseValue(_newMax);
		}

		final Object _attachment = com.alrex.parcool.common.attachment.Attachments.STAMINA.get();
		final java.lang.reflect.Method _getData = _player.getClass().getMethod(
			"getData",
			net.neoforged.neoforge.attachment.AttachmentType.class
		);
		final Object _current = _getData.invoke(_player, _attachment);

		final int _currentValue = (int) _current.getClass().getMethod("value").invoke(_current);
		final int _newValue = Math.max(0, Math.min(_currentValue, _newMax));

		final java.lang.reflect.Constructor<?> _constructor =
			_current.getClass().getDeclaredConstructor(boolean.class, int.class, int.class);
		_constructor.setAccessible(true);

		final Object _newStamina = _constructor.newInstance(false, _newValue, _newMax);

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