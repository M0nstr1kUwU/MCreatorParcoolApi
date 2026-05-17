package ${package}.hitbox;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityDimensions;
import net.minecraft.world.level.saveddata.SavedData;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.EntityEvent;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

@EventBusSubscriber(modid = "${modid}")
public final class HitboxApiBridge {
	private static final String DATA_NAME = "${modid}_hitbox_api_v1";

	private HitboxApiBridge() {
	}

	public static double getWidth(Entity entity) {
		return entity != null ? entity.getBbWidth() : 0.0D;
	}

	public static double getHeight(Entity entity) {
		return entity != null ? entity.getBbHeight() : 0.0D;
	}

	public static double getEyeHeight(Entity entity) {
		return entity != null ? entity.getEyeHeight() : 0.0D;
	}

	public static double getXSize(Entity entity) {
		return entity != null ? entity.getBoundingBox().getXsize() : 0.0D;
	}

	public static double getYSize(Entity entity) {
		return entity != null ? entity.getBoundingBox().getYsize() : 0.0D;
	}

	public static double getZSize(Entity entity) {
		return entity != null ? entity.getBoundingBox().getZsize() : 0.0D;
	}

	public static boolean setTemporaryHitbox(Entity entity, double width, double height) {
		if (entity == null) {
			return false;
		}

		float safeWidth = safeSize(width);
		float safeHeight = safeSize(height);
		double half = safeWidth / 2.0D;

		entity.setBoundingBox(new net.minecraft.world.phys.AABB(
			entity.getX() - half,
			entity.getY(),
			entity.getZ() - half,
			entity.getX() + half,
			entity.getY() + safeHeight,
			entity.getZ() + half
		));

		return true;
	}

	public static boolean setPersistentHitbox(Entity entity, double width, double height) {
		if (entity == null || entity.level().isClientSide()) {
			return false;
		}

		HitboxSavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		float safeWidth = safeSize(width);
		float safeHeight = safeSize(height);

		data.entries.put(entity.getUUID(), new HitboxEntry(safeWidth, safeHeight));
		data.setDirty();

		entity.refreshDimensions();
		setTemporaryHitbox(entity, safeWidth, safeHeight);

		return true;
	}

	public static boolean multiplyPersistentHitbox(Entity entity, double widthMultiplier, double heightMultiplier) {
		if (entity == null || entity.level().isClientSide()) {
			return false;
		}

		return setPersistentHitbox(
			entity,
			Math.max(0.01D, entity.getBbWidth()) * Math.max(0.01D, widthMultiplier),
			Math.max(0.01D, entity.getBbHeight()) * Math.max(0.01D, heightMultiplier)
		);
	}

	public static boolean clearPersistentHitbox(Entity entity) {
		if (entity == null || entity.level().isClientSide()) {
			return false;
		}

		HitboxSavedData data = getSavedData();

		if (data == null) {
			return false;
		}

		boolean removed = data.entries.remove(entity.getUUID()) != null;

		if (removed) {
			data.setDirty();
			entity.refreshDimensions();
		}

		return removed;
	}

	public static boolean hasPersistentHitbox(Entity entity) {
		if (entity == null || entity.level().isClientSide()) {
			return false;
		}

		HitboxSavedData data = getSavedData();
		return data != null && data.entries.containsKey(entity.getUUID());
	}

	public static double getPersistentWidth(Entity entity) {
		if (entity == null || entity.level().isClientSide()) {
			return 0.0D;
		}

		HitboxSavedData data = getSavedData();

		if (data == null) {
			return 0.0D;
		}

		HitboxEntry entry = data.entries.get(entity.getUUID());
		return entry != null ? entry.width : 0.0D;
	}

	public static double getPersistentHeight(Entity entity) {
		if (entity == null || entity.level().isClientSide()) {
			return 0.0D;
		}

		HitboxSavedData data = getSavedData();

		if (data == null) {
			return 0.0D;
		}

		HitboxEntry entry = data.entries.get(entity.getUUID());
		return entry != null ? entry.height : 0.0D;
	}

	public static boolean refresh(Entity entity) {
		if (entity == null) {
			return false;
		}

		entity.refreshDimensions();
		return true;
	}

	@SubscribeEvent
	public static void onEntitySize(EntityEvent.Size event) {
		Entity entity = event.getEntity();

		if (entity == null || entity.level().isClientSide()) {
			return;
		}

		HitboxSavedData data = getSavedData();

		if (data == null) {
			return;
		}

		HitboxEntry entry = data.entries.get(entity.getUUID());

		if (entry == null) {
			return;
		}

		event.setNewSize(EntityDimensions.scalable(entry.width, entry.height));
	}

	private static float safeSize(double value) {
		if (Double.isNaN(value) || Double.isInfinite(value)) {
			return 0.6F;
		}

		return (float) Math.max(0.01D, Math.min(64.0D, value));
	}

	private static HitboxSavedData getSavedData() {
		try {
			MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

			if (server == null) {
				return null;
			}

			ServerLevel overworld = server.overworld();

			if (overworld == null) {
				return null;
			}

			return overworld.getDataStorage().computeIfAbsent(
				new SavedData.Factory<>(HitboxSavedData::new, HitboxSavedData::load, null),
				DATA_NAME
			);
		} catch (Throwable ignored) {
			return null;
		}
	}

	private record HitboxEntry(float width, float height) {
	}

	public static final class HitboxSavedData extends SavedData {
		private final Map<UUID, HitboxEntry> entries = new ConcurrentHashMap<>();

		public static HitboxSavedData load(CompoundTag tag, HolderLookup.Provider provider) {
			HitboxSavedData data = new HitboxSavedData();
			ListTag list = tag.getList("Entries", Tag.TAG_COMPOUND);

			for (int i = 0; i < list.size(); i++) {
				CompoundTag entryTag = list.getCompound(i);

				try {
					UUID uuid = UUID.fromString(entryTag.getString("UUID"));
					float width = Math.max(0.01F, Math.min(64.0F, entryTag.getFloat("Width")));
					float height = Math.max(0.01F, Math.min(64.0F, entryTag.getFloat("Height")));

					data.entries.put(uuid, new HitboxEntry(width, height));
				} catch (Throwable ignored) {
				}
			}

			return data;
		}

		@Override
		public CompoundTag save(CompoundTag tag, HolderLookup.Provider provider) {
			ListTag list = new ListTag();

			for (Map.Entry<UUID, HitboxEntry> entry : entries.entrySet()) {
				CompoundTag entryTag = new CompoundTag();

				entryTag.putString("UUID", entry.getKey().toString());
				entryTag.putFloat("Width", entry.getValue().width);
				entryTag.putFloat("Height", entry.getValue().height);

				list.add(entryTag);
			}

			tag.put("Entries", list);
			return tag;
		}
	}
}
