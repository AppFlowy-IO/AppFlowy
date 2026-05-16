import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';

extension TimeFormatter on UserTimeFormatPB {
  DateFormat get toFormat => _toFormat[this]!;

  String formatTime(DateTime date) => toFormat.format(date);
}

final _toFormat = {
  UserTimeFormatPB.TwentyFourHour: DateFormat.Hm(),
  UserTimeFormatPB.TwelveHour: DateFormat.jm(),
};
