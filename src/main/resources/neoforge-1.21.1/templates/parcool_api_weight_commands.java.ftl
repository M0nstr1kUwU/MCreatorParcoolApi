package ${package}.weight;

import com.mojang.brigadier.arguments.BoolArgumentType;

import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.RegisterCommandsEvent;

@EventBusSubscriber(modid = "${modid}")
public final class ParCoolApiWeightCommands {
	private static final int ADMIN_PERMISSION_LEVEL = 2;

	private ParCoolApiWeightCommands() {
	}

	@SubscribeEvent
	public static void registerCommands(RegisterCommandsEvent event) {
		event.getDispatcher().register(
			Commands.literal("weight")
				.requires(source -> source.hasPermission(ADMIN_PERMISSION_LEVEL))
				.then(Commands.literal("admin")
					.then(Commands.literal("enabled")
						.then(Commands.argument("enabled", BoolArgumentType.bool())
							.executes(ctx -> setEnabled(ctx.getSource(), BoolArgumentType.getBool(ctx, "enabled")))
						)
					)
					.then(Commands.literal("reloadconfig")
						.executes(ctx -> {
							ParCoolApiWeightConfig.reload();
							ParCoolApiWeightSystem.onWeightConfigChanged();
							ctx.getSource().sendSuccess(() -> Component.literal("Weight config reloaded"), false);
							return 1;
						})
					)
					.then(Commands.literal("status")
						.executes(ctx -> showStatus(ctx.getSource(), ctx.getSource().getPlayerOrException()))
						.then(Commands.argument("player", EntityArgument.player())
							.executes(ctx -> showStatus(ctx.getSource(), EntityArgument.getPlayer(ctx, "player")))
						)
					)
				)
		);

		event.getDispatcher().register(
			Commands.literal("parcoolweight")
				.requires(source -> source.hasPermission(ADMIN_PERMISSION_LEVEL))
				.then(Commands.literal("enabled")
					.then(Commands.argument("enabled", BoolArgumentType.bool())
						.executes(ctx -> setEnabled(ctx.getSource(), BoolArgumentType.getBool(ctx, "enabled")))
					)
				)
				.then(Commands.literal("reloadconfig")
					.executes(ctx -> {
						ParCoolApiWeightConfig.reload();
						ParCoolApiWeightSystem.onWeightConfigChanged();
						ctx.getSource().sendSuccess(() -> Component.literal("Weight config reloaded"), false);
						return 1;
					})
				)
				.then(Commands.literal("status")
					.then(Commands.argument("player", EntityArgument.player())
						.executes(ctx -> showStatus(ctx.getSource(), EntityArgument.getPlayer(ctx, "player")))
					)
				)
		);
	}

	private static int setEnabled(CommandSourceStack source, boolean enabled) {
		boolean ok = ParCoolApiWeightSystem.setWeightSystemEnabled(enabled);

		source.sendSuccess(
			() -> Component.literal(ok
				? "Weight system " + (enabled ? "enabled" : "disabled")
				: "Could not change weight system state"),
			true
		);

		return ok ? 1 : 0;
	}

	private static int showStatus(CommandSourceStack source, ServerPlayer player) {
		boolean enabled = ParCoolApiWeightSystem.isWeightSystemEnabled();
		double current = ParCoolApiWeightSystem.getInventoryWeight(player);
		double max = ParCoolApiWeightSystem.getMaxCarryWeight(player);
		double percent = ParCoolApiWeightSystem.getLoadPercent(player);
		int status = ParCoolApiWeightSystem.getWeightStatus(player);

		source.sendSuccess(
			() -> Component.literal("Weight: enabled=" + enabled + ", player=" + player.getGameProfile().getName() + ", current=" + current + ", max=" + max + ", percent=" + percent + ", status=" + status),
			false
		);

		return 1;
	}
}