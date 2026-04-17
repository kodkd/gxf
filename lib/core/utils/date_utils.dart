class AppDateUtils {
  // 25/03/2025
  static String format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  // 25/03
  static String formatShort(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';

  // "Il y a 2 heures" / "Hier" / "25/03/2025"
  static String formatRelative(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays    == 1) return 'Hier';
    if (diff.inDays    <  7) return 'Il y a ${diff.inDays} jours';
    return format(date);
  }

  // Vérifie si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Vérifie si une date est dépassée
  static bool isPast(DateTime date) =>
      date.isBefore(DateTime.now());
}