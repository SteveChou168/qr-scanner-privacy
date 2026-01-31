// lib/utils/date_format_helper.dart

import '../app_text.dart';

/// Helper for consistent date formatting
class DateFormatHelper {
  DateFormatHelper._();

  /// Format as full datetime: "2024/01/28 14:30"
  static String formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Format as date only: "2024/01/28"
  static String formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  /// Format as time only: "14:30"
  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Format as relative time: "2 hours ago", "3 days ago"
  static String formatRelative(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return AppText.timeJustNow;
    } else if (diff.inHours < 1) {
      return AppText.timeMinutesAgo(diff.inMinutes);
    } else if (diff.inDays < 1) {
      return AppText.timeHoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return AppText.timeDaysAgo(diff.inDays);
    } else {
      return '${time.month}/${time.day}';
    }
  }

  /// Format for display in lists (relative for recent, date for older)
  static String formatForList(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays < 7) {
      return formatRelative(time);
    } else if (time.year == now.year) {
      return '${time.month}/${time.day}';
    } else {
      return formatDate(time);
    }
  }
}
