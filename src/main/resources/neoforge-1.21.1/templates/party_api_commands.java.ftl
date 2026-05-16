package ${package}.party;

import com.mojang.brigadier.arguments.BoolArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;

import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.RegisterCommandsEvent;

@EventBusSubscriber(modid = "${modid}")
public final class PartyApiCommands {
	private PartyApiCommands() {
	}

	@SubscribeEvent
	public static void registerCommands(RegisterCommandsEvent event) {
		event.getDispatcher().register(
			Commands.literal("party")
				.then(Commands.literal("create")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.createParty(player);
						ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Party created" : "Could not create party"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("disband")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.disbandParty(player);
						ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Party disbanded" : "Only leader can disband party"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("invite")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.invitePlayer(actor, target);
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Invite sent" : "Could not invite player"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("accept")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.acceptInvite(player);
						ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Joined party" : "No invite found"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("leave")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						boolean ok = PartyApiSystem.leaveParty(player);
						ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Left party" : "You are not in party"), false);
						return ok ? 1 : 0;
					})
				)
				.then(Commands.literal("kick")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.kickPlayer(actor, target);
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Player kicked" : "Could not kick player"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("pvp")
					.then(Commands.argument("enabled", BoolArgumentType.bool())
						.executes(ctx -> {
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
							boolean ok = PartyApiSystem.setPvp(player, enabled);
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Party PvP changed" : "Only leader can change PvP"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("showself")
					.then(Commands.argument("enabled", BoolArgumentType.bool())
						.executes(ctx -> {
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
							boolean ok = PartyApiSystem.setShowSelf(player, enabled);
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? (enabled ? "You will see yourself in party UI" : "You will not see yourself in party UI") : "You are not in party"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("pin")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.setPinned(actor, target, true);
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Pinned" : "Could not pin"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("unpin")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> {
							ServerPlayer actor = ctx.getSource().getPlayerOrException();
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							boolean ok = PartyApiSystem.setPinned(actor, target, false);
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Unpinned" : "Could not unpin"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("position")
					.then(Commands.argument("position", StringArgumentType.word())
						.executes(ctx -> {
							ServerPlayer player = ctx.getSource().getPlayerOrException();
							boolean ok = PartyApiSystem.setOverlayPosition(player, StringArgumentType.getString(ctx, "position"));
							ctx.getSource().sendSuccess(() -> net.minecraft.network.chat.Component.literal(ok ? "Overlay position changed" : "Could not change position"), false);
							return ok ? 1 : 0;
						})
					)
				)
				.then(Commands.literal("gui")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						PartyApiSystem.openPartyGui(player);
						return 1;
					})
				)
		);
	}
}
