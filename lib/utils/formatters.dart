import 'package:intl/intl.dart';

final _ugxFormat = NumberFormat.decimalPattern('en_US');

/// Formats an integer amount as "12,000 UGX".
String formatUgx(int amount) => '${_ugxFormat.format(amount)} UGX';

String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
