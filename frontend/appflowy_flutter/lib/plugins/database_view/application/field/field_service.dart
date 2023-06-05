import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_service.freezed.dart';

/// FieldService consists of lots of event functions. We define the events in the backend(Rust),
/// you can find the corresponding event implementation in event_map.rs of the corresponding crate.
///
/// You could check out the rust-lib/flowy-database/event_map.rs for more information.
class FieldBackendService {
  final String viewId;
  final String fieldId;

  FieldBackendService({required this.viewId, required this.fieldId});

  Future<Either<Unit, FlowyError>> moveField(final int fromIndex, final int toIndex) {
    final payload = MoveFieldPayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return DatabaseEventMoveField(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateField({
    final String? name,
    final FieldType? fieldType,
    final bool? frozen,
    final bool? visibility,
    final double? width,
  }) {
    final payload = FieldChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId;

    if (name != null) {
      payload.name = name;
    }

    if (fieldType != null) {
      payload.fieldType = fieldType;
    }

    if (frozen != null) {
      payload.frozen = frozen;
    }

    if (visibility != null) {
      payload.visibility = visibility;
    }

    if (width != null) {
      payload.width = width.toInt();
    }

    return DatabaseEventUpdateField(payload).send();
  }

  static Future<Either<Unit, FlowyError>> updateFieldTypeOption({
    required final String viewId,
    required final String fieldId,
    required final List<int> typeOptionData,
  }) {
    final payload = TypeOptionChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..typeOptionData = typeOptionData;

    return DatabaseEventUpdateFieldTypeOption(payload).send();
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
    required final FieldType fieldType,
  }) {
    final payload = TypeOptionPathPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = fieldType;
    return DatabaseEventGetTypeOption(payload).send().then((final result) {
      return result.fold(
        (final data) => left(data),
        (final err) => right(err),
      );
    });
  }
}

@freezed
class FieldCellContext with _$FieldCellContext {
  const factory FieldCellContext({
    required final String viewId,
    required final FieldPB field,
  }) = _FieldCellContext;
}
