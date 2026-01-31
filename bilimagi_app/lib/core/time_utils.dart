/// Format a DateTime as a relative time string (Turkish)
String formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) {
    return 'Az önce';
  } else if (diff.inHours < 1) {
    return '${diff.inMinutes} dakika önce';
  } else if (diff.inDays < 1) {
    return '${diff.inHours} saat önce';
  } else if (diff.inDays < 7) {
    return '${diff.inDays} gün önce';
  } else {
    return '${time.day}/${time.month}/${time.year}';
  }
}
