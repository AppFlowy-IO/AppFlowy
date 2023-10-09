import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

/// FieldService consists of lots of event functions. We define the events in the backend(Rust),
/// you can find the corresponding event implementation in event_map.rs of the corresponding crate.
///
/// You could check out the rust-lib/flowy-database/event_map.rs for more information.
class FieldBackendService {
  final String viewId;

  FieldBackendService({required this.viewId});

  Future<Either<Unit, FlowyError>> moveField(
    String fieldId,
    int fromIndex,
    int toIndex,
  ) {
    final payload = MoveFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return DatabaseEventMoveField(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateField({
    required String fieldId,
    String? name,
    bool? frozen,
    double? width,
  }) {
    final payload = FieldChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    if (name != null) {
      payload.name = name;
    }

    if (frozen != null) {
      payload.frozen = frozen;
    }

    if (width != null) {
      payload.width = width.toInt();
    }

    return DatabaseEventUpdateField(payload).send();
  }

  Future<Either<Unit, FlowyError>> switchToField({
    required String fieldId,
    required FieldType newFieldType,
  }) async {
    final payload = UpdateFieldTypePayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = newFieldType;

    return DatabaseEventUpdateFieldType(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateFieldTypeOption({
    required String fieldId,
    required List<int> typeOptionData,
  }) {
    final payload = FieldChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..typeOption = typeOptionData;

    return DatabaseEventUpdateField(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteField({required String fieldId}) {
    final payload = DeleteFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventDeleteField(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateField({required String fieldId}) {
    final payload = DuplicateFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventDuplicateField(payload).send();
  }

  static Future<Either<FieldPB, FlowyError>> getPrimaryField({
    required String viewId,
  }) {
    final payload = DatabaseViewIdPB.create()..value = viewId;
    return DatabaseEventGetPrimaryField(payload).send();
  }

  Future<Either<SelectOptionPB, FlowyError>> newOption({
    required String fieldId,
    required String name,
  }) {
    final payload = CreateSelectOptionPayloadPB.create()
      ..optionName = name
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventCreateSelectOption(payload).send();
  }

  Future<Either<FieldPB, FlowyError>> createField({
    required String viewId,
    FieldType fieldType = FieldType.RichText,
  }) {
    final payload = CreateFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldType = fieldType;

    return DatabaseEventCreateField(payload).send();
  }
}
