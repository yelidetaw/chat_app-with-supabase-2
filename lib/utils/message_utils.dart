import 'package:intl/intl.dart';

String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDateLocal = timestamp.toLocal();
  final messageDay = DateTime(
    messageDateLocal.year,
    messageDateLocal.month,
    messageDateLocal.day,
  );

  if (messageDay == today) {
    return DateFormat.jm().format(messageDateLocal);
  } else if (now.difference(messageDay).inDays < 7) {
    return DateFormat('E, h:mm a').format(messageDateLocal);
  } else {
    return DateFormat('MMM d, h:mm a').format(messageDateLocal);
  }
}

bool isImageFile(String? url) {
  if (url == null) return false;
  final extension = url.split('.').last.toLowerCase();
  return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(extension);
}

bool isAudioFile(String? url) {
  if (url == null) return false;
  final extension = url.split('.').last.toLowerCase();
  return ['mp3', 'wav', 'ogg', 'm4a'].contains(extension);
}

String getFormattedFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}