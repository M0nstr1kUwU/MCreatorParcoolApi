package ${package}.hitbox;

import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.AABB;

public final class HitboxApiBridge {
	private HitboxApiBridge() {
	}

	public static double getWidth(Entity entity) {
		return entity != null ? entity.getBbWidth() : 0.0D;
	}

	public static double getHeight(Entity entity) {
		return entity != null ? entity.getBbHeight() : 0.0D;
	}

	public static void setCenteredBox(Entity entity, double width, double height) {
		if (entity == null) {
			return;
		}

		double safeWidth = Math.max(0.05D, width);
		double safeHeight = Math.max(0.05D, height);
		double half = safeWidth / 2.0D;

		entity.setBoundingBox(new AABB(
			entity.getX() - half,
			entity.getY(),
			entity.getZ() - half,
			entity.getX() + half,
			entity.getY() + safeHeight,
			entity.getZ() + half
		));

		entity.hurtMarked = true;
	}

	public static void refreshDimensions(Entity entity) {
		if (entity != null) {
			entity.refreshDimensions();
		}
	}
}