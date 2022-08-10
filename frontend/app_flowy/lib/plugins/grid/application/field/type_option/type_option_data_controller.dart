import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';
import 'package:flowy_sdk/log.dart';

abstract class TypeOptionDataParser<T> {
  T fromBuffer(List<int> buffer);
}

class TypeOptionContext<T extends GeneratedMessage> {
  T? _typeOptionObject;
  final TypeOptionDataParser<T> dataParser;
  final TypeOptionDataController _dataController;

  TypeOptionContext({
    required this.dataParser,
    required TypeOptionDataController dataController,
  }) : _dataController = dataController;

  String get gridId => _dataController.gridId;

  Future<void> loadTypeOptionData({
    required void Function(T) onCompleted,
    required void Function(FlowyError) onError,
  }) async {
    await _dataController.loadTypeOptionData().then((result) {
      result.fold((l) => null, (err) => onError(err));
    });

    onCompleted(typeOption);
  }

  T get typeOption {
    if (_typeOptionObject != null) {
      return _typeOptionObject!;
    }

    final T object = _dataController.getTypeOption(dataParser);
    _typeOptionObject = object;
    return object;
  }

  set typeOption(T typeOption) {
    _dataController.typeOptionData = typeOption.writeToBuffer();
    _typeOptionObject = typeOption;
  }
}

abstract class TypeOptionFieldDelegate {
  void onFieldChanged(void Function(String) callback);
  void dispose();
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
  final IFieldTypeOptionLoader loader;
  late FieldTypeOptionDataPB _data;
  final PublishNotifier<GridFieldPB> _fieldNotifier = PublishNotifier();

  TypeOptionDataController({
    required this.gridId,
    required this.loader,
    GridFieldPB? field,
  }) {
    if (field != null) {
      _data = FieldTypeOptionDataPB.create()
        ..gridId = gridId
        ..field_2 = field;
    }
  }

  Future<Either<Unit, FlowyError>> loadTypeOptionData() async {
    final result = await loader.load();
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

  GridFieldPB get field {
    return _data.field_2;
  }

  set field(GridFieldPB field) {
    _updateData(newField: field);
  }

  T getTypeOption<T>(TypeOptionDataParser<T> parser) {
    return parser.fromBuffer(_data.typeOptionData);
  }

  set fieldName(String name) {
    _updateData(newName: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _updateData(newTypeOptionData: typeOptionData);
  }

  void _updateData({
    String? newName,
    GridFieldPB? newField,
    List<int>? newTypeOptionData,
  }) {
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
      typeOptionData: _data.typeOptionData,
    );
  }

  Future<void> switchToField(FieldType newFieldType) {
    return loader.switchToField(field.id, newFieldType).then((result) {
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
