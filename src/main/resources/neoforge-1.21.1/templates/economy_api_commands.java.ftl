package ${package}.economy;

import com.mojang.brigadier.arguments.BoolArgumentType;
import com.mojang.brigadier.arguments.DoubleArgumentType;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.arguments.LongArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;

import net.minecraft.commands.Commands;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.RegisterCommandsEvent;

@EventBusSubscriber(modid = "${modid}")
public final class EconomyApiCommands {
	private static final int ADMIN_PERMISSION_LEVEL = 2;

	private EconomyApiCommands() {
	}

	@SubscribeEvent
	public static void registerCommands(RegisterCommandsEvent event) {
		event.getDispatcher().register(
			Commands.literal("eco")
				.then(Commands.literal("wallet")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						ctx.getSource().sendSuccess(() -> Component.literal("Wallet: " + EconomyApiSystem.formatMoney(EconomyApiSystem.getWallet(player))), false);
						return 1;
					})
				)
				.then(Commands.literal("bank")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						ctx.getSource().sendSuccess(() -> Component.literal("Bank: " + EconomyApiSystem.formatMoney(EconomyApiSystem.getBank(player))), false);
						return 1;
					})
					.then(Commands.literal("deposit")
						.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
							.then(Commands.argument("unit", StringArgumentType.word())
								.executes(ctx -> {
									ServerPlayer player = ctx.getSource().getPlayerOrException();
									long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
									boolean ok = EconomyApiSystem.moveWalletToBank(player, value);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Moved to bank: " + EconomyApiSystem.formatMoney(value) : "Not enough wallet money"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
					.then(Commands.literal("withdraw")
						.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
							.then(Commands.argument("unit", StringArgumentType.word())
								.executes(ctx -> {
									ServerPlayer player = ctx.getSource().getPlayerOrException();
									long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
									boolean ok = EconomyApiSystem.moveBankToWallet(player, value);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Moved to wallet: " + EconomyApiSystem.formatMoney(value) : "Not enough bank money"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
				)
				.then(Commands.literal("balance")
					.executes(ctx -> {
						ServerPlayer player = ctx.getSource().getPlayerOrException();
						long wallet = EconomyApiSystem.getWallet(player);
						long bank = EconomyApiSystem.getBank(player);
						ctx.getSource().sendSuccess(() -> Component.literal("Wallet: " + EconomyApiSystem.formatMoney(wallet) + " | Bank: " + EconomyApiSystem.formatMoney(bank)), false);
						return 1;
					})
					.then(Commands.argument("player", EntityArgument.player())
						.requires(source -> source.hasPermission(ADMIN_PERMISSION_LEVEL))
						.executes(ctx -> {
							ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
							long wallet = EconomyApiSystem.getWallet(target);
							long bank = EconomyApiSystem.getBank(target);
							ctx.getSource().sendSuccess(() -> Component.literal(target.getGameProfile().getName() + " | Wallet: " + EconomyApiSystem.formatMoney(wallet) + " | Bank: " + EconomyApiSystem.formatMoney(bank)), false);
							return 1;
						})
					)
				)
				.then(Commands.literal("pay")
					.then(Commands.argument("player", EntityArgument.player())
						.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
							.then(Commands.argument("unit", StringArgumentType.word())
								.executes(ctx -> {
									ServerPlayer from = ctx.getSource().getPlayerOrException();
									ServerPlayer to = EntityArgument.getPlayer(ctx, "player");
									long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
									boolean ok = EconomyApiSystem.transferWallet(from, to, value);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Payment sent" : "Payment failed"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
				)
				.then(Commands.literal("coins")
					.then(Commands.literal("deposit")
						.then(Commands.argument("coin", StringArgumentType.word())
							.executes(ctx -> {
								ServerPlayer player = ctx.getSource().getPlayerOrException();
								int deposited = EconomyApiSystem.depositCoinItemsToBank(player, StringArgumentType.getString(ctx, "coin"), 0);
								ctx.getSource().sendSuccess(() -> Component.literal("Deposited coin items: " + deposited), false);
								return deposited;
							})
							.then(Commands.argument("items", IntegerArgumentType.integer(1))
								.executes(ctx -> {
									ServerPlayer player = ctx.getSource().getPlayerOrException();
									int deposited = EconomyApiSystem.depositCoinItemsToBank(player, StringArgumentType.getString(ctx, "coin"), IntegerArgumentType.getInteger(ctx, "items"));
									ctx.getSource().sendSuccess(() -> Component.literal("Deposited coin items: " + deposited), false);
									return deposited;
								})
							)
						)
					)
					.then(Commands.literal("withdraw")
						.then(Commands.argument("coin", StringArgumentType.word())
							.then(Commands.argument("items", IntegerArgumentType.integer(1))
								.executes(ctx -> {
									ServerPlayer player = ctx.getSource().getPlayerOrException();
									int withdrawn = EconomyApiSystem.withdrawCoinItemsFromBank(player, StringArgumentType.getString(ctx, "coin"), IntegerArgumentType.getInteger(ctx, "items"));
									ctx.getSource().sendSuccess(() -> Component.literal("Withdrawn coin items: " + withdrawn), false);
									return withdrawn;
								})
							)
						)
					)
				)
				.then(Commands.literal("admin")
					.requires(source -> source.hasPermission(ADMIN_PERMISSION_LEVEL))
					.then(Commands.literal("reloadconfig")
						.executes(ctx -> {
							EconomyApiServerConfig.reload();
							ctx.getSource().sendSuccess(() -> Component.literal("Economy config reloaded"), false);
							return 1;
						})
					)
					.then(Commands.literal("enabled")
						.then(Commands.argument("enabled", BoolArgumentType.bool())
							.executes(ctx -> {
								boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
								boolean ok = EconomyApiSystem.setEconomyEnabled(enabled);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Economy " + (enabled ? "enabled" : "disabled") : "Could not change economy state"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("casino")
						.then(Commands.argument("enabled", BoolArgumentType.bool())
							.executes(ctx -> {
								boolean enabled = BoolArgumentType.getBool(ctx, "enabled");
								boolean ok = EconomyApiSystem.setCasinoEnabled(enabled);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Casino " + (enabled ? "enabled" : "disabled") : "Could not change casino state"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("setwallet")
						.then(Commands.argument("player", EntityArgument.player())
							.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
								.then(Commands.argument("unit", StringArgumentType.word())
									.executes(ctx -> {
										ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
										long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
										boolean ok = EconomyApiSystem.setWallet(target, value);
										ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Wallet set to " + EconomyApiSystem.formatMoney(value) : "Failed"), false);
										return ok ? 1 : 0;
									})
								)
							)
						)
					)
					.then(Commands.literal("setbank")
						.then(Commands.argument("player", EntityArgument.player())
							.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
								.then(Commands.argument("unit", StringArgumentType.word())
									.executes(ctx -> {
										ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
										long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
										boolean ok = EconomyApiSystem.setBank(target, value);
										ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Bank set to " + EconomyApiSystem.formatMoney(value) : "Failed"), false);
										return ok ? 1 : 0;
									})
								)
							)
						)
					)
					.then(Commands.literal("addwallet")
						.then(Commands.argument("player", EntityArgument.player())
							.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
								.then(Commands.argument("unit", StringArgumentType.word())
									.executes(ctx -> {
										ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
										long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
										boolean ok = EconomyApiSystem.addWallet(target, value);
										ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Added to wallet: " + EconomyApiSystem.formatMoney(value) : "Failed"), false);
										return ok ? 1 : 0;
									})
								)
							)
						)
					)
					.then(Commands.literal("addbank")
						.then(Commands.argument("player", EntityArgument.player())
							.then(Commands.argument("amount", DoubleArgumentType.doubleArg(0.0D))
								.then(Commands.argument("unit", StringArgumentType.word())
									.executes(ctx -> {
										ServerPlayer target = EntityArgument.getPlayer(ctx, "player");
										long value = EconomyApiSystem.toCopper(DoubleArgumentType.getDouble(ctx, "amount"), StringArgumentType.getString(ctx, "unit"));
										boolean ok = EconomyApiSystem.addBank(target, value);
										ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Added to bank: " + EconomyApiSystem.formatMoney(value) : "Failed"), false);
										return ok ? 1 : 0;
									})
								)
							)
						)
					)
					.then(Commands.literal("fee")
						.then(Commands.argument("percent", DoubleArgumentType.doubleArg(0.0D, 100.0D))
							.executes(ctx -> {
								double percent = DoubleArgumentType.getDouble(ctx, "percent");
								boolean ok = EconomyApiSystem.setTransferFeePercent(percent);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Transfer fee set to " + percent + "%" : "Failed"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("deathloss")
						.then(Commands.argument("percent", DoubleArgumentType.doubleArg(0.0D, 100.0D))
							.executes(ctx -> {
								double percent = DoubleArgumentType.getDouble(ctx, "percent");
								boolean ok = EconomyApiSystem.setDeathWalletLossPercent(percent);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Death wallet loss set to " + percent + "%" : "Failed"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("houseedge")
						.then(Commands.argument("percent", DoubleArgumentType.doubleArg(0.0D, 99.0D))
							.executes(ctx -> {
								double percent = DoubleArgumentType.getDouble(ctx, "percent");
								boolean ok = EconomyApiSystem.setCasinoHouseEdgePercent(percent);
								ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Casino house edge set to " + percent + "%" : "Failed"), false);
								return ok ? 1 : 0;
							})
						)
					)
					.then(Commands.literal("betlimits")
						.then(Commands.argument("minCooper", LongArgumentType.longArg(0L))
							.then(Commands.argument("maxCooper", LongArgumentType.longArg(0L))
								.executes(ctx -> {
									long min = LongArgumentType.getLong(ctx, "minCooper");
									long max = LongArgumentType.getLong(ctx, "maxCooper");
									boolean ok = EconomyApiSystem.setCasinoBetLimits(min, max);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Casino bet limits changed" : "Failed"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
					.then(Commands.literal("coinitem")
						.then(Commands.argument("coin", StringArgumentType.word())
							.then(Commands.argument("item_id", StringArgumentType.word())
								.executes(ctx -> {
									String coin = StringArgumentType.getString(ctx, "coin");
									String itemId = StringArgumentType.getString(ctx, "item_id");
									boolean ok = EconomyApiSystem.setCoinItem(coin, itemId);
									ctx.getSource().sendSuccess(() -> Component.literal(ok ? "Coin item changed" : "Failed"), false);
									return ok ? 1 : 0;
								})
							)
						)
					)
				)
		);
	}
}
