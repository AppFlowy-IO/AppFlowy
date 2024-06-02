final RegExp timerRegExp =
    RegExp(r'(?:(?<hours>\d*)h)? ?(?:(?<minutes>\d*)m)?');

int? parseTime(String timerStr) {
  int? res = int.tryParse(timerStr);
  if (res != null) {
    return res;
  }

  final matches = timerRegExp.firstMatch(timerStr);
  if (matches == null) {
    return null;
  }
  final hours = int.tryParse(matches.namedGroup('hours') ?? "");
  final minutes = int.tryParse(matches.namedGroup('minutes') ?? "");
  if (hours == null && minutes == null) {
    return null;
  }

  final expected =
      "${hours != null ? '${hours}h' : ''}${hours != null && minutes != null ? ' ' : ''}${minutes != null ? '${minutes}m' : ''}";
  if (timerStr != expected) {
    return null;
  }

  res = 0;
  res += hours != null ? hours * 60 : res;
  res += minutes ?? 0;

  return res;
}

String formatTime(int minutes) {
  if (minutes >= 60) {
    if (minutes % 60 == 0) {
      return "${minutes ~/ 60}h";
    }
    return "${minutes ~/ 60}h ${minutes % 60}m";
  } else if (minutes >= 0) {
    return "${minutes}m";
  }
  return "";
}
