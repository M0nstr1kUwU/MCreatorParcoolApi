package ${package}.economy;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

public final class EconomyApiCasino {
	private static final SecureRandom RANDOM = new SecureRandom();

	private EconomyApiCasino() {
	}

	public static int rollInt(int min, int max) {
		int low = Math.min(min, max);
		int high = Math.max(min, max);

		if (low == high) {
			return low;
		}

		return low + RANDOM.nextInt((high - low) + 1);
	}

	public static double rollDouble(double min, double max) {
		double low = Math.min(min, max);
		double high = Math.max(min, max);

		if (Double.isNaN(low) || Double.isNaN(high) || Double.isInfinite(low) || Double.isInfinite(high)) {
			return 0.0D;
		}

		if (low == high) {
			return low;
		}

		return low + (RANDOM.nextDouble() * (high - low));
	}

	public static boolean chance(double percent, boolean applyHouseEdge) {
		double effective = clamp(percent, 0.0D, 100.0D);

		if (applyHouseEdge) {
			effective *= Math.max(0.0D, 1.0D - EconomyApiServerConfig.get().casinoHouseEdgePercent / 100.0D);
		}

		return RANDOM.nextDouble() * 100.0D < effective;
	}

	public static boolean coinFlip() {
		return RANDOM.nextBoolean();
	}

	public static int diceSum(int dice, int sides) {
		int count = Math.max(1, Math.min(128, dice));
		int safeSides = Math.max(2, Math.min(10_000, sides));
		int sum = 0;

		for (int i = 0; i < count; i++) {
			sum += rollInt(1, safeSides);
		}

		return sum;
	}

	public static String diceCsv(int dice, int sides) {
		int count = Math.max(1, Math.min(128, dice));
		int safeSides = Math.max(2, Math.min(10_000, sides));
		StringBuilder builder = new StringBuilder();

		for (int i = 0; i < count; i++) {
			if (i > 0) {
				builder.append(",");
			}

			builder.append(rollInt(1, safeSides));
		}

		return builder.toString();
	}

	public static int rouletteNumber() {
		return rollInt(0, 36);
	}

	public static String rouletteColor(int number) {
		if (number <= 0) {
			return "GREEN";
		}

		return switch (number) {
			case 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 -> "RED";
			default -> "BLACK";
		};
	}

	public static boolean rouletteIsWin(String betType, String choice, int number) {
		String type = normalize(betType);
		String selected = normalize(choice);
		int value = Math.max(0, Math.min(36, number));

		return switch (type) {
			case "STRAIGHT" -> selected.equals(String.valueOf(value));
			case "COLOR" -> rouletteColor(value).equals(selected);
			case "EVEN_ODD" -> value > 0 && (("EVEN".equals(selected) && value % 2 == 0) || ("ODD".equals(selected) && value % 2 != 0));
			case "LOW_HIGH" -> value > 0 && (("LOW".equals(selected) && value <= 18) || ("HIGH".equals(selected) && value >= 19));
			case "DOZEN" -> value > 0 && (("FIRST".equals(selected) && value <= 12) || ("SECOND".equals(selected) && value >= 13 && value <= 24) || ("THIRD".equals(selected) && value >= 25));
			case "COLUMN" -> value > 0 && (("FIRST".equals(selected) && value % 3 == 1) || ("SECOND".equals(selected) && value % 3 == 2) || ("THIRD".equals(selected) && value % 3 == 0));
			default -> false;
		};
	}

	public static double roulettePayoutMultiplier(String betType) {
		return switch (normalize(betType)) {
			case "STRAIGHT" -> 36.0D;
			case "DOZEN", "COLUMN" -> 3.0D;
			case "COLOR", "EVEN_ODD", "LOW_HIGH" -> 2.0D;
			default -> 0.0D;
		};
	}

	public static String slotResult(int symbols) {
		int count = Math.max(2, Math.min(64, symbols));
		return rollInt(1, count) + "," + rollInt(1, count) + "," + rollInt(1, count);
	}

	public static boolean slotAllEqual(String result) {
		if (result == null || result.isBlank()) {
			return false;
		}

		String[] parts = result.split(",");

		if (parts.length < 3) {
			return false;
		}

		return parts[0].trim().equals(parts[1].trim()) && parts[1].trim().equals(parts[2].trim());
	}

	public static boolean slotHasPair(String result) {
		if (result == null || result.isBlank()) {
			return false;
		}

		String[] parts = result.split(",");

		if (parts.length < 3) {
			return false;
		}

		String a = parts[0].trim();
		String b = parts[1].trim();
		String c = parts[2].trim();

		return a.equals(b) || a.equals(c) || b.equals(c);
	}

	public static double slotPayoutMultiplier(String result, double jackpotMultiplier, double pairMultiplier, double missMultiplier) {
		if (slotAllEqual(result)) {
			return Math.max(0.0D, jackpotMultiplier);
		}

		if (slotHasPair(result)) {
			return Math.max(0.0D, pairMultiplier);
		}

		return Math.max(0.0D, missMultiplier);
	}

	public static int cardRank() {
		return rollInt(1, 13);
	}

	public static String cardSuit() {
		return switch (rollInt(0, 3)) {
			case 0 -> "SPADES";
			case 1 -> "HEARTS";
			case 2 -> "DIAMONDS";
			default -> "CLUBS";
		};
	}

	public static String cardName(int rank, String suit) {
		int safeRank = Math.max(1, Math.min(13, rank));
		String rankName = switch (safeRank) {
			case 1 -> "ACE";
			case 11 -> "JACK";
			case 12 -> "QUEEN";
			case 13 -> "KING";
			default -> String.valueOf(safeRank);
		};

		String safeSuit = switch (normalize(suit)) {
			case "SPADES", "HEARTS", "DIAMONDS", "CLUBS" -> normalize(suit);
			default -> "SPADES";
		};

		return rankName + "_OF_" + safeSuit;
	}

	public static int blackjackCardValue(int rank) {
		int safeRank = Math.max(1, Math.min(13, rank));

		if (safeRank == 1) {
			return 11;
		}

		if (safeRank >= 10) {
			return 10;
		}

		return safeRank;
	}

	public static int blackjackHandValue(String ranksCsv) {
		if (ranksCsv == null || ranksCsv.isBlank()) {
			return 0;
		}

		String[] parts = ranksCsv.split(",");
		int total = 0;
		int aces = 0;

		for (String part : parts) {
			try {
				int rank = Integer.parseInt(part.trim());
				int safeRank = Math.max(1, Math.min(13, rank));

				if (safeRank == 1) {
					aces++;
				}

				total += blackjackCardValue(safeRank);
			} catch (Throwable ignored) {
			}
		}

		while (total > 21 && aces > 0) {
			total -= 10;
			aces--;
		}

		return total;
	}

	public static boolean blackjackIsBust(String ranksCsv) {
		return blackjackHandValue(ranksCsv) > 21;
	}

	public static boolean blackjackDealerShouldHit(String ranksCsv) {
		return blackjackHandValue(ranksCsv) <= 16;
	}

	public static int weightedIndex(String weightsCsv) {
		if (weightsCsv == null || weightsCsv.isBlank()) {
			return -1;
		}

		String[] parts = weightsCsv.split(",");
		List<Double> weights = new ArrayList<>();
		double total = 0.0D;

		for (String part : parts) {
			try {
				double weight = Math.max(0.0D, Double.parseDouble(part.trim()));
				weights.add(weight);
				total += weight;
			} catch (Throwable ignored) {
				weights.add(0.0D);
			}
		}

		if (total <= 0.0D) {
			return -1;
		}

		double roll = RANDOM.nextDouble() * total;
		double current = 0.0D;

		for (int i = 0; i < weights.size(); i++) {
			current += weights.get(i);

			if (roll <= current) {
				return i;
			}
		}

		return weights.size() - 1;
	}

	public static double csvDoubleAt(String valuesCsv, int index, double fallback) {
		if (valuesCsv == null || valuesCsv.isBlank() || index < 0) {
			return fallback;
		}

		String[] parts = valuesCsv.split(",");

		if (index >= parts.length) {
			return fallback;
		}

		try {
			return Double.parseDouble(parts[index].trim());
		} catch (Throwable ignored) {
			return fallback;
		}
	}

	public static String csvStringAt(String valuesCsv, int index, String fallback) {
		if (valuesCsv == null || valuesCsv.isBlank() || index < 0) {
			return fallback;
		}

		String[] parts = valuesCsv.split(",");

		if (index >= parts.length) {
			return fallback;
		}

		return parts[index].trim();
	}

	public static double weightedMultiplier(String weightsCsv, String multipliersCsv, double fallback) {
		int index = weightedIndex(weightsCsv);
		return csvDoubleAt(multipliersCsv, index, fallback);
	}

	public static double crashMultiplier(double maxMultiplier) {
		double max = Math.max(1.01D, Math.min(1_000_000.0D, maxMultiplier));
		double edgeFactor = Math.max(0.0D, 1.0D - EconomyApiServerConfig.get().casinoHouseEdgePercent / 100.0D);

		double random = Math.max(0.000001D, RANDOM.nextDouble());
		double result = edgeFactor / random;

		return clamp(result, 1.0D, max);
	}

	public static boolean crashCashoutWins(double generatedMultiplier, double cashoutMultiplier) {
		if (Double.isNaN(generatedMultiplier) || Double.isNaN(cashoutMultiplier)) {
			return false;
		}

		return generatedMultiplier >= Math.max(1.0D, cashoutMultiplier);
	}

	public static long payoutByMultiplier(long betCooper, double multiplier, boolean applyHouseEdge) {
		return EconomyApiSystem.calculateCasinoPayout(betCooper, multiplier, applyHouseEdge);
	}

	private static String normalize(String value) {
		if (value == null) {
			return "";
		}

		return value.trim().toUpperCase(java.util.Locale.ROOT);
	}

	private static double clamp(double value, double min, double max) {
		return Math.max(min, Math.min(max, value));
	}
}
