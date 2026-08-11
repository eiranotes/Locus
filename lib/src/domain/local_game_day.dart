class LocalGameDay {
  const LocalGameDay({required this.boundaryHour});

  final int boundaryHour;

  DateTime startFor(DateTime value) {
    final local = value.toLocal();
    final calendarDay = DateTime(local.year, local.month, local.day);
    if (local.hour < boundaryHour) {
      return calendarDay.subtract(const Duration(days: 1)).add(
        Duration(hours: boundaryHour),
      );
    }
    return calendarDay.add(Duration(hours: boundaryHour));
  }

  String keyFor(DateTime value) {
    final start = startFor(value);
    final month = start.month.toString().padLeft(2, '0');
    final day = start.day.toString().padLeft(2, '0');
    return '${start.year}-$month-$day';
  }
}
