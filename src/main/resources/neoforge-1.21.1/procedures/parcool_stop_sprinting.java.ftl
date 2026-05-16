<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
	try {
		if (_player.isSprinting()) {
			_player.setSprinting(false);
			_player.hasImpulse = true;
		}
	} catch (Throwable ignored) {
	}
}
</#if>