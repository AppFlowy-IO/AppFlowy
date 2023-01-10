import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pb.dart';

class SortInfo {
  final SortPB sortPB;
  final FieldInfo fieldInfo;

  SortInfo({required this.sortPB, required this.fieldInfo});

  String get sortId => sortPB.id;
}
