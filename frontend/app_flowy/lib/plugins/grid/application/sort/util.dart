import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';

List<FieldInfo> getCreatableSorts(List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere((element) => element.canCreateSort);
  return creatableFields;
}
