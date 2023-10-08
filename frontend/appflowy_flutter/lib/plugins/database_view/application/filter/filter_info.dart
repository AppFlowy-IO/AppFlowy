import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';

class FilterInfo {
  final FilterPB filter;
  final FieldPB field;

  const FilterInfo({required this.filter, required this.field});

  FilterInfo copyWith({FilterPB? filter, FieldPB? field}) {
    return FilterInfo(
      filter: filter ?? this.filter,
      field: field ?? this.field,
    );
  }

  String get filterId => filter.id;

  String get fieldId => filter.fieldId;

  DateFilterPB? dateFilter() {
    if (![
      FieldType.DateTime,
      FieldType.LastEditedTime,
      FieldType.CreatedTime,
    ].contains(filter.fieldType)) {
      return null;
    }
    return DateFilterPB.fromBuffer(filter.data);
  }

  TextFilterPB? textFilter() {
    if (filter.fieldType != FieldType.RichText) {
      return null;
    }
    return TextFilterPB.fromBuffer(filter.data);
  }

  CheckboxFilterPB? checkboxFilter() {
    if (filter.fieldType != FieldType.Checkbox) {
      return null;
    }
    return CheckboxFilterPB.fromBuffer(filter.data);
  }

  SelectOptionFilterPB? selectOptionFilter() {
    if (filter.fieldType == FieldType.SingleSelect ||
        filter.fieldType == FieldType.MultiSelect) {
      return SelectOptionFilterPB.fromBuffer(filter.data);
    } else {
      return null;
    }
  }

  ChecklistFilterPB? checklistFilter() {
    if (filter.fieldType == FieldType.Checklist) {
      return ChecklistFilterPB.fromBuffer(filter.data);
    } else {
      return null;
    }
  }
}
