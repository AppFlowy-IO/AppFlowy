import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class FieldSettingsBackendService {
  FieldSettingsBackendService({required this.viewId});

  final String viewId;

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
    double? width,
  }) {
    final FieldSettingsChangesetPB payload = FieldSettingsChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    if (fieldVisibility != null) {
      payload.visibility = fieldVisibility;
    }

    if (width != null) {
      payload.width = width.round();
    }

    return DatabaseEventUpdateFieldSettings(payload).send();
  }
}
