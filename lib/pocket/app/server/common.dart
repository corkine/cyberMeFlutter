String expiredAt(int timeSeconds) {
  final _expired = DateTime.fromMillisecondsSinceEpoch(timeSeconds * 1000);
  return '${_expired.year}-${_expired.month.toString().padLeft(2, '0')}-${_expired.day.toString().padLeft(2, '0')}';
}

String expiredFormat(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime expiredTo(int timeSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(timeSeconds * 1000);

int expiredFrom(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;
