import 'package:intl/intl.dart';

/// Date utility helpers for budget period calculations.
class AppDateUtils {
  AppDateUtils._();

  /// Total days in the current month.
  static int daysInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  /// Days remaining in the current month (including today).
  static int daysRemainingInMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day + 1;
  }

  /// Days elapsed in the current month.
  static int daysElapsedInMonth() {
    return DateTime.now().day;
  }

  /// Progress through the month (0.0 to 1.0).
  static double monthProgress() {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    return now.day / totalDays;
  }

  /// Start of the current month.
  static DateTime startOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// End of the current month.
  static DateTime endOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Start of the current week (Monday).
  static DateTime startOfCurrentWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Start of last week (Monday).
  static DateTime startOfLastWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1) - 7);
  }

  /// End of last week (Sunday).
  static DateTime endOfLastWeek() {
    final start = startOfCurrentWeek();
    return start.subtract(const Duration(seconds: 1));
  }

  /// Current month as integer (1-12).
  static int currentMonth() => DateTime.now().month;

  /// Current year.
  static int currentYear() => DateTime.now().year;

  /// Format date as "Jun 6".
  static String formatShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format date as "June 6, 2026".
  static String formatFull(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format date as "6 Jun".
  static String formatCompact(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  /// Format time as "2:30 PM".
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format as relative: "Today", "Yesterday", or "Jun 4".
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // "Wednesday"
    }
    return formatShort(date);
  }

  /// Get current month name (e.g., "June").
  static String currentMonthName() {
    return DateFormat('MMMM').format(DateTime.now());
  }

  /// Get month name from number (1 = January).
  static String monthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  /// Check if a date is in the current month.
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // ─── Custom Reset Cycle Calculations ──────────────────────────

  /// Get the start of the monthly cycle containing the given date.
  static DateTime startOfCycle(DateTime date, int cycleStartDay) {
    if (date.day >= cycleStartDay) {
      return DateTime(date.year, date.month, cycleStartDay);
    } else {
      return DateTime(date.year, date.month - 1, cycleStartDay);
    }
  }

  /// Get the end of the monthly cycle containing the given date.
  static DateTime endOfCycle(DateTime date, int cycleStartDay) {
    final start = startOfCycle(date, cycleStartDay);
    return DateTime(start.year, start.month + 1, cycleStartDay).subtract(const Duration(seconds: 1));
  }

  /// Total days in the cycle containing the given date.
  static int daysInCycle(DateTime date, int cycleStartDay) {
    final start = startOfCycle(date, cycleStartDay);
    final nextStart = DateTime(start.year, start.month + 1, cycleStartDay);
    return nextStart.difference(start).inDays;
  }

  /// Days remaining in the cycle containing the given date (including today).
  static int daysRemainingInCycle(DateTime date, int cycleStartDay) {
    final start = startOfCycle(date, cycleStartDay);
    final nextStart = DateTime(start.year, start.month + 1, cycleStartDay);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return nextStart.difference(dateOnly).inDays;
  }

  /// Days elapsed in the cycle containing the given date.
  static int daysElapsedInCycle(DateTime date, int cycleStartDay) {
    final start = startOfCycle(date, cycleStartDay);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.difference(start).inDays + 1;
  }

  /// Progress through the cycle (0.0 to 1.0).
  static double cycleProgress(DateTime date, int cycleStartDay) {
    final elapsed = daysElapsedInCycle(date, cycleStartDay);
    final total = daysInCycle(date, cycleStartDay);
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
