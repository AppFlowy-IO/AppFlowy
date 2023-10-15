import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class FieldSettingsBackendService {
  const FieldSettingsBackendService._();

  static Future<Either<Unit, FlowyError>> updateFieldSettings({
    required String viewId,
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
