enum MentionType {
  page,
  date,
  externalLink,
  childPage;

  static MentionType fromString(String value) => switch (value) {
    'page' => page,
    'date' => date,
    'externalLink' => externalLink,
    'childPage' => childPage,
    // Backwards compatibility
    'reminder' => date,
    _ => throw UnimplementedError(),
  };
}

class MentionBlockKeys {
  const MentionBlockKeys._();

  static const mention = 'mention';
  static const type = 'type'; // MentionType, String

  static const pageId = 'page_id';
  static const blockId = 'block_id';
  static const url = 'url';

  // Related to Reminder and Date blocks
  static const date = 'date'; // Start Date
  static const includeTime = 'include_time';
  static const reminderId = 'reminder_id'; // ReminderID
  static const reminderOption = 'reminder_option';

  static const mentionChar = '\$';

  static Map<String, dynamic> buildMentionPageAttributes({
    required MentionType mentionType,
    required String pageId,
    required String? blockId,
  }) {
    return {
      MentionBlockKeys.mention: {
        MentionBlockKeys.type: mentionType.name,
        MentionBlockKeys.pageId: pageId,
        if (blockId != null) MentionBlockKeys.blockId: blockId,
      },
    };
  }

  static Map<String, dynamic> buildMentionDateAttributes({
    required String date,
    required String? reminderId,
    required String? reminderOption,
    required bool includeTime,
  }) {
    return {
      MentionBlockKeys.mention: {
        MentionBlockKeys.type: MentionType.date.name,
        MentionBlockKeys.date: date,
        MentionBlockKeys.includeTime: includeTime,
        if (reminderId != null) MentionBlockKeys.reminderId: reminderId,
        if (reminderOption != null)
          MentionBlockKeys.reminderOption: reminderOption,
      },
    };
  }
}
