/// RegExp to match Twelve Hour formats
/// Source: https://stackoverflow.com/a/33906224
///
/// Matches eg: "05:05 PM", "5:50 Pm", "10:59 am", etc.
///
final _twelveHourTimePattern =
    RegExp(r'\b((1[0-2]|0?[1-9]):([0-5][0-9]) ([AaPp][Mm]))');
bool isTwelveHourTime(String? time) =>
    _twelveHourTimePattern.hasMatch(time ?? '');

/// RegExp to match Twenty Four Hour formats
/// Source: https://stackoverflow.com/a/7536768
///
/// Matches eg: "0:01", "04:59", "16:30", etc.
///
final _twentyFourHourtimePattern = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
bool isTwentyFourHourTime(String? time) =>
    _twentyFourHourtimePattern.hasMatch(time ?? '');
