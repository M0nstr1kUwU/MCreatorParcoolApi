package ${package}.events;

import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.LevelAccessor;

import net.neoforged.bus.api.Event;
import net.neoforged.neoforge.common.NeoForge;

public final class ParCoolApiBridgeEvents {
	public static final int WEIGHT_STATUS_NORMAL = 0;
	public static final int WEIGHT_STATUS_OVERLOADED = 1;
	public static final int WEIGHT_STATUS_HEAVY_OVERLOADED = 2;
	public static final int WEIGHT_STATUS_CRITICAL_OVERLOADED = 3;

	public static final int ABILITY_SPRINT = 1;
	public static final int ABILITY_CLIMB = 2;
	public static final int ABILITY_JUMP = 3;
	public static final int ABILITY_HANG = 4;
	public static final int ABILITY_WALL_RUN = 5;
	public static final int ABILITY_ALL_MOVEMENTS = 6;

	public static final int CAMERA_FIRST_PERSON = 0;
	public static final int CAMERA_THIRD_PERSON_BACK = 1;
	public static final int CAMERA_THIRD_PERSON_FRONT = 2;

	private ParCoolApiBridgeEvents() {
	}

	public static void fireWeightStatusChanged(Player player, int oldStatus, int newStatus, double currentWeight, double maxWeight, double loadPercent) {
		if (player == null) {
			return;
		}

		NeoForge.EVENT_BUS.post(new WeightStatusChangedEvent(player, oldStatus, newStatus, currentWeight, maxWeight, loadPercent));

		if (oldStatus <= WEIGHT_STATUS_NORMAL && newStatus > WEIGHT_STATUS_NORMAL) {
			NeoForge.EVENT_BUS.post(new WeightOverloadStartedEvent(player, currentWeight, maxWeight, loadPercent));
		}

		if (oldStatus > WEIGHT_STATUS_NORMAL && newStatus <= WEIGHT_STATUS_NORMAL) {
			NeoForge.EVENT_BUS.post(new WeightOverloadEndedEvent(player, currentWeight, maxWeight, loadPercent));
		}

		if (oldStatus < WEIGHT_STATUS_HEAVY_OVERLOADED && newStatus >= WEIGHT_STATUS_HEAVY_OVERLOADED) {
			NeoForge.EVENT_BUS.post(new WeightHeavyOverloadStartedEvent(player, currentWeight, maxWeight, loadPercent));
		}

		if (oldStatus < WEIGHT_STATUS_CRITICAL_OVERLOADED && newStatus >= WEIGHT_STATUS_CRITICAL_OVERLOADED) {
			NeoForge.EVENT_BUS.post(new WeightCriticalOverloadStartedEvent(player, currentWeight, maxWeight, loadPercent));
		}
	}

	public static void fireMovementAbilityChanged(Player player, int abilityId, boolean enabled) {
		if (player != null) {
			NeoForge.EVENT_BUS.post(new MovementAbilityChangedEvent(player, abilityId, enabled));
		}
	}

	public static void firePermissionsForceSynced(Player player) {
		if (player != null) {
			NeoForge.EVENT_BUS.post(new PermissionsForceSyncedEvent(player));
		}
	}

	public static void fireCameraPerspectiveRequested(Player player, int perspectiveId) {
		if (player != null) {
			NeoForge.EVENT_BUS.post(new CameraPerspectiveRequestedEvent(player, perspectiveId));
		}
	}

	public static void fireItemEnchantmentsStripped(ItemStack itemStack) {
		if (itemStack != null && !itemStack.isEmpty()) {
			NeoForge.EVENT_BUS.post(new ItemEnchantmentsStrippedEvent(itemStack.copy()));
		}
	}

	public static void fireClientWaitFinished(Player player) {
		if (player != null) {
			NeoForge.EVENT_BUS.post(new ClientWaitFinishedEvent(player));
		}
	}

	public static class WeightStatusChangedEvent extends Event {
		private final Player player;
		private final int oldStatus;
		private final int newStatus;
		private final double currentWeight;
		private final double maxWeight;
		private final double loadPercent;

		public WeightStatusChangedEvent(Player player, int oldStatus, int newStatus, double currentWeight, double maxWeight, double loadPercent) {
			this.player = player;
			this.oldStatus = oldStatus;
			this.newStatus = newStatus;
			this.currentWeight = currentWeight;
			this.maxWeight = maxWeight;
			this.loadPercent = loadPercent;
		}

		public Player getPlayer() {
			return player;
		}

		public LevelAccessor getWorld() {
			return player.level();
		}

		public int getOldStatus() {
			return oldStatus;
		}

		public int getNewStatus() {
			return newStatus;
		}

		public double getCurrentWeight() {
			return currentWeight;
		}

		public double getMaxWeight() {
			return maxWeight;
		}

		public double getLoadPercent() {
			return loadPercent;
		}
	}

	public static class WeightOverloadStartedEvent extends Event {
		private final Player player;
		private final double currentWeight;
		private final double maxWeight;
		private final double loadPercent;

		public WeightOverloadStartedEvent(Player player, double currentWeight, double maxWeight, double loadPercent) {
			this.player = player;
			this.currentWeight = currentWeight;
			this.maxWeight = maxWeight;
			this.loadPercent = loadPercent;
		}

		public Player getPlayer() {
			return player;
		}

		public LevelAccessor getWorld() {
			return player.level();
		}

		public double getCurrentWeight() {
			return currentWeight;
		}

		public double getMaxWeight() {
			return maxWeight;
		}

		public double getLoadPercent() {
			return loadPercent;
		}
	}

	public static class WeightOverloadEndedEvent extends WeightOverloadStartedEvent {
		public WeightOverloadEndedEvent(Player player, double currentWeight, double maxWeight, double loadPercent) {
			super(player, currentWeight, maxWeight, loadPercent);
		}
	}

	public static class WeightHeavyOverloadStartedEvent extends WeightOverloadStartedEvent {
		public WeightHeavyOverloadStartedEvent(Player player, double currentWeight, double maxWeight, double loadPercent) {
			super(player, currentWeight, maxWeight, loadPercent);
		}
	}

	public static class WeightCriticalOverloadStartedEvent extends WeightOverloadStartedEvent {
		public WeightCriticalOverloadStartedEvent(Player player, double currentWeight, double maxWeight, double loadPercent) {
			super(player, currentWeight, maxWeight, loadPercent);
		}
	}

	public static class MovementAbilityChangedEvent extends Event {
		private final Player player;
		private final int abilityId;
		private final boolean enabled;

		public MovementAbilityChangedEvent(Player player, int abilityId, boolean enabled) {
			this.player = player;
			this.abilityId = abilityId;
			this.enabled = enabled;
		}

		public Player getPlayer() {
			return player;
		}

		public LevelAccessor getWorld() {
			return player.level();
		}

		public int getAbilityId() {
			return abilityId;
		}

		public boolean isEnabled() {
			return enabled;
		}
	}

	public static class PermissionsForceSyncedEvent extends Event {
		private final Player player;

		public PermissionsForceSyncedEvent(Player player) {
			this.player = player;
		}

		public Player getPlayer() {
			return player;
		}

		public LevelAccessor getWorld() {
			return player.level();
		}
	}

	public static class CameraPerspectiveRequestedEvent extends Event {
		private final Player player;
		private final int perspectiveId;

		public CameraPerspectiveRequestedEvent(Player player, int perspectiveId) {
			this.player = player;
			this.perspectiveId = perspectiveId;
		}

		public Player getPlayer() {
			return player;
		}

		public LevelAccessor getWorld() {
			return player.level();
		}

		public int getPerspectiveId() {
			return perspectiveId;
		}
	}

	public static class ItemEnchantmentsStrippedEvent extends Event {
		private final ItemStack itemStack;

		public ItemEnchantmentsStrippedEvent(ItemStack itemStack) {
			this.itemStack = itemStack;
		}

		public ItemStack getItemStack() {
			return itemStack;
		}
	}

	public static class ClientWaitFinishedEvent extends Event {
		private final Player player;

		public ClientWaitFinishedEvent(Player player) {
			this.player = player;
		}

		public Player getPlayer() {
			return player;
		}

		public LevelAccessor getWorld() {
			return player.level();
		}
	}
}