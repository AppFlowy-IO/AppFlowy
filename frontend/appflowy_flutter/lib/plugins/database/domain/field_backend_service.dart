import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/field_settings_service.dart';
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

  Future<void> show() async {
    await fieldSettingsService.updateFieldSettings(
      fieldId: fieldId,
      fieldVisibility: FieldVisibility.AlwaysShown,
    );
  }

  Future<void> delete() async {
    await fieldBackendService.delete();
  }

  Future<void> duplicate() async {
    await fieldBackendService.duplicate();
  }

  Future<void> insertLeft() async {
    await FieldBackendService.createField(
      viewId: viewId,
      position: OrderObjectPositionPB(
        position: OrderObjectPositionTypePB.Before,
        objectId: fieldId,
      ),
    );
  }

  Future<void> insertRight() async {
    await FieldBackendService.createField(
      viewId: viewId,
      position: OrderObjectPositionPB(
        position: OrderObjectPositionTypePB.After,
        objectId: fieldId,
      ),
    );
  }

  Future<void> updateName(String name) async {
    await fieldBackendService.updateField(
      name: name,
    );
  }
}
