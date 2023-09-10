import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';

const _localFmt = 'M/d/y';
const _usFmt = 'y/M/d';
const _isoFmt = 'ymd';
const _friendlyFmt = 'MMM d, y';
const _dmyFmt = 'd/M/y';

extension DateFormatter on DateFormatPB {
  DateFormat get toFormat => DateFormat(_toFormat[this] ?? _friendlyFmt);

  String formatDate(
    DateTime date,
    bool includeTime, [
    TimeFormatPB? timeFormat,
  ]) {
    final format = toFormat;

    if (includeTime) {
      switch (timeFormat) {
        case TimeFormatPB.TwentyFourHour:
          return format.add_Hm().format(date);
        case TimeFormatPB.TwelveHour:
          return format.add_jm().format(date);
        default:
          return format.format(date);
      }
    }

    return format.format(date);
  }
}

final _toFormat = {
  DateFormatPB.Locally: _localFmt,
  DateFormatPB.US: _usFmt,
  DateFormatPB.ISO: _isoFmt,
  DateFormatPB.Friendly: _friendlyFmt,
  DateFormatPB.DayMonthYear: _dmyFmt,
};
