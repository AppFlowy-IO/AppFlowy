import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:appflowy_backend/log.dart';

import 'type_option_context.dart';

class TypeOptionDataController {
  final String databaseId;
  final IFieldTypeOptionLoader loader;
  late TypeOptionPB _typeOptiondata;
  final PublishNotifier<FieldPB> _fieldNotifier = PublishNotifier();

  /// Returns a [TypeOptionDataController] used to modify the specified
  /// [FieldPB]'s data
  ///
  /// Should call [loadTypeOptionData] if the passed-in [FieldInfo]
  /// is null
  ///
  TypeOptionDataController({
    required this.databaseId,
    required this.loader,
    FieldInfo? fieldInfo,
  }) {
    if (fieldInfo != null) {
      _typeOptiondata = TypeOptionPB.create()
        ..databaseId = databaseId
        ..field_2 = fieldInfo.field;
    }
  }

  Future<Either<TypeOptionPB, FlowyError>> loadTypeOptionData() async {
    final result = await loader.load();
    return result.fold(
      (data) {
        data.freeze();
        _typeOptiondata = data;
        _fieldNotifier.value = data.field_2;
        return left(data);
      },
      (err) {
        Log.error(err);
        return right(err);
      },
    );
  }

  FieldPB get field {
    return _typeOptiondata.field_2;
  }

  T getTypeOption<T>(TypeOptionDataParser<T> parser) {
    return parser.fromBuffer(_typeOptiondata.typeOptionData);
  }

  set fieldName(String name) {
    _typeOptiondata = _typeOptiondata.rebuild((rebuildData) {
      rebuildData.field_2 = rebuildData.field_2.rebuild((rebuildField) {
        rebuildField.name = name;
      });
    });

    _fieldNotifier.value = _typeOptiondata.field_2;

    FieldService(databaseId: databaseId, fieldId: field.id)
        .updateField(name: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _typeOptiondata = _typeOptiondata.rebuild((rebuildData) {
      if (typeOptionData.isNotEmpty) {
        rebuildData.typeOptionData = typeOptionData;
      }
    });

    FieldService.updateFieldTypeOption(
      databaseId: databaseId,
      fieldId: field.id,
      typeOptionData: typeOptionData,
    );
  }

  Future<void> switchToField(FieldType newFieldType) async {
    final result = await loader.switchToField(field.id, newFieldType);
    await result.fold(
      (_) {
        // Should load the type-option data after switching to a new field.
        // After loading the type-option data, the editor widget that uses
        // the type-option data will be rebuild.
        loadTypeOptionData();
      },
      (err) => Future(() => Log.error(err)),
    );
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
