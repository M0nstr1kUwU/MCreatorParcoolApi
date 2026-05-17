package ${package}.attributes;

import net.minecraft.core.Holder;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.Attribute;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;

public final class AttributeApiBridge {
	private AttributeApiBridge() {
	}

	public static double getAttributeBase(Entity entity, String attributeId) {
		AttributeInstance instance = getInstance(entity, attributeId);
		return instance != null ? instance.getBaseValue() : 0.0D;
	}

	public static double getAttributeValue(Entity entity, String attributeId) {
		AttributeInstance instance = getInstance(entity, attributeId);
		return instance != null ? instance.getValue() : 0.0D;
	}

	public static boolean setAttributeBase(Entity entity, String attributeId, double value) {
		AttributeInstance instance = getInstance(entity, attributeId);

		if (instance == null) {
			return false;
		}

		instance.setBaseValue(safeValue(value));
		return true;
	}

	public static boolean addAttributeBase(Entity entity, String attributeId, double value) {
		AttributeInstance instance = getInstance(entity, attributeId);

		if (instance == null) {
			return false;
		}

		instance.setBaseValue(safeValue(instance.getBaseValue() + value));
		return true;
	}

	public static boolean multiplyAttributeBase(Entity entity, String attributeId, double multiplier) {
		AttributeInstance instance = getInstance(entity, attributeId);

		if (instance == null) {
			return false;
		}

		instance.setBaseValue(safeValue(instance.getBaseValue() * multiplier));
		return true;
	}

	public static boolean hasAttribute(Entity entity, String attributeId) {
		return getInstance(entity, attributeId) != null;
	}

	private static AttributeInstance getInstance(Entity entity, String attributeId) {
		if (!(entity instanceof LivingEntity living)) {
			return null;
		}

		Holder<Attribute> holder = resolveAttribute(attributeId);

		if (holder == null) {
			return null;
		}

		return living.getAttribute(holder);
	}

	private static Holder<Attribute> resolveAttribute(String attributeId) {
		try {
			String id = normalize(attributeId);
			ResourceKey<Attribute> key = ResourceKey.create(Registries.ATTRIBUTE, ResourceLocation.parse(id));
			return BuiltInRegistries.ATTRIBUTE.getHolder(key).orElse(null);
		} catch (Throwable ignored) {
			return null;
		}
	}

	private static String normalize(String attributeId) {
		if (attributeId == null || attributeId.isBlank()) {
			return "minecraft:max_health";
		}

		String id = attributeId.trim().toLowerCase(java.util.Locale.ROOT);

		if (!id.contains(":")) {
			id = "minecraft:" + id;
		}

		return id;
	}

	private static double safeValue(double value) {
		if (Double.isNaN(value) || Double.isInfinite(value)) {
			return 0.0D;
		}

		return Math.max(-1024.0D, Math.min(1024.0D, value));
	}

	public static boolean setHealth(Entity entity, double value) {
		if (!(entity instanceof LivingEntity living)) {
			return false;
		}

		living.setHealth((float) Math.max(0.0D, Math.min(living.getMaxHealth(), value)));
		return true;
	}

	public static boolean heal(Entity entity, double value) {
		if (!(entity instanceof LivingEntity living)) {
			return false;
		}

		living.heal((float) Math.max(0.0D, value));
		return true;
	}

	public static boolean hurt(Entity entity, double value) {
		if (!(entity instanceof LivingEntity living)) {
			return false;
		}

		living.hurt(living.damageSources().generic(), (float) Math.max(0.0D, value));
		return true;
	}

	public static double getHealth(Entity entity) {
		return entity instanceof LivingEntity living ? living.getHealth() : 0.0D;
	}

	public static double getMaxHealth(Entity entity) {
		return entity instanceof LivingEntity living ? living.getMaxHealth() : 0.0D;
	}

	public static boolean setAbsorption(Entity entity, double value) {
		if (!(entity instanceof LivingEntity living)) {
			return false;
		}

		living.setAbsorptionAmount((float) Math.max(0.0D, Math.min(1024.0D, value)));
		return true;
	}

	public static double getAbsorption(Entity entity) {
		return entity instanceof LivingEntity living ? living.getAbsorptionAmount() : 0.0D;
	}

	public static boolean setAirSupply(Entity entity, int value) {
		if (entity == null) {
			return false;
		}

		entity.setAirSupply(Math.max(0, Math.min(30000, value)));
		return true;
	}

	public static int getAirSupply(Entity entity) {
		return entity != null ? entity.getAirSupply() : 0;
	}

	public static boolean setRemainingFireTicks(Entity entity, int value) {
		if (entity == null) {
			return false;
		}

		entity.setRemainingFireTicks(Math.max(0, Math.min(30000, value)));
		return true;
	}

	public static int getRemainingFireTicks(Entity entity) {
		return entity != null ? entity.getRemainingFireTicks() : 0;
	}

	public static boolean setTicksFrozen(Entity entity, int value) {
		if (entity == null) {
			return false;
		}

		entity.setTicksFrozen(Math.max(0, Math.min(30000, value)));
		return true;
	}

	public static int getTicksFrozen(Entity entity) {
		return entity != null ? entity.getTicksFrozen() : 0;
	}

	public static boolean setNoGravity(Entity entity, boolean value) {
		if (entity == null) {
			return false;
		}

		entity.setNoGravity(value);
		return true;
	}

	public static boolean isNoGravity(Entity entity) {
		return entity != null && entity.isNoGravity();
	}

	public static boolean setGlowing(Entity entity, boolean value) {
		if (entity == null) {
			return false;
		}

		entity.setGlowingTag(value);
		return true;
	}

	public static boolean isGlowing(Entity entity) {
		return entity != null && entity.isCurrentlyGlowing();
	}

	public static boolean setInvulnerable(Entity entity, boolean value) {
		if (entity == null) {
			return false;
		}

		entity.setInvulnerable(value);
		return true;
	}

	public static boolean isInvulnerable(Entity entity) {
		return entity != null && entity.isInvulnerable();
	}

	public static boolean setSilent(Entity entity, boolean value) {
		if (entity == null) {
			return false;
		}

		entity.setSilent(value);
		return true;
	}

	public static boolean isSilent(Entity entity) {
		return entity != null && entity.isSilent();
	}

	public static boolean setCustomNameVisible(Entity entity, boolean value) {
		if (entity == null) {
			return false;
		}

		entity.setCustomNameVisible(value);
		return true;
	}

	public static boolean isCustomNameVisible(Entity entity) {
		return entity != null && entity.isCustomNameVisible();
	}

	public static boolean setFoodLevel(Entity entity, int value) {
		if (!(entity instanceof ServerPlayer player)) {
			return false;
		}

		player.getFoodData().setFoodLevel(Math.max(0, Math.min(20, value)));
		return true;
	}

	public static int getFoodLevel(Entity entity) {
		return entity instanceof ServerPlayer player ? player.getFoodData().getFoodLevel() : 0;
	}

	public static boolean setSaturation(Entity entity, double value) {
		if (!(entity instanceof ServerPlayer player)) {
			return false;
		}

		player.getFoodData().setSaturation(Math.max(0.0F, Math.min(20.0F, (float) value)));
		return true;
	}

	public static double getSaturation(Entity entity) {
		return entity instanceof ServerPlayer player ? player.getFoodData().getSaturationLevel() : 0.0D;
	}

	public static boolean setExhaustion(Entity entity, double value) {
		if (!(entity instanceof ServerPlayer player)) {
			return false;
		}

		player.getFoodData().setExhaustion(Math.max(0.0F, Math.min(40.0F, (float) value)));
		return true;
	}
}
