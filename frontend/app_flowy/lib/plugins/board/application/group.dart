import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';

class BoardGroupService {
  final String gridId;
  FieldPB? groupField;

  BoardGroupService(this.gridId);

  void setGroupField(FieldPB field) {
    groupField = field;
  }
}
