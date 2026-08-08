import 'package:reality_diorama/src/domain/enums.dart';

TimeBand timeBandFor(DateTime date) {
  final hour = date.hour;
  if (hour < 6) {
    return TimeBand.dawn;
  }
  if (hour < 11) {
    return TimeBand.morning;
  }
  if (hour < 17) {
    return TimeBand.afternoon;
  }
  if (hour < 21) {
    return TimeBand.evening;
  }
  return TimeBand.night;
}

Season seasonFor(DateTime date, {bool northernHemisphere = true}) {
  final month = date.month;
  final northern = switch (month) {
    3 || 4 || 5 => Season.spring,
    6 || 7 || 8 => Season.summer,
    9 || 10 || 11 => Season.autumn,
    _ => Season.winter,
  };
  if (northernHemisphere) {
    return northern;
  }
  return switch (northern) {
    Season.spring => Season.autumn,
    Season.summer => Season.winter,
    Season.autumn => Season.spring,
    Season.winter => Season.summer,
  };
}

String dayKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
