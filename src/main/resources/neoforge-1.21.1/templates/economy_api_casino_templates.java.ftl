package ${package}.economy;

import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;

public final class EconomyApiCasinoTemplates {
	private EconomyApiCasinoTemplates() {
	}

	public static boolean playCoinFlip(ServerPlayer player, double amount, String coin, String choice, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		boolean heads = EconomyApiCasino.coinFlip();
		String result = heads ? "HEADS" : "TAILS";
		String selected = normalize(choice);
		boolean win = result.equals(selected);

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, 2.0D);
			message(player, sendMessages, "Coin Flip: " + result + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Coin Flip: " + result + ". You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playRouletteColor(ServerPlayer player, double amount, String coin, String colorChoice, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		int number = EconomyApiCasino.rouletteNumber();
		String color = EconomyApiCasino.rouletteColor(number);
		boolean win = EconomyApiCasino.rouletteIsWin("COLOR", colorChoice, number);

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, EconomyApiCasino.roulettePayoutMultiplier("COLOR"));
			message(player, sendMessages, "Roulette: " + number + " " + color + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Roulette: " + number + " " + color + ". You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playRouletteStraight(ServerPlayer player, double amount, String coin, int selectedNumber, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		int safeSelected = Math.max(0, Math.min(36, selectedNumber));
		int number = EconomyApiCasino.rouletteNumber();
		String color = EconomyApiCasino.rouletteColor(number);
		boolean win = EconomyApiCasino.rouletteIsWin("STRAIGHT", String.valueOf(safeSelected), number);

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, EconomyApiCasino.roulettePayoutMultiplier("STRAIGHT"));
			message(player, sendMessages, "Roulette: " + number + " " + color + ". Straight win! " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Roulette: " + number + " " + color + ". You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playSlots(ServerPlayer player, double amount, String coin, int symbols, double jackpotMultiplier, double pairMultiplier, double missMultiplier, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		String result = EconomyApiCasino.slotResult(symbols);
		double multiplier = EconomyApiCasino.slotPayoutMultiplier(result, jackpotMultiplier, pairMultiplier, missMultiplier);
		boolean win = multiplier > 0.0D;

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, multiplier);
			message(player, sendMessages, "Slots [" + result + "]: x" + round2(multiplier) + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Slots [" + result + "]: you lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playDiceOverUnder(ServerPlayer player, double amount, String coin, String choice, int dice, int sides, int threshold, double winMultiplier, boolean pushOnEqual, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		int sum = EconomyApiCasino.diceSum(dice, sides);
		String selected = normalize(choice);

		if (pushOnEqual && sum == threshold) {
			EconomyApiSystem.addWallet(player, bet);
			message(player, sendMessages, "Dice: " + sum + ". Push: bet returned.");
			return false;
		}

		boolean win = ("OVER".equals(selected) && sum > threshold) || ("UNDER".equals(selected) && sum < threshold);

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, Math.max(0.0D, winMultiplier));
			message(player, sendMessages, "Dice: " + sum + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Dice: " + sum + ". You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playWeightedWheel(ServerPlayer player, double amount, String coin, String weightsCsv, String multipliersCsv, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		double multiplier = EconomyApiCasino.weightedMultiplier(weightsCsv, multipliersCsv, 0.0D);
		boolean win = multiplier > 0.0D;

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, multiplier);
			message(player, sendMessages, "Wheel: x" + round2(multiplier) + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Wheel: x0. You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playCrash(ServerPlayer player, double amount, String coin, double cashoutMultiplier, double maxMultiplier, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		double generated = EconomyApiCasino.crashMultiplier(maxMultiplier);
		double safeCashout = Math.max(1.0D, cashoutMultiplier);
		boolean win = EconomyApiCasino.crashCashoutWins(generated, safeCashout);

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, safeCashout);
			message(player, sendMessages, "Crash reached x" + round2(generated) + ". Cashout x" + round2(safeCashout) + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Crash stopped at x" + round2(generated) + ". You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	public static boolean playBlackjackLite(ServerPlayer player, double amount, String coin, boolean sendMessages) {
		if (player == null || !EconomyApiSystem.isEconomyEnabled() || !EconomyApiSystem.isCasinoEnabled()) {
			return false;
		}

		long bet = EconomyApiSystem.toCopper(amount, coin);

		if (!EconomyApiSystem.isCasinoBetAllowed(bet)) {
			message(player, sendMessages, "Bet is not allowed: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		if (!EconomyApiSystem.takeCasinoBet(player, bet)) {
			message(player, sendMessages, "Not enough wallet money for bet: " + EconomyApiSystem.formatMoney(bet));
			return false;
		}

		String playerRanks = EconomyApiCasino.cardRank() + "," + EconomyApiCasino.cardRank();
		String dealerRanks = EconomyApiCasino.cardRank() + "," + EconomyApiCasino.cardRank();

		while (EconomyApiCasino.blackjackHandValue(playerRanks) < 16) {
			playerRanks += "," + EconomyApiCasino.cardRank();
		}

		while (EconomyApiCasino.blackjackDealerShouldHit(dealerRanks)) {
			dealerRanks += "," + EconomyApiCasino.cardRank();
		}

		int playerValue = EconomyApiCasino.blackjackHandValue(playerRanks);
		int dealerValue = EconomyApiCasino.blackjackHandValue(dealerRanks);

		boolean playerBust = playerValue > 21;
		boolean dealerBust = dealerValue > 21;
		boolean push = !playerBust && !dealerBust && playerValue == dealerValue;
		boolean win = !playerBust && (dealerBust || playerValue > dealerValue);

		if (push) {
			EconomyApiSystem.addWallet(player, bet);
			message(player, sendMessages, "Blackjack Lite: push. You " + playerValue + ", dealer " + dealerValue + ". Bet returned.");
			return false;
		}

		if (win) {
			long payout = EconomyApiSystem.giveCasinoPayout(player, bet, 2.0D);
			message(player, sendMessages, "Blackjack Lite: you " + playerValue + ", dealer " + dealerValue + ". You won " + EconomyApiSystem.formatMoney(payout));
		} else {
			message(player, sendMessages, "Blackjack Lite: you " + playerValue + ", dealer " + dealerValue + ". You lost " + EconomyApiSystem.formatMoney(bet));
		}

		return win;
	}

	private static void message(ServerPlayer player, boolean sendMessages, String text) {
		if (sendMessages && player != null) {
			player.displayClientMessage(Component.literal(text), false);
		}
	}

	private static String normalize(String value) {
		return value == null ? "" : value.trim().toUpperCase(java.util.Locale.ROOT);
	}

	private static double round2(double value) {
		return Math.round(value * 100.0D) / 100.0D;
	}
}
