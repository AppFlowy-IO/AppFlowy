import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';
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
    final payload = MoveItemPayloadPB.create()
      ..gridId = gridId
      ..itemId = fieldId
      ..ty = MoveItemTypePB.MoveField
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
    required GridFieldPB field,
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
    final payload = GridFieldTypeOptionIdPB.create()
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
    required GridFieldPB field,
  }) = _GridFieldCellContext;
}

abstract class IFieldTypeOptionLoader {
  String get gridId;
  Future<Either<FieldTypeOptionDataPB, FlowyError>> load();

  Future<Either<FieldTypeOptionDataPB, FlowyError>> switchToField(
      String fieldId, FieldType fieldType) {
    final payload = EditFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return GridEventSwitchToField(payload).send();
  }
}

class NewFieldTypeOptionLoader extends IFieldTypeOptionLoader {
  @override
  final String gridId;
  NewFieldTypeOptionLoader({
    required this.gridId,
  });

  @override
  Future<Either<FieldTypeOptionDataPB, FlowyError>> load() {
    final payload = CreateFieldPayloadPB.create()
      ..gridId = gridId
      ..fieldType = FieldType.RichText;

    return GridEventCreateFieldTypeOption(payload).send();
  }
}

class FieldTypeOptionLoader extends IFieldTypeOptionLoader {
  @override
  final String gridId;
  final GridFieldPB field;

  FieldTypeOptionLoader({
    required this.gridId,
    required this.field,
  });

  @override
  Future<Either<FieldTypeOptionDataPB, FlowyError>> load() {
    final payload = GridFieldTypeOptionIdPB.create()
      ..gridId = gridId
      ..fieldId = field.id
      ..fieldType = field.fieldType;

    return GridEventGetFieldTypeOption(payload).send();
  }
}

class TypeOptionDataController {
  final String gridId;
  final IFieldTypeOptionLoader _loader;

  late FieldTypeOptionDataPB _data;
  final PublishNotifier<GridFieldPB> _fieldNotifier = PublishNotifier();

  TypeOptionDataController({
    required this.gridId,
    required IFieldTypeOptionLoader loader,
  }) : _loader = loader;

  Future<Either<Unit, FlowyError>> loadTypeOptionData() async {
    final result = await _loader.load();
    return result.fold(
      (data) {
        data.freeze();
        _data = data;
        _fieldNotifier.value = data.field_2;
        return left(unit);
      },
      (err) {
        Log.error(err);
        return right(err);
      },
    );
  }

  GridFieldPB get field => _data.field_2;

  set field(GridFieldPB field) {
    _updateData(newField: field);
  }

  List<int> get typeOptionData => _data.typeOptionData;

  set fieldName(String name) {
    _updateData(newName: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _updateData(newTypeOptionData: typeOptionData);
  }

  void _updateData(
      {String? newName, GridFieldPB? newField, List<int>? newTypeOptionData}) {
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

    _fieldNotifier.value = _data.field_2;

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

  void Function() addFieldListener(void Function(GridFieldPB) callback) {
    listener() {
      callback(field);
    }

    _fieldNotifier.addListener(listener);
    return listener;
  }

  void removeFieldListener(void Function() listener) {
    _fieldNotifier.removeListener(listener);
  }
}
