String getRelativeTime(String dateString) {
  if (dateString.isEmpty) return dateString;
  DateTime date = DateTime.parse(dateString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(date);

  if (difference.inDays > 365) {
    return '${(difference.inDays / 365).floor()}年前';
  } else if (difference.inDays > 30) {
    return '${(difference.inDays / 30).floor()}个月前';
  } else if (difference.inDays > 7) {
    return '${(difference.inDays / 7).floor()}周前';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}天前';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}小时前';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}分钟前';
  } else {
    return '刚刚';
  }
}
