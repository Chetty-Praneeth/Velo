/// Math utility helpers for budget computations.
class MathUtils {
  MathUtils._();

  /// Calculate spendable budget = allowance - savings goal.
  static double spendableBudget(double allowance, double savingsGoal) {
    return allowance - savingsGoal;
  }

  /// Safe daily spend = remaining balance / remaining days.
  static double safeDailySpend(double remainingBalance, int remainingDays) {
    if (remainingDays <= 0) return 0;
    return remainingBalance / remainingDays;
  }

  /// Remaining balance = spendable budget - total spent.
  static double remainingBalance(double spendableBudget, double totalSpent) {
    return spendableBudget - totalSpent;
  }

  /// Budget spend percentage (0.0 to 1.0+).
  static double spendPercentage(double totalSpent, double spendableBudget) {
    if (spendableBudget <= 0) return 1.0;
    return totalSpent / spendableBudget;
  }

  /// Predicted month-end balance based on current spending rate.
  /// `avgDailySpend` = total spent / days elapsed.
  /// `predicted` = remaining - (avgDailySpend * daysLeft).
  static double predictedMonthEndBalance({
    required double remainingBalance,
    required double avgDailySpend,
    required int daysRemaining,
  }) {
    return remainingBalance - (avgDailySpend * daysRemaining);
  }

  /// Average daily spending = total spent / days elapsed.
  static double averageDailySpend(double totalSpent, int daysElapsed) {
    if (daysElapsed <= 0) return 0;
    return totalSpent / daysElapsed;
  }

  /// Percentage change between two values.
  /// Returns 0.0 if previous is 0.
  static double percentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  /// Whether savings goal is achievable at current spend rate.
  static bool isSavingsOnTrack({
    required double remainingBalance,
    required double avgDailySpend,
    required int daysRemaining,
  }) {
    final predicted = predictedMonthEndBalance(
      remainingBalance: remainingBalance,
      avgDailySpend: avgDailySpend,
      daysRemaining: daysRemaining,
    );
    return predicted >= 0;
  }

  /// How much the user needs to reduce daily spending to stay on track.
  /// Returns 0 if already on track.
  static double dailyReductionNeeded({
    required double remainingBalance,
    required double safeDailySpend,
    required double avgDailySpend,
  }) {
    final excess = avgDailySpend - safeDailySpend;
    return excess > 0 ? excess : 0;
  }

  /// Category percentage of total spending.
  static double categoryPercentage(double categoryTotal, double totalSpent) {
    if (totalSpent <= 0) return 0;
    return (categoryTotal / totalSpent) * 100;
  }

  /// Clamp a value between min and max.
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
