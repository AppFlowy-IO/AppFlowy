import 'dart:typed_data';

import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checklist.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/number.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/condition_list.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:fixnum/fixnum.dart';

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
      default:
        throw ArgumentError();
    }
  }

  final String filterId;
  final String fieldId;
  final FieldType fieldType;

  String get conditionName;

  String getDescription(FieldInfo field);

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
  String getDescription(FieldInfo field) {
    final filterDesc = condition.choicechipPrefix;

    if (condition == TextFilterConditionPB.TextIsEmpty ||
        condition == TextFilterConditionPB.TextIsNotEmpty) {
      return filterDesc;
    }

    return content.isEmpty ? filterDesc : "$filterDesc $content";
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
  String getDescription(FieldInfo field) {
    if (condition == NumberFilterConditionPB.NumberIsEmpty ||
        condition == NumberFilterConditionPB.NumberIsNotEmpty) {
      return condition.shortName;
    }

    return "${condition.shortName} $content";
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
  String getDescription(FieldInfo field) => condition.filterName;

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
  String getDescription(FieldInfo field) => condition.filterName;

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
  String getDescription(FieldInfo field) {
    if (condition == SelectOptionFilterConditionPB.OptionIsEmpty ||
        condition == SelectOptionFilterConditionPB.OptionIsNotEmpty) {
      return condition.i18n;
    }

    final delegate = fieldType == FieldType.SingleSelect
        ? const SingleSelectOptionFilterDelegateImpl()
        : const MultiSelectOptionFilterDelegateImpl();
    final options = delegate.getOptions(field);

    final optionNames =
        options.where((option) => optionIds.contains(option.id)).join(', ');
    return "${condition.i18n} $optionNames";
  }

  @override
  Uint8List writeToBuffer() {
    final filterPB = SelectOptionFilterPB()..condition = condition;

    if (condition != SelectOptionFilterConditionPB.OptionIsEmpty &&
        condition != SelectOptionFilterConditionPB.OptionIsNotEmpty) {
      filterPB.optionIds.addAll(optionIds);
    }
    return filterPB.writeToBuffer();
  }

  SelectOptionFilter copyWith({
    SelectOptionFilterConditionPB? condition,
    List<String>? optionIds,
  }) {
    return SelectOptionFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
      optionIds: optionIds ?? this.optionIds,
    );
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
  String get conditionName => condition.name;

  @override
  String getDescription(FieldInfo field) {
    return switch (condition) {
      DateFilterConditionPB.DateIsEmpty ||
      DateFilterConditionPB.DateIsNotEmpty =>
        condition.name,
      DateFilterConditionPB.DateWithIn =>
        "${condition.name} ${start ?? ""} - ${end ?? ""}",
      _ => "${condition.name} ${timestamp ?? ""}"
    };
  }

  @override
  Uint8List writeToBuffer() {
    final filterPB = DateFilterPB()..condition = condition;

    Int64 dateTimeToInt(DateTime dateTime) {
      return Int64(dateTime.millisecondsSinceEpoch ~/ 1000);
    }

    switch (condition) {
      case DateFilterConditionPB.DateIs:
      case DateFilterConditionPB.DateBefore:
      case DateFilterConditionPB.DateOnOrBefore:
      case DateFilterConditionPB.DateAfter:
      case DateFilterConditionPB.DateOnOrAfter:
        if (timestamp != null) {
          filterPB.timestamp = dateTimeToInt(timestamp!);
        }
        break;
      case DateFilterConditionPB.DateWithIn:
        if (start != null) {
          filterPB.start = dateTimeToInt(start!);
        }
        if (end != null) {
          filterPB.end = dateTimeToInt(end!);
        }
      default:
        break;
    }

    return filterPB.writeToBuffer();
  }

  DateTimeFilter copyWith({
    DateFilterConditionPB? condition,
    DateTime? start,
    DateTime? end,
    DateTime? timestamp,
  }) {
    return DateTimeFilter(
      filterId: filterId,
      fieldId: fieldId,
      fieldType: fieldType,
      condition: condition ?? this.condition,
      start: start ?? this.start,
      end: end ?? this.end,
      timestamp: timestamp ?? this.timestamp,
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
  String getDescription(FieldInfo field) {
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
