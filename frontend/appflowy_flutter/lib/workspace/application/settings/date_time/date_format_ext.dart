import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';

const _localFmt = 'M/d/y';
const _usFmt = 'y/M/d';
const _isoFmt = 'y-M-d';
const _friendlyFmt = 'MMM d, y';
const _dmyFmt = 'd/M/y';

extension DateFormatter on UserDateFormatPB {
  DateFormat get toFormat => DateFormat(_toFormat[this] ?? _friendlyFmt);

  String formatDate(
    DateTime date,
    bool includeTime, [
    UserTimeFormatPB? timeFormat,
  ]) {
    final format = toFormat;

    if (includeTime) {
      switch (timeFormat) {
        case UserTimeFormatPB.TwentyFourHour:
          return format.add_Hm().format(date);
        case UserTimeFormatPB.TwelveHour:
          return format.add_jm().format(date);
        default:
          return format.format(date);
      }
    }

    return format.format(date);
  }
}

final _toFormat = {
  UserDateFormatPB.Locally: _localFmt,
  UserDateFormatPB.US: _usFmt,
  UserDateFormatPB.ISO: _isoFmt,
  UserDateFormatPB.Friendly: _friendlyFmt,
  UserDateFormatPB.DayMonthYear: _dmyFmt,
};
