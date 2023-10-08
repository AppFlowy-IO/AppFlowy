import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';

class SortInfo {
  final SortPB sort;
  final FieldPB field;

  const SortInfo({required this.sort, required this.field});

  String get sortId => sort.id;

  String get fieldId => sort.fieldId;
}
