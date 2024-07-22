import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

String formatTimeSeconds(
  int seconds, [
  TimePrecisionPB precision = TimePrecisionPB.Seconds,
]) {
  if (precision == TimePrecisionPB.Minutes) {
    seconds ~/= 60;
  }
  return formatTime(seconds, precision);
}

String formatTime(
  int time, [
  TimePrecisionPB precision = TimePrecisionPB.Seconds,
]) {
  if (time < 0) {
    return '';
  }
  if (precision == TimePrecisionPB.Minutes) {
    time *= 60;
  }
  final (hours, minutes, seconds) = splitTimeToHMS(time);

  return precision == TimePrecisionPB.Seconds
      ? formatTimeFromHMS(hours, minutes, seconds)
      : formatTimeFromHMS(hours, minutes);
}

(int, int, int) splitTimeToHMS(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds - hours * 3600) ~/ 60;
  final remainingSeconds = seconds - hours * 3600 - minutes * 60;

  return (hours, minutes, remainingSeconds);
}

String formatTimeFromHMS(int hours, int minutes, [int? seconds]) {
  final res = [];
  if (hours != 0) {
    res.add("${hours}h");
  }
  if (hours != 0 || minutes != 0 || seconds == null) {
    res.add("${minutes}m");
  }
  if (seconds != null) {
    res.add("${seconds}s");
  }

  return res.join(" ");
}

final RegExp _timeStrRegExp = RegExp(
  r'(?:(?<hours>\d*)h)? ?(?:(?<minutes>\d*)m)? ?(?:(?<seconds>\d*)s)?',
);

int? parseTimeToSeconds(String timeStr, TimePrecisionPB precision) {
  final int coeficient = precision == TimePrecisionPB.Seconds ? 1 : 60;

  int? res = int.tryParse(timeStr);
  if (res != null) {
    return res * coeficient;
  }

  final matches = _timeStrRegExp.firstMatch(timeStr);
  if (matches == null) {
    return null;
  }
  final hours = int.tryParse(matches.namedGroup('hours') ?? "");
  final minutes = int.tryParse(matches.namedGroup('minutes') ?? "");
  final seconds = int.tryParse(matches.namedGroup('seconds') ?? "");
  if (hours == null && minutes == null && seconds == null) {
    return null;
  }

  final expected = [];
  if (hours != null) {
    expected.add("${hours}h");
  }
  if (minutes != null) {
    expected.add("${minutes}m");
  }
  if (seconds != null) {
    expected.add("${seconds}s");
  }
  if (timeStr != expected.join(" ")) {
    return null;
  }

  res = 0;
  res += hours != null ? hours * 3600 : 0;
  res += minutes != null ? minutes * 60 : 0;
  res += seconds ?? 0;

  return res;
}
