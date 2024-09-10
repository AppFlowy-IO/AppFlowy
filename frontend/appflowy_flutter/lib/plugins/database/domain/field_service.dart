import 'dart:typed_data';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// FieldService provides many field-related interfaces event functions. Check out
/// `rust-lib/flowy-database/event_map.rs` for a list of events and their
/// implementations.
class FieldBackendService {
  FieldBackendService({required this.viewId, required this.fieldId});

  final String viewId;
  final String fieldId;

  /// Create a field in a database view. The position will only be applicable
  /// in this view; for other views it will be appended to the end
  static Future<FlowyResult<FieldPB, FlowyError>> createField({
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
  static Future<FlowyResult<void, FlowyError>> moveField({
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
  static Future<FlowyResult<void, FlowyError>> deleteField({
    required String viewId,
    required String fieldId,
  }) {
    final payload = DeleteFieldPayloadPB(
      viewId: viewId,
      fieldId: fieldId,
    );

    return DatabaseEventDeleteField(payload).send();
  }

  // Clear all data of all cells in a Field
  static Future<FlowyResult<void, FlowyError>> clearField({
    required String viewId,
    required String fieldId,
  }) {
    final payload = ClearFieldPayloadPB(
      viewId: viewId,
      fieldId: fieldId,
    );

    return DatabaseEventClearField(payload).send();
  }

  /// Duplicate a field
  static Future<FlowyResult<void, FlowyError>> duplicateField({
    required String viewId,
    required String fieldId,
  }) {
    final payload = DuplicateFieldPayloadPB(viewId: viewId, fieldId: fieldId);

    return DatabaseEventDuplicateField(payload).send();
  }

  /// Update a field's properties
  Future<FlowyResult<void, FlowyError>> updateField({
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
  static Future<FlowyResult<void, FlowyError>> updateFieldType({
    required String viewId,
    required String fieldId,
    required FieldType fieldType,
    String? fieldName,
  }) {
    final payload = UpdateFieldTypePayloadPB()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    // Only set if fieldName is not null
    if (fieldName != null) {
      payload.fieldName = fieldName;
    }

    return DatabaseEventUpdateFieldType(payload).send();
  }

  /// Update a field's type option data
  static Future<FlowyResult<void, FlowyError>> updateFieldTypeOption({
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
  static Future<FlowyResult<FieldPB, FlowyError>> getPrimaryField({
    required String viewId,
  }) {
    final payload = DatabaseViewIdPB.create()..value = viewId;
    return DatabaseEventGetPrimaryField(payload).send();
  }

  Future<FlowyResult<FieldPB, FlowyError>> createBefore({
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

  Future<FlowyResult<FieldPB, FlowyError>> createAfter({
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

  Future<FlowyResult<void, FlowyError>> updateType({
    required FieldType fieldType,
    String? fieldName,
  }) =>
      updateFieldType(
        viewId: viewId,
        fieldId: fieldId,
        fieldType: fieldType,
        fieldName: fieldName,
      );

  Future<FlowyResult<void, FlowyError>> delete() =>
      deleteField(viewId: viewId, fieldId: fieldId);

  Future<FlowyResult<void, FlowyError>> duplicate() =>
      duplicateField(viewId: viewId, fieldId: fieldId);
}
