import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';
import 'package:flowy_sdk/log.dart';

import 'type_option_context.dart';

class TypeOptionDataController {
  final String gridId;
  final IFieldTypeOptionLoader loader;
  late FieldTypeOptionDataPB _data;
  final PublishNotifier<FieldPB> _fieldNotifier = PublishNotifier();

  TypeOptionDataController({
    required this.gridId,
    required this.loader,
    FieldPB? field,
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

  FieldPB get field {
    return _data.field_2;
  }

  set field(FieldPB field) {
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
    FieldPB? newField,
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

  void Function() addFieldListener(void Function(FieldPB) callback) {
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
