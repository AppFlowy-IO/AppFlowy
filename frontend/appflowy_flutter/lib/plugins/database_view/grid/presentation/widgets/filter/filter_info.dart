import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';

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
