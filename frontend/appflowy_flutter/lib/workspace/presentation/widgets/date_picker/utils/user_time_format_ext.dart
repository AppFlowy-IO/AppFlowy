import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

extension ToTimeFormat on UserTimeFormatPB {
  TimeFormatPB get simplified => switch (this) {
        UserTimeFormatPB.TwelveHour => TimeFormatPB.TwelveHour,
        UserTimeFormatPB.TwentyFourHour => TimeFormatPB.TwentyFourHour,
        _ => TimeFormatPB.TwentyFourHour,
      };
}
