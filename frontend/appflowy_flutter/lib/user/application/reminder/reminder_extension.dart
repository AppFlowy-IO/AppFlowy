import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

enum ReminderMetaKeys {
  includeTime("include_time"),
  blockId("block_id");

  const ReminderMetaKeys(this.name);

  final String name;
}

extension ReminderExtension on ReminderPB {
  bool? get includeTime {
    final String? includeTimeStr = meta[ReminderMetaKeys.includeTime.name];

    return includeTimeStr != null ? includeTimeStr == true.toString() : null;
  }
}
