import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/group.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/setting_entities.pb.dart';

class SettingFFIService {
  final String viewId;

  const SettingFFIService({required this.viewId});

  Future<Either<GridSettingPB, FlowyError>> getSetting() {
    final payload = GridIdPB.create()..value = viewId;
    return GridEventGetGridSetting(payload).send();
  }

  Future<Either<Unit, FlowyError>> groupByField({
    required String fieldId,
    required FieldType fieldType,
  }) {
    final insertGroupPayload = InsertGroupPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType;
    final payload = GridSettingChangesetPayloadPB.create()
      ..gridId = viewId
      ..insertGroup = insertGroupPayload;

    return GridEventUpdateGridSetting(payload).send();
  }
}
