import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/text_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/util.pb.dart';

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
