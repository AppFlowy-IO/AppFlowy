import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

extension ToDateFormat on UserDateFormatPB {
  DateFormatPB get simplified => switch (this) {
        UserDateFormatPB.DayMonthYear => DateFormatPB.DayMonthYear,
        UserDateFormatPB.Friendly => DateFormatPB.Friendly,
        UserDateFormatPB.ISO => DateFormatPB.ISO,
        UserDateFormatPB.Locally => DateFormatPB.Local,
        UserDateFormatPB.US => DateFormatPB.US,
        _ => DateFormatPB.Friendly,
      };
}
