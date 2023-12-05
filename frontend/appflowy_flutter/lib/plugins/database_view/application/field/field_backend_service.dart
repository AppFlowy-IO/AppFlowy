import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

// This class is used for combining the
// 1. FieldBackendService
// 2. FieldSettingsBackendService
// 3. TypeOptionBackendService
//
// including,
// hide, delete, duplicated,
// insertLeft, insertRight,
// updateName
class FieldServices {
  FieldServices({
    required this.viewId,
    required this.fieldId,
  })  : fieldBackendService = FieldBackendService(
          viewId: viewId,
          fieldId: fieldId,
        ),
        fieldSettingsService = FieldSettingsBackendService(
          viewId: viewId,
        );

  final String viewId;
  final String fieldId;

  final FieldBackendService fieldBackendService;
  final FieldSettingsBackendService fieldSettingsService;

  Future<void> hide() async {
    await fieldSettingsService.updateFieldSettings(
      fieldId: fieldId,
      fieldVisibility: FieldVisibility.AlwaysHidden,
    );
  }

  Future<void> delete() async {
    await fieldBackendService.deleteField();
  }

  Future<void> duplicate() async {
    await fieldBackendService.duplicateField();
  }

  Future<void> insertLeft() async {
    await TypeOptionBackendService.createFieldTypeOption(
      viewId: viewId,
      position: CreateFieldPosition.Before,
      targetFieldId: fieldId,
    );
  }

  Future<void> insertRight() async {
    await TypeOptionBackendService.createFieldTypeOption(
      viewId: viewId,
      position: CreateFieldPosition.After,
      targetFieldId: fieldId,
    );
  }

  Future<void> updateName(String name) async {
    await fieldBackendService.updateField(
      name: name,
    );
  }
}
