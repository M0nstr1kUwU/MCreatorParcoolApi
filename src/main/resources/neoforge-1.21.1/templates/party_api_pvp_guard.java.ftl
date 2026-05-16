package ${package}.party;

import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.projectile.Projectile;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.living.LivingIncomingDamageEvent;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiPvpGuard {
	private PartyApiPvpGuard() {
	}

	@SubscribeEvent
	public static void onLivingIncomingDamage(LivingIncomingDamageEvent event) {
		if (!PartyApiServerConfig.pvpProtectionEnabled()) {
			return;
		}

		if (!(event.getEntity() instanceof ServerPlayer target)) {
			return;
		}

		ServerPlayer attacker = resolveAttackingPlayer(event.getSource().getEntity(), event.getSource().getDirectEntity());

		if (attacker == null) {
			return;
		}

		if (PartyApiSystem.shouldCancelPvpDamage(attacker, target)) {
			event.setCanceled(true);
		}
	}

	private static ServerPlayer resolveAttackingPlayer(Entity sourceEntity, Entity directEntity) {
		if (sourceEntity instanceof ServerPlayer player) {
			return player;
		}

		if (directEntity instanceof ServerPlayer player) {
			return player;
		}

		if (directEntity instanceof Projectile projectile && projectile.getOwner() instanceof ServerPlayer player) {
			return player;
		}

		return null;
	}
}
