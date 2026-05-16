/// RegExp to match Twelve Hour formats
/// Source: https://stackoverflow.com/a/33906224
///
/// Matches eg: "05:05 PM", "5:50 Pm", "10:59 am", etc.
///
const _twelveHourTimePattern =
    r'\b((1[0-2]|0?[1-9]):([0-5][0-9]) ([AaPp][Mm]))';
final twelveHourTimeRegex = RegExp(_twelveHourTimePattern);
bool isTwelveHourTime(String? time) => twelveHourTimeRegex.hasMatch(time ?? '');

/// RegExp to match Twenty Four Hour formats
/// Source: https://stackoverflow.com/a/7536768
///
/// Matches eg: "0:01", "04:59", "16:30", etc.
///
const _twentyFourHourtimePattern = r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$';
final tewentyFourHourTimeRegex = RegExp(_twentyFourHourtimePattern);
bool isTwentyFourHourTime(String? time) =>
    tewentyFourHourTimeRegex.hasMatch(time ?? '');
