package ${package}.party;

import com.mojang.brigadier.arguments.BoolArgumentType;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;

import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.RegisterCommandsEvent;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiCommands {
	private PartyApiCommands() {
	}

	private static boolean ensureEnabled(CommandSourceStack source) {
		if (PartyApiSystem.isPartySystemEnabled()) {
			return true;
		}

		source.sendFailure(Component.literal("Party system is disabled on this server"));
		return false;
	}

	@SubscribeEvent
	public static void registerCommands(RegisterCommandsEvent event) {
		event.getDispatcher().register(
			Commands.literal("party")
				.then(Commands.literal("create")
					.executes(ctx -> {
						if (!ensureEnabled(ctx.getSource())) return 0;
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.createParty(player);
						ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party created" : "Could not create party"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("disband")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.disbandParty(player);
						ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party disbanded" : "Only leader can disband party"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("invite")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.invitePlayer(actor, target);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Invite sent" : "Could not invite player"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("revoke")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.revokeInvite(actor, target);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Invite revoked" : "Could not revoke invite"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("accept")
					.executes(ctx -> {
						if (!ensureEnabled(ctx.getSource())) return 0;
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.acceptInvite(player);
						ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Joined party" : "No invite found or party is full"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("decline")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.declineInvite(player);
						ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Invite declined" : "No invite found"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("leave")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.leaveParty(player);
						ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Left party" : "You are not in party"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("kick")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.kickPlayer(actor, target);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Player kicked" : "Could not kick player"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("transfer")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.transferLeadership(actor, target);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party leadership transferred" : "Only leader can transfer leadership to a party member"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("pvp")
					.then(Commands.argument("enabled", BoolArgumentType.bool())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
							boolean ok = PartyApiSystem.setPvp(player, enabled);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party PvP changed" : "Only leader can change PvP"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("limit")
					.then(Commands.argument("size", IntegerArgumentType.integer(1, 200))
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							int size = IntegerArgumentType.getInteger(ctx, "size");
							boolean ok = PartyApiSystem.setPartyMaxMembers(player, size);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party limit set to " + size : "Only leader can change party limit"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("showself")
					.then(Commands.argument("enabled", BoolArgumentType.bool())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
							boolean ok = PartyApiSystem.setShowSelf(player, enabled);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party show-self changed" : "You are not in party"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("pin")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.setPinned(actor, target, true);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Pinned" : "Could not pin"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("unpin")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.setPinned(actor, target, false);
							ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Unpinned" : "Could not unpin"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("position")
					.then(Commands.argument("x", IntegerArgumentType.integer())
						.then(Commands.argument("y", IntegerArgumentType.integer())
							.executes(ctx -> {
								if (!ensureEnabled(ctx.getSource())) return 0;
								ServerPlayer player = ctx.getSource().getPlayerOrException();
								boolean ok = PartyApiSystem.setOverlayPosition(player, IntegerArgumentType.getInteger(ctx, "x"), IntegerArgumentType.getInteger(ctx, "y"));
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Overlay position changed" : "Could not change position"), false);
								return ok ? 1 : 0;
							})
						)
					)
				)
				.then(Commands.literal("gui")
					.executes(ctx -> {
						if (!ensureEnabled(ctx.getSource())) return 0;
						PartyApiSystem.openPartyMainGui(ctx.getSource().getPlayerOrException());
						return 1;
					})
				)
				.then(Commands.literal("invitegui")
					.executes(ctx -> {
						if (!ensureEnabled(ctx.getSource())) return 0;
						PartyApiSystem.openInviteGui(ctx.getSource().getPlayerOrException());
						return 1;
					})
				)
				.then(Commands.literal("settingsgui")
					.executes(ctx -> {
						if (!ensureEnabled(ctx.getSource())) return 0;
						PartyApiSystem.openSettingsGui(ctx.getSource().getPlayerOrException());
						return 1;
					})
				)
				.then(Commands.literal("chat")
					.then(Commands.argument("message", StringArgumentType.greedyString())
						.executes(ctx -> {
							if (!ensureEnabled(ctx.getSource())) return 0;
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							String message = StringArgumentType.getString(ctx, "message");
							boolean ok = PartyApiSystem.sendPartyChat(player, message);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("info")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						int size = PartyApiSystem.getPartySize(player);
						int online = PartyApiSystem.getOnlinePartySize(player);
						int limit = PartyApiSystem.getPartyMaxMembers(player);
						ctx.getSource().sendSuccess(() -> Component.literal("Party: " + size + "/" + limit + " members, online: " + online + ", system: " + (PartyApiSystem.isPartySystemEnabled() ? "enabled" : "disabled")), false);
						return 1;
					})
				)
				.then(Commands.literal("admin")
					.requires(source -> source.hasPermission(PartyApiServerConfig.adminPermissionLevel()))
					.then(Commands.literal("enabled")
						.then(Commands.argument("enabled", BoolArgumentType.bool())
							.executes(ctx -> {
								boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
								boolean ok = PartyApiSystem.adminSetPartySystemEnabled(enabled);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Party system " + (enabled ? "enabled" : "disabled") : "Could not change party system state"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("reloadconfig")
						.executes(ctx -> {
							PartyApiServerConfig.reload();
							ctx.getSource().sendSuccess(() -> Component.literal("Party server config reloaded"), false);
							return 1;
						})
					)
					.then(Commands.literal("gui")
						.then(Commands.argument("player", EntityArgument.player())
							.executes(ctx -> {
								ServerPlayer admin = ctx.getSource().getPlayerOrException();
								ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
								PartyApiSystem.openPartyGuiForPartyOf(admin, target);
								return 1;
							})
						)
					)
					.then(Commands.literal("limit")
						.then(Commands.argument("player", EntityArgument.player())
							.then(Commands.argument("size", IntegerArgumentType.integer(1, 200))
								.executes(ctx -> {
									ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
									int size = IntegerArgumentType.getInteger(ctx, "size");
									boolean ok = PartyApiSystem.adminSetPartyMaxMembers(target, size);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Target party limit set to " + size : "Target is not in party"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
					.then(Commands.literal("pvp")
						.then(Commands.argument("player", EntityArgument.player())
							.then(Commands.argument("enabled", BoolArgumentType.bool())
								.executes(ctx -> {
									ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
									boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
									boolean ok = PartyApiSystem.adminSetPvp(target, enabled);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Target party PvP changed" : "Target is not in party"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
					.then(Commands.literal("add")
						.then(Commands.argument("party_member", EntityArgument.player())
							.then(Commands.argument("target", EntityArgument.player())
								.executes(ctx -> {
									ServerPlayer partyMember = EntityArgument.getPlayer(ctx, "party_member");
									ServerPlayer target = EntityArgument.getPlayer(ctx, "target");
									boolean ok = PartyApiSystem.adminAddPlayerToParty(partyMember, target, false);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Player added to target party" : "Could not add player"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
					.then(Commands.literal("forceadd")
						.then(Commands.argument("party_member", EntityArgument.player())
							.then(Commands.argument("target", EntityArgument.player())
								.executes(ctx -> {
									ServerPlayer partyMember = EntityArgument.getPlayer(ctx, "party_member");
									ServerPlayer target = EntityArgument.getPlayer(ctx, "target");
									boolean ok = PartyApiSystem.adminAddPlayerToParty(partyMember, target, true);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Player force-added to target party" : "Could not force-add player"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
					.then(Commands.literal("remove")
						.then(Commands.argument("target", EntityArgument.player())
							.executes(ctx -> {
								ServerPlayer target = EntityArgument.getPlayer(ctx, "target");
								boolean ok = PartyApiSystem.adminRemovePlayerFromParty(target);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Player removed from party" : "Target is not in party"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("disband")
						.then(Commands.argument("player", EntityArgument.player())
							.executes(ctx -> {
								ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
								boolean ok = PartyApiSystem.adminDisbandPartyOf(target);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Target party disbanded" : "Target is not in party"), false);
								return ok ? 1 : 0;
							})
						)
					)
				)
		);
	}
}
