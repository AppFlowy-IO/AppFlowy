import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

class FilterInfo {
  FilterInfo(this.viewId, this.filter, this.fieldInfo);

  final String viewId;
  final FilterPB filter;
  final FieldInfo fieldInfo;

  FilterInfo copyWith({FilterPB? filter, FieldInfo? fieldInfo}) {
    return FilterInfo(
      viewId,
      filter ?? this.filter,
      fieldInfo ?? this.fieldInfo,
    );
  }

  String get filterId => filter.id;

  String get fieldId => filter.data.fieldId;

  DateFilterPB? dateFilter() {
    final fieldType = filter.data.fieldType;
    return fieldType == FieldType.DateTime ||
            fieldType == FieldType.CreatedTime ||
            fieldType == FieldType.LastEditedTime
        ? DateFilterPB.fromBuffer(filter.data.data)
        : null;
  }

  TextFilterPB? textFilter() {
    return filter.data.fieldType == FieldType.RichText ||
            filter.data.fieldType == FieldType.URL
        ? TextFilterPB.fromBuffer(filter.data.data)
        : null;
  }

  CheckboxFilterPB? checkboxFilter() {
    return filter.data.fieldType == FieldType.Checkbox
        ? CheckboxFilterPB.fromBuffer(filter.data.data)
        : null;
  }

  SelectOptionFilterPB? selectOptionFilter() {
    return filter.data.fieldType == FieldType.SingleSelect ||
            filter.data.fieldType == FieldType.MultiSelect
        ? SelectOptionFilterPB.fromBuffer(filter.data.data)
        : null;
  }

  ChecklistFilterPB? checklistFilter() {
    return filter.data.fieldType == FieldType.Checklist
        ? ChecklistFilterPB.fromBuffer(filter.data.data)
        : null;
  }

  NumberFilterPB? numberFilter() {
    return filter.data.fieldType == FieldType.Number
        ? NumberFilterPB.fromBuffer(filter.data.data)
        : null;
  }

  TimerFilterPB? timerFilter() {
    return filter.data.fieldType == FieldType.Timer
        ? TimerFilterPB.fromBuffer(filter.data.data)
        : null;
  }
}
