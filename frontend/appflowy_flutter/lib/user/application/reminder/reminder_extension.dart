import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

class ReminderMetaKeys {
  static String includeTime = "include_time";
  static String blockId = "block_id";
  static String rowId = "row_id";
  static String createdAt = "created_at";
  static String isArchived = "is_archived";
}

extension ReminderExtension on ReminderPB {
  bool? get includeTime {
    final String? includeTimeStr = meta[ReminderMetaKeys.includeTime];

    return includeTimeStr != null ? includeTimeStr == true.toString() : null;
  }

  String? get blockId => meta[ReminderMetaKeys.blockId];

  String? get rowId => meta[ReminderMetaKeys.rowId];

  int? get createdAt {
    final t = meta[ReminderMetaKeys.createdAt];
    return t != null ? int.tryParse(t) : null;
  }

  bool get isArchived {
    final t = meta[ReminderMetaKeys.isArchived];
    return t != null ? t == true.toString() : false;
  }
}
