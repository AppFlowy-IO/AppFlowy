import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

/// FieldService consists of lots of event functions. We define the events in the backend(Rust),
/// you can find the corresponding event implementation in event_map.rs of the corresponding crate.
///
/// You could check out the rust-lib/flowy-database/event_map.rs for more information.
class FieldBackendService {
  final String viewId;
  final String fieldId;

  FieldBackendService({required this.viewId, required this.fieldId});

  Future<Either<Unit, FlowyError>> moveField(int fromIndex, int toIndex) {
    final payload = MoveFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return DatabaseEventMoveField(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateField({
    String? name,
    bool? frozen,
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

    return DatabaseEventUpdateField(payload).send();
  }

  static Future<Either<Unit, FlowyError>> updateFieldTypeOption({
    required String viewId,
    required String fieldId,
    required List<int> typeOptionData,
  }) {
    final payload = TypeOptionChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..typeOptionData = typeOptionData;

    return DatabaseEventUpdateFieldTypeOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateFieldType({
    required FieldType fieldType,
  }) {
    final payload = UpdateFieldTypePayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return DatabaseEventUpdateFieldType(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteField() {
    final payload = DeleteFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventDeleteField(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateField() {
    final payload = DuplicateFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventDuplicateField(payload).send();
  }

  Future<Either<TypeOptionPB, FlowyError>> getFieldTypeOptionData({
    required FieldType fieldType,
  }) {
    final payload = TypeOptionPathPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = fieldType;
    return DatabaseEventGetTypeOption(payload).send().then((result) {
      return result.fold(
        (data) => left(data),
        (err) => right(err),
      );
    });
  }

  /// Returns the primary field of the view.
  static Future<Either<FieldPB, FlowyError>> getPrimaryField({
    required String viewId,
  }) {
    final payload = DatabaseViewIdPB.create()..value = viewId;
    return DatabaseEventGetPrimaryField(payload).send();
  }
}
