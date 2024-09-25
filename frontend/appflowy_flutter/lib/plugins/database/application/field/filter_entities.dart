import 'dart:typed_data';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/view/database_filter_bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checklist.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/date.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/number.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/condition_list.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

abstract class DatabaseFilter {
  const DatabaseFilter({
    required this.filterId,
    required this.fieldId,
    required this.fieldType,
  });

  factory DatabaseFilter.fromPB(FilterPB filterPB) {
    final FilterDataPB(:fieldId, :fieldType) = filterPB.data;
    switch (fieldType) {
      case FieldType.RichText:
      case FieldType.URL:
        final data = TextFilterPB.fromBuffer(filterPB.data.data);
        return TextFilter(
          filterId: filterPB.id,
          fieldId: fieldId,
          fieldType: fieldType,
          condition: data.condition,
          content: data.content,
        );
      case FieldType.Number:
        final data = NumberFilterPB.fromBuffer(filterPB.data.data);
        return NumberFilter(
          filterId: filterPB.id,
          fieldId: fieldId,
          fieldType: fieldType,
          condition: data.condition,
          content: data.content,
        );
      case FieldType.Checkbox:
        final data = CheckboxFilterPB.fromBuffer(filterPB.data.data);
        return CheckboxFilter(
          filterId: filterPB.id,
          fieldId: fieldId,
          fieldType: fieldType,
          condition: data.condition,
        );
      case FieldType.Checklist:
        final data = ChecklistFilterPB.fromBuffer(filterPB.data.data);
        return ChecklistFilter(
          filterId: filterPB.id,
          fieldId: fieldId,
          fieldType: fieldType,
          condition: data.condition,
        );
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        final data = SelectOptionFilterPB.fromBuffer(filterPB.data.data);
        return SelectOptionFilter(
          filterId: filterPB.id,
          fieldId: fieldId,
          fieldType: fieldType,
          condition: data.condition,
          optionIds: data.optionIds,
        );
      case FieldType.DateTime:
        final data = DateFilterPB.fromBuffer(filterPB.data.data);
        return DateTimeFilter(
          filterId: filterPB.id,
          fieldId: fieldId,
          fieldType: fieldType,
          condition: data.condition,
          timestamp: data.hasTimestamp() ? data.timestamp.toDateTime() : null,
          start: data.hasStart() ? data.start.toDateTime() : null,
          end: data.hasEnd() ? data.end.toDateTime() : null,
        );
      default:
        throw ArgumentError();
    }
  }

  final String filterId;
  final String fieldId;
  final FieldType fieldType;

  String get conditionName;

  bool get canAttachContent;

  String getContentDescription(FieldInfo field);

  Widget getMobileDescription(
    FieldInfo field, {
    required VoidCallback onExpand,
    required void Function(DatabaseFilter filter) onUpdate,
  }) =>
      const SizedBox.shrink();

  Uint8List writeToBuffer();
}

final class TextFilter extends DatabaseFilter {
  const TextFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
    required this.content,
  });

  final TextFilterConditionPB condition;
  final String content;

  @override
  String get conditionName => condition.filterName;

  @override
  bool get canAttachContent =>
      condition != TextFilterConditionPB.TextIsEmpty &&
      condition != TextFilterConditionPB.TextIsNotEmpty;

  @override
  String getContentDescription(FieldInfo field) {
    final filterDesc = condition.choicechipPrefix;

    if (condition == TextFilterConditionPB.TextIsEmpty ||
        condition == TextFilterConditionPB.TextIsNotEmpty) {
      return filterDesc;
    }

    return content.isEmpty ? filterDesc : "$filterDesc $content";
  }

  @override
  Widget getMobileDescription(
    FieldInfo field, {
    required VoidCallback onExpand,
    required void Function(DatabaseFilter filter) onUpdate,
  }) {
    return FilterItemInnerTextField(
      content: content,
      enabled: canAttachContent,
      onSubmitted: (content) {
        final newFilter = copyWith(content: content);
        onUpdate(newFilter);
      },
    );
  }

  @override
  Uint8List writeToBuffer() {
    final filterPB = TextFilterPB()..condition = condition;

    if (condition != TextFilterConditionPB.TextIsEmpty &&
        condition != TextFilterConditionPB.TextIsNotEmpty) {
      filterPB.content = content;
    }
    return filterPB.writeToBuffer();
  }

  TextFilter copyWith({
    TextFilterConditionPB? condition,
    String? content,
  }) {
    return TextFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
      content: content ?? this.content,
    );
  }
}

final class NumberFilter extends DatabaseFilter {
  const NumberFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
    required this.content,
  });

  final NumberFilterConditionPB condition;
  final String content;

  @override
  String get conditionName => condition.filterName;

  @override
  bool get canAttachContent =>
      condition != NumberFilterConditionPB.NumberIsEmpty &&
      condition != NumberFilterConditionPB.NumberIsNotEmpty;

  @override
  String getContentDescription(FieldInfo field) {
    if (condition == NumberFilterConditionPB.NumberIsEmpty ||
        condition == NumberFilterConditionPB.NumberIsNotEmpty) {
      return condition.shortName;
    }

    return "${condition.shortName} $content";
  }

  @override
  Widget getMobileDescription(
    FieldInfo field, {
    required VoidCallback onExpand,
    required void Function(DatabaseFilter filter) onUpdate,
  }) {
    return FilterItemInnerTextField(
      content: content,
      enabled: canAttachContent,
      onSubmitted: (content) {
        final newFilter = copyWith(content: content);
        onUpdate(newFilter);
      },
    );
  }

  @override
  Uint8List writeToBuffer() {
    final filterPB = NumberFilterPB()..condition = condition;

    if (condition != NumberFilterConditionPB.NumberIsEmpty &&
        condition != NumberFilterConditionPB.NumberIsNotEmpty) {
      filterPB.content = content;
    }
    return filterPB.writeToBuffer();
  }

  NumberFilter copyWith({
    NumberFilterConditionPB? condition,
    String? content,
  }) {
    return NumberFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
      content: content ?? this.content,
    );
  }
}

final class CheckboxFilter extends DatabaseFilter {
  const CheckboxFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
  });

  final CheckboxFilterConditionPB condition;

  @override
  String get conditionName => condition.filterName;

  @override
  bool get canAttachContent => false;

  @override
  String getContentDescription(FieldInfo field) => condition.filterName;

  @override
  Uint8List writeToBuffer() {
    return (CheckboxFilterPB()..condition = condition).writeToBuffer();
  }

  CheckboxFilter copyWith({
    CheckboxFilterConditionPB? condition,
  }) {
    return CheckboxFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
    );
  }
}

final class ChecklistFilter extends DatabaseFilter {
  const ChecklistFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
  });

  final ChecklistFilterConditionPB condition;

  @override
  String get conditionName => condition.filterName;

  @override
  bool get canAttachContent => false;

  @override
  String getContentDescription(FieldInfo field) => condition.filterName;

  @override
  Uint8List writeToBuffer() {
    return (ChecklistFilterPB()..condition = condition).writeToBuffer();
  }

  ChecklistFilter copyWith({
    ChecklistFilterConditionPB? condition,
  }) {
    return ChecklistFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
    );
  }
}

final class SelectOptionFilter extends DatabaseFilter {
  const SelectOptionFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
    required this.optionIds,
  });

  final SelectOptionFilterConditionPB condition;
  final List<String> optionIds;

  @override
  String get conditionName => condition.i18n;

  @override
  bool get canAttachContent =>
      condition != SelectOptionFilterConditionPB.OptionIsEmpty &&
      condition != SelectOptionFilterConditionPB.OptionIsNotEmpty;

  @override
  String getContentDescription(FieldInfo field) {
    if (!canAttachContent) {
      return condition.i18n;
    }

    final delegate = makeDelegate(field);
    final options = delegate.getOptions(field);

    final optionNames =
        options.where((option) => optionIds.contains(option.id)).join(', ');
    return "${condition.i18n} $optionNames";
  }

  @override
  Widget getMobileDescription(
    FieldInfo field, {
    required VoidCallback onExpand,
    required void Function(DatabaseFilter filter) onUpdate,
  }) {
    final delegate = makeDelegate(field);
    final options = delegate
        .getOptions(field)
        .where((option) => optionIds.contains(option.id))
        .toList();

    return FilterItemInnerButton(
      onTap: onExpand,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const HSpace(8),
        itemCount: options.length,
        itemBuilder: (context, index) => SelectOptionTag(
          option: options[index],
          fontSize: 14,
          borderRadius: BorderRadius.circular(9),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  @override
  Uint8List writeToBuffer() {
    final filterPB = SelectOptionFilterPB()..condition = condition;

    if (canAttachContent) {
      filterPB.optionIds.addAll(optionIds);
    }

    return filterPB.writeToBuffer();
  }

  SelectOptionFilter copyWith({
    SelectOptionFilterConditionPB? condition,
    List<String>? optionIds,
  }) {
    final options = optionIds ?? this.optionIds;
    if (fieldType == FieldType.SingleSelect &&
        condition == SelectOptionFilterConditionPB.OptionIs &&
        options.length > 1) {
      options.removeRange(1, options.length);
    }
    return SelectOptionFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
      optionIds: optionIds ?? this.optionIds,
    );
  }

  SelectOptionFilterDelegate makeDelegate(FieldInfo field) =>
      field.fieldType == FieldType.SingleSelect
          ? const SingleSelectOptionFilterDelegateImpl()
          : const MultiSelectOptionFilterDelegateImpl();
}

enum DateTimeFilterCondition {
  on,
  before,
  after,
  onOrBefore,
  onOrAfter,
  between,
  isEmpty,
  isNotEmpty;

  DateFilterConditionPB toPB(bool isStart) {
    return isStart
        ? switch (this) {
            on => DateFilterConditionPB.DateStartsOn,
            before => DateFilterConditionPB.DateStartsBefore,
            after => DateFilterConditionPB.DateStartsAfter,
            onOrBefore => DateFilterConditionPB.DateStartsOnOrBefore,
            onOrAfter => DateFilterConditionPB.DateStartsOnOrAfter,
            between => DateFilterConditionPB.DateStartsBetween,
            isEmpty => DateFilterConditionPB.DateStartIsEmpty,
            isNotEmpty => DateFilterConditionPB.DateStartIsNotEmpty,
          }
        : switch (this) {
            on => DateFilterConditionPB.DateEndsOn,
            before => DateFilterConditionPB.DateEndsBefore,
            after => DateFilterConditionPB.DateEndsAfter,
            onOrBefore => DateFilterConditionPB.DateEndsOnOrBefore,
            onOrAfter => DateFilterConditionPB.DateEndsOnOrAfter,
            between => DateFilterConditionPB.DateEndsBetween,
            isEmpty => DateFilterConditionPB.DateEndIsEmpty,
            isNotEmpty => DateFilterConditionPB.DateEndIsNotEmpty,
          };
  }

  String get choiceChipPrefix {
    return switch (this) {
      on => "",
      before => LocaleKeys.grid_dateFilter_choicechipPrefix_before.tr(),
      after => LocaleKeys.grid_dateFilter_choicechipPrefix_after.tr(),
      onOrBefore => LocaleKeys.grid_dateFilter_choicechipPrefix_onOrBefore.tr(),
      onOrAfter => LocaleKeys.grid_dateFilter_choicechipPrefix_onOrAfter.tr(),
      between => LocaleKeys.grid_dateFilter_choicechipPrefix_between.tr(),
      isEmpty => LocaleKeys.grid_dateFilter_choicechipPrefix_isEmpty.tr(),
      isNotEmpty => LocaleKeys.grid_dateFilter_choicechipPrefix_isNotEmpty.tr(),
    };
  }

  String get filterName {
    return switch (this) {
      on => LocaleKeys.grid_dateFilter_is.tr(),
      before => LocaleKeys.grid_dateFilter_before.tr(),
      after => LocaleKeys.grid_dateFilter_after.tr(),
      onOrBefore => LocaleKeys.grid_dateFilter_onOrBefore.tr(),
      onOrAfter => LocaleKeys.grid_dateFilter_onOrAfter.tr(),
      between => LocaleKeys.grid_dateFilter_between.tr(),
      isEmpty => LocaleKeys.grid_dateFilter_empty.tr(),
      isNotEmpty => LocaleKeys.grid_dateFilter_notEmpty.tr(),
    };
  }
}

final class DateTimeFilter extends DatabaseFilter {
  const DateTimeFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
    this.timestamp,
    this.start,
    this.end,
  });

  final DateFilterConditionPB condition;
  final DateTime? timestamp;
  final DateTime? start;
  final DateTime? end;

  @override
  String get conditionName => condition.toCondition().filterName;

  @override
  bool get canAttachContent => ![
        DateFilterConditionPB.DateStartIsEmpty,
        DateFilterConditionPB.DateStartIsNotEmpty,
        DateFilterConditionPB.DateEndIsEmpty,
        DateFilterConditionPB.DateEndIsNotEmpty,
      ].contains(condition);

  @override
  String getContentDescription(FieldInfo field) {
    return switch (condition) {
      DateFilterConditionPB.DateStartIsEmpty ||
      DateFilterConditionPB.DateStartIsNotEmpty ||
      DateFilterConditionPB.DateEndIsEmpty ||
      DateFilterConditionPB.DateEndIsNotEmpty =>
        condition.toCondition().choiceChipPrefix,
      DateFilterConditionPB.DateStartsOn ||
      DateFilterConditionPB.DateEndsOn =>
        timestamp?.defaultFormat ?? "",
      DateFilterConditionPB.DateStartsBetween ||
      DateFilterConditionPB.DateEndsBetween =>
        "${condition.toCondition().choiceChipPrefix} ${start?.defaultFormat ?? ""} - ${end?.defaultFormat ?? ""}",
      _ =>
        "${condition.toCondition().choiceChipPrefix} ${timestamp?.defaultFormat ?? ""}"
    };
  }

  @override
  Widget getMobileDescription(
    FieldInfo field, {
    required VoidCallback onExpand,
    required void Function(DatabaseFilter filter) onUpdate,
  }) {
    String? text;

    if (condition.isRange) {
      text = "${start?.defaultFormat ?? ""} - ${end?.defaultFormat ?? ""}";
      text = text == " - " ? null : text;
    } else {
      text = timestamp.defaultFormat;
    }
    return FilterItemInnerButton(
      onTap: onExpand,
      child: FlowyText(
        text ?? "",
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Uint8List writeToBuffer() {
    final filterPB = DateFilterPB()..condition = condition;

    Int64 dateTimeToInt(DateTime dateTime) {
      return Int64(dateTime.millisecondsSinceEpoch ~/ 1000);
    }

    switch (condition) {
      case DateFilterConditionPB.DateStartsOn:
      case DateFilterConditionPB.DateStartsBefore:
      case DateFilterConditionPB.DateStartsOnOrBefore:
      case DateFilterConditionPB.DateStartsAfter:
      case DateFilterConditionPB.DateStartsOnOrAfter:
      case DateFilterConditionPB.DateEndsOn:
      case DateFilterConditionPB.DateEndsBefore:
      case DateFilterConditionPB.DateEndsOnOrBefore:
      case DateFilterConditionPB.DateEndsAfter:
      case DateFilterConditionPB.DateEndsOnOrAfter:
        if (timestamp != null) {
          filterPB.timestamp = dateTimeToInt(timestamp!);
        }
        break;
      case DateFilterConditionPB.DateStartsBetween:
      case DateFilterConditionPB.DateEndsBetween:
        if (start != null) {
          filterPB.start = dateTimeToInt(start!);
        }
        if (end != null) {
          filterPB.end = dateTimeToInt(end!);
        }
        break;
      default:
        break;
    }

    return filterPB.writeToBuffer();
  }

  DateTimeFilter copyWithCondition({
    required bool isStart,
    required DateTimeFilterCondition condition,
  }) {
    return DateTimeFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition.toPB(isStart),
      start: start,
      end: end,
      timestamp: timestamp,
    );
  }

  DateTimeFilter copyWithTimestamp({
    required DateTime timestamp,
  }) {
    return DateTimeFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition,
      start: start,
      end: end,
      timestamp: timestamp,
    );
  }

  DateTimeFilter copyWithRange({
    required DateTime? start,
    required DateTime? end,
  }) {
    return DateTimeFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition,
      start: start,
      end: end,
      timestamp: timestamp,
    );
  }
}

final class TimeFilter extends DatabaseFilter {
  const TimeFilter({
    required super.filterId,
    required super.fieldId,
    required super.fieldType,
    required this.condition,
    required this.content,
  });

  final NumberFilterConditionPB condition;
  final String content;

  @override
  String get conditionName => condition.filterName;

  @override
  bool get canAttachContent =>
      condition != NumberFilterConditionPB.NumberIsEmpty &&
      condition != NumberFilterConditionPB.NumberIsNotEmpty;

  @override
  String getContentDescription(FieldInfo field) {
    if (condition == NumberFilterConditionPB.NumberIsEmpty ||
        condition == NumberFilterConditionPB.NumberIsNotEmpty) {
      return condition.shortName;
    }

    return "${condition.shortName} $content";
  }

  @override
  Uint8List writeToBuffer() {
    return (NumberFilterPB()
          ..condition = condition
          ..content = content)
        .writeToBuffer();
  }

  TimeFilter copyWith({NumberFilterConditionPB? condition, String? content}) {
    return TimeFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
      content: content ?? this.content,
    );
  }
}
