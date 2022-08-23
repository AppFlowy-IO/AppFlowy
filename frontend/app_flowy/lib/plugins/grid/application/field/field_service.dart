import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'field_service.freezed.dart';

/// FieldService consists of lots of event functions. We define the events in the backend(Rust),
/// you can find the corresponding event implementation in event_map.rs of the corresponding crate.
///
/// You could check out the rust-lib/flowy-grid/event_map.rs for more information.
class FieldService {
  final String gridId;
  final String fieldId;

  FieldService({required this.gridId, required this.fieldId});

  Future<Either<Unit, FlowyError>> moveField(int fromIndex, int toIndex) {
    final payload = MoveFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return GridEventMoveField(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateField({
    String? name,
    FieldType? fieldType,
    bool? frozen,
    bool? visibility,
    double? width,
    List<int>? typeOptionData,
  }) {
    var payload = FieldChangesetPayloadPB.create()
      ..gridId = gridId
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

    if (typeOptionData != null) {
      payload.typeOptionData = typeOptionData;
    }

    return GridEventUpdateField(payload).send();
  }

  // Create the field if it does not exist. Otherwise, update the field.
  static Future<Either<Unit, FlowyError>> insertField({
    required String gridId,
    required FieldPB field,
    List<int>? typeOptionData,
    String? startFieldId,
  }) {
    var payload = InsertFieldPayloadPB.create()
      ..gridId = gridId
      ..field_2 = field
      ..typeOptionData = typeOptionData ?? [];

    if (startFieldId != null) {
      payload.startFieldId = startFieldId;
    }

    return GridEventInsertField(payload).send();
  }

  static Future<Either<Unit, FlowyError>> updateFieldTypeOption({
    required String gridId,
    required String fieldId,
    required List<int> typeOptionData,
  }) {
    var payload = UpdateFieldTypeOptionPayloadPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..typeOptionData = typeOptionData;

    return GridEventUpdateFieldTypeOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteField() {
    final payload = DeleteFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventDeleteField(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateField() {
    final payload = DuplicateFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventDuplicateField(payload).send();
  }

  Future<Either<FieldTypeOptionDataPB, FlowyError>> getFieldTypeOptionData({
    required FieldType fieldType,
  }) {
    final payload = FieldTypeOptionIdPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fieldType = fieldType;
    return GridEventGetFieldTypeOption(payload).send().then((result) {
      return result.fold(
        (data) => left(data),
        (err) => right(err),
      );
    });
  }
}

@freezed
class GridFieldCellContext with _$GridFieldCellContext {
  const factory GridFieldCellContext({
    required String gridId,
    required FieldPB field,
  }) = _GridFieldCellContext;
}
