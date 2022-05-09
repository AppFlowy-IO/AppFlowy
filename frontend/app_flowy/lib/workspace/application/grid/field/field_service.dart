import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'field_service.freezed.dart';

class FieldService {
  final String gridId;
  final String fieldId;

  FieldService({required this.gridId, required this.fieldId});

  Future<Either<EditFieldContext, FlowyError>> switchToField(FieldType fieldType) {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return GridEventSwitchToField(payload).send();
  }

  Future<Either<EditFieldContext, FlowyError>> getEditFieldContext(FieldType fieldType) {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return GridEventGetEditFieldContext(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveField(int fromIndex, int toIndex) {
    final payload = MoveItemPayload.create()
      ..gridId = gridId
      ..itemId = fieldId
      ..ty = MoveItemType.MoveField
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return GridEventMoveItem(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateField({
    String? name,
    FieldType? fieldType,
    bool? frozen,
    bool? visibility,
    double? width,
    List<int>? typeOptionData,
  }) {
    var payload = FieldChangesetPayload.create()
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
    required Field field,
    List<int>? typeOptionData,
    String? startFieldId,
  }) {
    var payload = InsertFieldPayload.create()
      ..gridId = gridId
      ..field_2 = field
      ..typeOptionData = typeOptionData ?? [];

    if (startFieldId != null) {
      payload.startFieldId = startFieldId;
    }

    return GridEventInsertField(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteField() {
    final payload = FieldIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventDeleteField(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateField() {
    final payload = FieldIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventDuplicateField(payload).send();
  }

  Future<Either<List<int>, FlowyError>> getTypeOptionData({
    required FieldType fieldType,
  }) {
    final payload = EditFieldPayload.create()
      ..fieldId = fieldId
      ..fieldType = fieldType;
    return GridEventGetFieldTypeOption(payload).send().then((result) {
      return result.fold(
        (data) => left(data.typeOptionData),
        (err) => right(err),
      );
    });
  }
}

@freezed
class GridFieldCellContext with _$GridFieldCellContext {
  const factory GridFieldCellContext({
    required String gridId,
    required Field field,
  }) = _GridFieldCellContext;
}

abstract class EditFieldContextLoader {
  Future<Either<EditFieldContext, FlowyError>> load();

  Future<Either<EditFieldContext, FlowyError>> switchToField(String fieldId, FieldType fieldType);
}

class NewFieldContextLoader extends EditFieldContextLoader {
  final String gridId;
  NewFieldContextLoader({
    required this.gridId,
  });

  @override
  Future<Either<EditFieldContext, FlowyError>> load() {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldType = FieldType.RichText;

    return GridEventGetEditFieldContext(payload).send();
  }

  @override
  Future<Either<EditFieldContext, FlowyError>> switchToField(String fieldId, FieldType fieldType) {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldType = fieldType;

    return GridEventGetEditFieldContext(payload).send();
  }
}

class FieldContextLoaderAdaptor extends EditFieldContextLoader {
  final String gridId;
  final Field field;

  FieldContextLoaderAdaptor({
    required this.gridId,
    required this.field,
  });

  @override
  Future<Either<EditFieldContext, FlowyError>> load() {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldId = field.id
      ..fieldType = field.fieldType;

    return GridEventGetEditFieldContext(payload).send();
  }

  @override
  Future<Either<EditFieldContext, FlowyError>> switchToField(String fieldId, FieldType fieldType) async {
    final fieldService = FieldService(gridId: gridId, fieldId: fieldId);
    return fieldService.switchToField(fieldType);
  }
}
