import 'dart:typed_data';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

/// FieldService provides many field-related interfaces event functions. Check out
/// `rust-lib/flowy-database/event_map.rs` for a list of events and their
/// implementations.
class FieldBackendService {
  FieldBackendService({required this.viewId, required this.fieldId});

  final String viewId;
  final String fieldId;

  /// Create a field in a database view. The position will only be applicable
  /// in this view; for other views it will be appended to the end
  static Future<Either<FieldPB, FlowyError>> createField({
    required String viewId,
    FieldType fieldType = FieldType.RichText,
    String? fieldName,
    Uint8List? typeOptionData,
    OrderObjectPositionPB? position,
  }) {
    final payload = CreateFieldPayloadPB(
      viewId: viewId,
      fieldType: fieldType,
      fieldName: fieldName,
      typeOptionData: typeOptionData,
      fieldPosition: position,
    );

    return DatabaseEventCreateField(payload).send();
  }

  /// Reorder a field within a database view
  static Future<Either<Unit, FlowyError>> moveField({
    required String viewId,
    required String fromFieldId,
    required String toFieldId,
  }) {
    final payload = MoveFieldPayloadPB(
      viewId: viewId,
      fromFieldId: fromFieldId,
      toFieldId: toFieldId,
    );

    return DatabaseEventMoveField(payload).send();
  }

  /// Delete a field
  static Future<Either<Unit, FlowyError>> deleteField({
    required String viewId,
    required String fieldId,
  }) {
    final payload = DeleteFieldPayloadPB(
      viewId: viewId,
      fieldId: fieldId,
    );

    return DatabaseEventDeleteField(payload).send();
  }

  /// Duplicate a field
  static Future<Either<Unit, FlowyError>> duplicateField({
    required String viewId,
    required String fieldId,
  }) {
    final payload = DuplicateFieldPayloadPB(
      viewId: viewId,
      fieldId: fieldId,
    );

    return DatabaseEventDuplicateField(payload).send();
  }

  /// Update a field's properties
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

  /// Change a field's type
  static Future<Either<Unit, FlowyError>> updateFieldType({
    required String viewId,
    required String fieldId,
    required FieldType fieldType,
  }) {
    final payload = UpdateFieldTypePayloadPB()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return DatabaseEventUpdateFieldType(payload).send();
  }

  /// Update a field's type option data
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

  /// Returns the primary field of the view.
  static Future<Either<FieldPB, FlowyError>> getPrimaryField({
    required String viewId,
  }) {
    final payload = DatabaseViewIdPB.create()..value = viewId;
    return DatabaseEventGetPrimaryField(payload).send();
  }

  Future<Either<FieldPB, FlowyError>> createBefore({
    FieldType fieldType = FieldType.RichText,
    String? fieldName,
    Uint8List? typeOptionData,
  }) {
    return createField(
      viewId: viewId,
      fieldType: fieldType,
      fieldName: fieldName,
      typeOptionData: typeOptionData,
      position: OrderObjectPositionPB(
        position: OrderObjectPositionTypePB.Before,
        objectId: fieldId,
      ),
    );
  }

  Future<Either<FieldPB, FlowyError>> createAfter({
    FieldType fieldType = FieldType.RichText,
    String? fieldName,
    Uint8List? typeOptionData,
  }) {
    return createField(
      viewId: viewId,
      fieldType: fieldType,
      fieldName: fieldName,
      typeOptionData: typeOptionData,
      position: OrderObjectPositionPB(
        position: OrderObjectPositionTypePB.After,
        objectId: fieldId,
      ),
    );
  }

  Future<Either<Unit, FlowyError>> updateType({
    required FieldType fieldType,
  }) =>
      updateFieldType(
        viewId: viewId,
        fieldId: fieldId,
        fieldType: fieldType,
      );

  Future<Either<Unit, FlowyError>> delete() =>
      deleteField(viewId: viewId, fieldId: fieldId);

  Future<Either<Unit, FlowyError>> duplicate() =>
      duplicateField(viewId: viewId, fieldId: fieldId);
}
