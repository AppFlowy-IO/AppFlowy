import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';

extension GroupName on GroupPB {
  String generateGroupName(DatabaseController databaseController) {
    final fieldController = databaseController.fieldController;
    final field = fieldController.getField(fieldId);
    if (field == null) {
      return "";
    }

    // if the group is the default group, then
    if (isDefault) {
      return "No ${field.name}";
    }

    final groupSettings = databaseController.fieldController.groupSettings
        .firstWhereOrNull((gs) => gs.fieldId == field.id);

    switch (field.fieldType) {
      case FieldType.SingleSelect:
        final options =
            SingleSelectTypeOptionPB.fromBuffer(field.field.typeOptionData)
                .options;
        final option =
            options.firstWhereOrNull((option) => option.id == groupId);
        return option == null ? "" : option.name;
      case FieldType.MultiSelect:
        final options =
            MultiSelectTypeOptionPB.fromBuffer(field.field.typeOptionData)
                .options;
        final option =
            options.firstWhereOrNull((option) => option.id == groupId);
        return option == null ? "" : option.name;
      case FieldType.Checkbox:
        return groupId;
      case FieldType.URL:
        return groupId;
      case FieldType.DateTime:
        final config = groupSettings?.content != null
            ? DateGroupConfigurationPB.fromBuffer(groupSettings!.content)
            : DateGroupConfigurationPB();
        final dateFormat = DateFormat("y/MM/dd");
        try {
          final targetDateTime = dateFormat.parseLoose(groupId);
          switch (config.condition) {
            case DateConditionPB.Day:
              return DateFormat("MMM dd, y").format(targetDateTime);
            case DateConditionPB.Week:
              final beginningOfWeek = targetDateTime
                  .subtract(Duration(days: targetDateTime.weekday - 1));
              final endOfWeek = targetDateTime.add(
                Duration(days: DateTime.daysPerWeek - targetDateTime.weekday),
              );

              final beginningOfWeekFormat =
                  beginningOfWeek.year != endOfWeek.year
                      ? "MMM dd y"
                      : "MMM dd";
              final endOfWeekFormat = beginningOfWeek.month != endOfWeek.month
                  ? "MMM dd y"
                  : "dd y";

              return LocaleKeys.board_dateCondition_weekOf.tr(
                args: [
                  DateFormat(beginningOfWeekFormat).format(beginningOfWeek),
                  DateFormat(endOfWeekFormat).format(endOfWeek),
                ],
              );
            case DateConditionPB.Month:
              return DateFormat("MMM y").format(targetDateTime);
            case DateConditionPB.Year:
              return DateFormat("y").format(targetDateTime);
            case DateConditionPB.Relative:
              final targetDateTimeDay = DateTime(
                targetDateTime.year,
                targetDateTime.month,
                targetDateTime.day,
              );
              final nowDay = DateTime.now().withoutTime;
              final diff = targetDateTimeDay.difference(nowDay).inDays;
              return switch (diff) {
                0 => LocaleKeys.board_dateCondition_today.tr(),
                -1 => LocaleKeys.board_dateCondition_yesterday.tr(),
                1 => LocaleKeys.board_dateCondition_tomorrow.tr(),
                -7 => LocaleKeys.board_dateCondition_lastSevenDays.tr(),
                2 => LocaleKeys.board_dateCondition_nextSevenDays.tr(),
                -30 => LocaleKeys.board_dateCondition_lastThirtyDays.tr(),
                8 => LocaleKeys.board_dateCondition_nextThirtyDays.tr(),
                _ => DateFormat("MMM y").format(targetDateTimeDay)
              };
            default:
              return "";
          }
        } on FormatException {
          return "";
        }
      default:
        return "";
    }
  }
}
