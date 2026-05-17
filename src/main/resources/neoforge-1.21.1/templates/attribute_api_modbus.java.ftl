package ${package}.attributes;

import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.ai.attributes.Attributes;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.EntityAttributeModificationEvent;

@EventBusSubscriber(modid = "${modid}", bus = EventBusSubscriber.Bus.MOD)
public final class AttributeApiModBus {
	private AttributeApiModBus() {
	}

	@SubscribeEvent
	public static void addCommonAttributes(EntityAttributeModificationEvent event) {
		for (EntityType<? extends net.minecraft.world.entity.LivingEntity> type : event.getTypes()) {
			addIfMissing(event, type, Attributes.MAX_HEALTH, 20.0D);
			addIfMissing(event, type, Attributes.FOLLOW_RANGE, 32.0D);
			addIfMissing(event, type, Attributes.KNOCKBACK_RESISTANCE, 0.0D);
			addIfMissing(event, type, Attributes.MOVEMENT_SPEED, 0.1D);
			addIfMissing(event, type, Attributes.FLYING_SPEED, 0.4D);
			addIfMissing(event, type, Attributes.ATTACK_DAMAGE, 2.0D);
			addIfMissing(event, type, Attributes.ATTACK_KNOCKBACK, 0.0D);
			addIfMissing(event, type, Attributes.ATTACK_SPEED, 4.0D);
			addIfMissing(event, type, Attributes.ARMOR, 0.0D);
			addIfMissing(event, type, Attributes.ARMOR_TOUGHNESS, 0.0D);
			addIfMissing(event, type, Attributes.LUCK, 0.0D);
			addIfMissing(event, type, Attributes.SCALE, 1.0D);
			addIfMissing(event, type, Attributes.STEP_HEIGHT, 0.6D);
			addIfMissing(event, type, Attributes.GRAVITY, 0.08D);
			addIfMissing(event, type, Attributes.SAFE_FALL_DISTANCE, 3.0D);
			addIfMissing(event, type, Attributes.FALL_DAMAGE_MULTIPLIER, 1.0D);
			addIfMissing(event, type, Attributes.BLOCK_INTERACTION_RANGE, 4.5D);
			addIfMissing(event, type, Attributes.ENTITY_INTERACTION_RANGE, 3.0D);
			addIfMissing(event, type, Attributes.MOVEMENT_EFFICIENCY, 0.0D);
			addIfMissing(event, type, Attributes.WATER_MOVEMENT_EFFICIENCY, 0.0D);
			addIfMissing(event, type, Attributes.OXYGEN_BONUS, 0.0D);
			addIfMissing(event, type, Attributes.SNEAKING_SPEED, 0.3D);
			addIfMissing(event, type, Attributes.SUBMERGED_MINING_SPEED, 0.2D);
		}
	}

	private static void addIfMissing(
		EntityAttributeModificationEvent event,
		EntityType<? extends net.minecraft.world.entity.LivingEntity> type,
		net.minecraft.core.Holder<net.minecraft.world.entity.ai.attributes.Attribute> attribute,
		double defaultValue
	) {
		if (!event.has(type, attribute)) {
			event.add(type, attribute, defaultValue);
		}
	}
}
