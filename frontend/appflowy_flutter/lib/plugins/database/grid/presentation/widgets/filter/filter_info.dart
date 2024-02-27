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

  String get fieldId => filter.fieldId;

  DateFilterPB? dateFilter() {
    return filter.fieldType == FieldType.DateTime
        ? DateFilterPB.fromBuffer(filter.data)
        : null;
  }

  TextFilterPB? textFilter() {
    return filter.fieldType == FieldType.RichText
        ? TextFilterPB.fromBuffer(filter.data)
        : null;
  }

  CheckboxFilterPB? checkboxFilter() {
    return filter.fieldType == FieldType.Checkbox
        ? CheckboxFilterPB.fromBuffer(filter.data)
        : null;
  }

  SelectOptionFilterPB? selectOptionFilter() {
    return filter.fieldType == FieldType.SingleSelect ||
            filter.fieldType == FieldType.MultiSelect
        ? SelectOptionFilterPB.fromBuffer(filter.data)
        : null;
  }

  ChecklistFilterPB? checklistFilter() {
    return filter.fieldType == FieldType.Checklist
        ? ChecklistFilterPB.fromBuffer(filter.data)
        : null;
  }

  NumberFilterPB? numberFilter() {
    return filter.fieldType == FieldType.Number
        ? NumberFilterPB.fromBuffer(filter.data)
        : null;
  }
}
