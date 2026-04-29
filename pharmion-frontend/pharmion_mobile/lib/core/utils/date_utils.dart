class AppDateUtils {
  static DateTime? parseUtc(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().replaceFirst(' ', 'T');
    final withZ = normalized.endsWith('Z') ? normalized : '${normalized}Z';
    return DateTime.tryParse(withZ)?.toLocal();
  }

  static String formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static String formatDateTime(DateTime? d) {
    if (d == null) return '—';
    return '${formatDate(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTimeStr(String? raw) => formatDateTime(parseUtc(raw));
  static String formatDateStr(String? raw) => formatDate(parseUtc(raw));

  static int daysUntil(DateTime? d) {
    if (d == null) return 0;
    return d.difference(DateTime.now()).inDays;
  }

  static bool isExpired(DateTime? d) {
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }

  static bool isExpiringSoon(DateTime? d, {int withinDays = 30}) {
    if (d == null) return false;
    final diff = daysUntil(d);
    return diff >= 0 && diff <= withinDays;
  }
}