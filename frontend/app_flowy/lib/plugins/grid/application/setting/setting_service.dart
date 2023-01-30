import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';

class SettingFFIService {
  final String viewId;

  const SettingFFIService({required this.viewId});

  Future<Either<DatabaseViewSettingPB, FlowyError>> getSetting() {
    final payload = DatabaseIdPB.create()..value = viewId;
    return DatabaseEventGetDatabaseSetting(payload).send();
  }

  Future<Either<Unit, FlowyError>> groupByField({
    required String fieldId,
    required FieldType fieldType,
  }) {
    final insertGroupPayload = InsertGroupPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType;
    final payload = DatabaseSettingChangesetPB.create()
      ..gridId = viewId
      ..insertGroup = insertGroupPayload;

    return DatabaseEventUpdateDatabaseSetting(payload).send();
  }
}
