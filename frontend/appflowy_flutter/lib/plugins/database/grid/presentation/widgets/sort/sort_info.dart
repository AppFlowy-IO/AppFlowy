import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';

class SortInfo {
  SortInfo({required this.sortPB, required this.fieldInfo});

  final SortPB sortPB;
  final FieldInfo fieldInfo;

  String get sortId => sortPB.id;

  String get fieldId => sortPB.fieldId;
}
