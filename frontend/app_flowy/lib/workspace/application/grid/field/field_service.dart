import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/field.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';
part 'field_service.freezed.dart';

class FieldService {
  final String gridId;
  final String fieldId;

  FieldService({required this.gridId, required this.fieldId});

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

  static Future<Either<Unit, FlowyError>> updateFieldTypeOption({
    required String gridId,
    required String fieldId,
    required List<int> typeOptionData,
  }) {
    var payload = UpdateFieldTypeOptionPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..typeOptionData = typeOptionData;

    return GridEventUpdateFieldTypeOption(payload).send();
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

  Future<Either<FieldTypeOptionData, FlowyError>> getFieldTypeOptionData({
    required FieldType fieldType,
  }) {
    final payload = EditFieldPayload.create()
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
    required Field field,
  }) = _GridFieldCellContext;
}

abstract class IFieldContextLoader {
  String get gridId;
  Future<Either<FieldTypeOptionData, FlowyError>> load();

  Future<Either<FieldTypeOptionData, FlowyError>> switchToField(String fieldId, FieldType fieldType) {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return GridEventSwitchToField(payload).send();
  }
}

class NewFieldContextLoader extends IFieldContextLoader {
  @override
  final String gridId;
  NewFieldContextLoader({
    required this.gridId,
  });

  @override
  Future<Either<FieldTypeOptionData, FlowyError>> load() {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldType = FieldType.RichText;

    return GridEventCreateFieldTypeOption(payload).send();
  }
}

class FieldContextLoader extends IFieldContextLoader {
  @override
  final String gridId;
  final Field field;

  FieldContextLoader({
    required this.gridId,
    required this.field,
  });

  @override
  Future<Either<FieldTypeOptionData, FlowyError>> load() {
    final payload = EditFieldPayload.create()
      ..gridId = gridId
      ..fieldId = field.id
      ..fieldType = field.fieldType;

    return GridEventGetFieldTypeOption(payload).send();
  }
}

class GridFieldContext {
  final String gridId;
  final IFieldContextLoader _loader;

  late FieldTypeOptionData _data;
  ValueNotifier<Field>? _fieldNotifier;

  GridFieldContext({
    required this.gridId,
    required IFieldContextLoader loader,
  }) : _loader = loader;

  Future<Either<Unit, FlowyError>> loadData() async {
    final result = await _loader.load();
    return result.fold(
      (data) {
        data.freeze();
        _data = data;

        if (_fieldNotifier == null) {
          _fieldNotifier = ValueNotifier(data.field_2);
        } else {
          _fieldNotifier?.value = data.field_2;
        }

        return left(unit);
      },
      (err) {
        Log.error(err);
        return right(err);
      },
    );
  }

  Field get field => _data.field_2;

  set field(Field field) {
    _updateData(newField: field);
  }

  List<int> get typeOptionData => _data.typeOptionData;

  set fieldName(String name) {
    _updateData(newName: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _updateData(newTypeOptionData: typeOptionData);
  }

  void _updateData({String? newName, Field? newField, List<int>? newTypeOptionData}) {
    _data = _data.rebuild((rebuildData) {
      if (newName != null) {
        rebuildData.field_2 = rebuildData.field_2.rebuild((rebuildField) {
          rebuildField.name = newName;
        });
      }

      if (newField != null) {
        rebuildData.field_2 = newField;
      }

      if (newTypeOptionData != null) {
        rebuildData.typeOptionData = newTypeOptionData;
      }
    });

    if (_data.field_2 != _fieldNotifier?.value) {
      _fieldNotifier?.value = _data.field_2;
    }

    FieldService.insertField(
      gridId: gridId,
      field: field,
      typeOptionData: typeOptionData,
    );
  }

  Future<void> switchToField(FieldType newFieldType) {
    return _loader.switchToField(field.id, newFieldType).then((result) {
      return result.fold(
        (fieldTypeOptionData) {
          _updateData(
            newField: fieldTypeOptionData.field_2,
            newTypeOptionData: fieldTypeOptionData.typeOptionData,
          );
        },
        (err) {
          Log.error(err);
        },
      );
    });
  }

  void Function() addFieldListener(void Function(Field) callback) {
    listener() {
      callback(field);
    }

    _fieldNotifier?.addListener(listener);
    return listener;
  }

  void removeFieldListener(void Function() listener) {
    _fieldNotifier?.removeListener(listener);
  }
}
