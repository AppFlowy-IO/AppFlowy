import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

class BoardGroupService {
  final String viewId;
  FieldPB? groupField;

  BoardGroupService(this.viewId);

  void setGroupField(FieldPB field) {
    groupField = field;
  }
}
