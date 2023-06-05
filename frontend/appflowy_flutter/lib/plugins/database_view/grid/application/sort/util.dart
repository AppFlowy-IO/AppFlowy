import '../../../application/field/field_controller.dart';

List<FieldInfo> getCreatableSorts(final List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere((final element) => element.canCreateSort);
  return creatableFields;
}
