import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class FieldSettingsBackendService {
  final String viewId;
  FieldSettingsBackendService({required this.viewId});

  Future<Either<FieldSettingsPB, FlowyError>> getFieldSettings(
    String fieldId,
  ) {
    final id = FieldIdPB(fieldId: fieldId);
    final ids = RepeatedFieldIdPB()..items.add(id);
    final payload = FieldIdsPB()
      ..viewId = viewId
      ..fieldIds = ids;

    return DatabaseEventGetFieldSettings(payload).send().then((result) {
      return result.fold(
        (repeatedFieldSettings) {
          final fieldSetting = repeatedFieldSettings.items.first;
          if (!fieldSetting.hasVisibility()) {
            fieldSetting.visibility = FieldVisibility.AlwaysShown;
          }

          return left(fieldSetting);
        },
        (r) => right(r),
      );
    });
  }

  Future<Either<List<FieldSettingsPB>, FlowyError>> getAllFieldSettings() {
    final payload = DatabaseViewIdPB()..value = viewId;

    return DatabaseEventGetAllFieldSettings(payload).send().then((result) {
      return result.fold(
        (repeatedFieldSettings) {
          final fieldSettings = <FieldSettingsPB>[];

          for (final fieldSetting in repeatedFieldSettings.items) {
            if (!fieldSetting.hasVisibility()) {
              fieldSetting.visibility = FieldVisibility.AlwaysShown;
            }
            fieldSettings.add(fieldSetting);
          }

          return left(fieldSettings);
        },
        (r) => right(r),
      );
    });
  }

  Future<Either<Unit, FlowyError>> updateFieldSettings({
    required String fieldId,
    FieldVisibility? fieldVisibility,
  }) {
    final FieldSettingsChangesetPB payload = FieldSettingsChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    if (fieldVisibility != null) {
      payload.visibility = fieldVisibility;
    }

    return DatabaseEventUpdateFieldSettings(payload).send();
  }
}
