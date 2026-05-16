<#if input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.Entity _entity) {
	try {
		net.minecraft.world.phys.Vec3 _motion = _entity.getDeltaMovement();

		if (_motion.y > 0.0D) {
			_entity.setDeltaMovement(_motion.x, 0.0D, _motion.z);
			_entity.fallDistance = 0.0F;
			_entity.hasImpulse = true;

			if (!_entity.level().isClientSide()
					&& _entity.level() instanceof net.minecraft.server.level.ServerLevel _serverLevel) {
				_serverLevel.getChunkSource().broadcastAndSend(
					_entity,
					new net.minecraft.network.protocol.game.ClientboundSetEntityMotionPacket(_entity)
				);
			}
		}
	} catch (Throwable ignored) {
	}
}
</#if>