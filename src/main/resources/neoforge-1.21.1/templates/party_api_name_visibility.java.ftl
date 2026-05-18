package ${package}.party;

import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minecraft.network.protocol.game.ClientboundPlayerInfoRemovePacket;
import net.minecraft.network.protocol.game.ClientboundPlayerInfoUpdatePacket;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.scores.PlayerTeam;
import net.minecraft.world.scores.Scoreboard;
import net.minecraft.world.scores.Team;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.player.PlayerEvent;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiNameVisibility {
	private static final String HIDDEN_NAME_TEAM = "${modid}_hidden_nametags";
	private static final Map<UUID, String> ORIGINAL_TEAMS = new ConcurrentHashMap<>();
	private static final Set<UUID> TAB_HIDDEN = ConcurrentHashMap.newKeySet();

	private PartyApiNameVisibility() {
	}

	public static boolean hideNameTag(ServerPlayer player) {
		if (player == null || player.server == null) {
			return false;
		}

		try {
			Scoreboard scoreboard = player.server.getScoreboard();
			PlayerTeam hiddenTeam = getOrCreateHiddenNameTeam(scoreboard);
			String playerName = player.getScoreboardName();
			PlayerTeam currentTeam = scoreboard.getPlayersTeam(playerName);

			if (currentTeam != null && !HIDDEN_NAME_TEAM.equals(currentTeam.getName())) {
				ORIGINAL_TEAMS.put(player.getUUID(), currentTeam.getName());
			}

			scoreboard.addPlayerToTeam(playerName, hiddenTeam);
			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	public static boolean showNameTag(ServerPlayer player) {
		if (player == null || player.server == null) {
			return false;
		}

		try {
			Scoreboard scoreboard = player.server.getScoreboard();
			String playerName = player.getScoreboardName();
			PlayerTeam currentTeam = scoreboard.getPlayersTeam(playerName);

			if (currentTeam != null && HIDDEN_NAME_TEAM.equals(currentTeam.getName())) {
				scoreboard.removePlayerFromTeam(playerName, currentTeam);
			}

			String originalTeamName = ORIGINAL_TEAMS.remove(player.getUUID());

			if (originalTeamName != null && !originalTeamName.isBlank() && !HIDDEN_NAME_TEAM.equals(originalTeamName)) {
				PlayerTeam originalTeam = scoreboard.getPlayerTeam(originalTeamName);

				if (originalTeam != null) {
					scoreboard.addPlayerToTeam(playerName, originalTeam);
				}
			}

			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	public static void hideAllNameTags() {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return;
		}

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			hideNameTag(player);
		}
	}

	public static void showAllNameTags() {
		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();

		if (server == null) {
			return;
		}

		for (ServerPlayer player : server.getPlayerList().getPlayers()) {
			showNameTag(player);
		}
	}

	public static boolean hideFromTab(ServerPlayer player) {
		if (player == null || player.server == null) {
			return false;
		}

		try {
			TAB_HIDDEN.add(player.getUUID());
			ClientboundPlayerInfoRemovePacket packet = new ClientboundPlayerInfoRemovePacket(List.of(player.getUUID()));

			for (ServerPlayer viewer : player.server.getPlayerList().getPlayers()) {
				viewer.connection.send(packet);
			}

			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	public static boolean showInTab(ServerPlayer player) {
		if (player == null || player.server == null) {
			return false;
		}

		try {
			TAB_HIDDEN.remove(player.getUUID());

			ClientboundPlayerInfoUpdatePacket packet = new ClientboundPlayerInfoUpdatePacket(
				EnumSet.allOf(ClientboundPlayerInfoUpdatePacket.Action.class),
				List.of(player)
			);

			for (ServerPlayer viewer : player.server.getPlayerList().getPlayers()) {
				viewer.connection.send(packet);
			}

			return true;
		} catch (Throwable ignored) {
			return false;
		}
	}

	@SubscribeEvent
	public static void onPlayerLogin(PlayerEvent.PlayerLoggedInEvent event) {
		if (!(event.getEntity() instanceof ServerPlayer joined)) {
			return;
		}

		try {
			for (UUID hiddenId : TAB_HIDDEN) {
				if (hiddenId.equals(joined.getUUID())) {
					continue;
				}

				ServerPlayer hiddenPlayer = joined.server.getPlayerList().getPlayer(hiddenId);

				if (hiddenPlayer != null) {
					joined.connection.send(new ClientboundPlayerInfoRemovePacket(List.of(hiddenId)));
				}
			}

			if (TAB_HIDDEN.contains(joined.getUUID())) {
				hideFromTab(joined);
			}
		} catch (Throwable ignored) {
		}
	}

	private static PlayerTeam getOrCreateHiddenNameTeam(Scoreboard scoreboard) {
		PlayerTeam team = scoreboard.getPlayerTeam(HIDDEN_NAME_TEAM);

		if (team == null) {
			team = scoreboard.addPlayerTeam(HIDDEN_NAME_TEAM);
			team.setNameTagVisibility(Team.Visibility.NEVER);
			team.setSeeFriendlyInvisibles(false);
			team.setAllowFriendlyFire(true);
		} else {
			team.setNameTagVisibility(Team.Visibility.NEVER);
		}

		return team;
	}
}
