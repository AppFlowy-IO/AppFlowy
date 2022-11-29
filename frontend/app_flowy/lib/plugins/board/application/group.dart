import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';

class BoardGroupService {
  final String gridId;
  FieldPB? groupField;

  BoardGroupService(this.gridId);

  void setGroupField(FieldPB field) {
    groupField = field;
  }
}
