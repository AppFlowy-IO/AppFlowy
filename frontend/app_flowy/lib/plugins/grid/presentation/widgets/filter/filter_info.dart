import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checklist_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';

class FilterInfo {
  final String viewId;
  final FilterPB filter;
  final FieldInfo fieldInfo;

  FilterInfo(this.viewId, this.filter, this.fieldInfo);

  FilterInfo copyWith({FilterPB? filter, FieldInfo? fieldInfo}) {
    return FilterInfo(
      viewId,
      filter ?? this.filter,
      fieldInfo ?? this.fieldInfo,
    );
  }

  DateFilterPB? dateFilter() {
    if (filter.fieldType != FieldType.DateTime) {
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
