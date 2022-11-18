import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
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
  late TypeOptionPB _data;
  final PublishNotifier<FieldPB> _fieldNotifier = PublishNotifier();

  /// Returns a [TypeOptionDataController] used to modify the specified
  /// [FieldPB]'s data
  ///
  /// Should call [loadTypeOptionData] if the passed-in [GridFieldContext]
  /// is null
  ///
  TypeOptionDataController({
    required this.gridId,
    required this.loader,
    GridFieldContext? fieldContext,
  }) {
    if (fieldContext != null) {
      _data = TypeOptionPB.create()
        ..gridId = gridId
        ..field_2 = fieldContext.field;
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

  T getTypeOption<T>(TypeOptionDataParser<T> parser) {
    return parser.fromBuffer(_data.typeOptionData);
  }

  set fieldName(String name) {
    _data = _data.rebuild((rebuildData) {
      rebuildData.field_2 = rebuildData.field_2.rebuild((rebuildField) {
        rebuildField.name = name;
      });
    });

    _fieldNotifier.value = _data.field_2;

    FieldService(gridId: gridId, fieldId: field.id).updateField(name: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _data = _data.rebuild((rebuildData) {
      if (typeOptionData.isNotEmpty) {
        rebuildData.typeOptionData = typeOptionData;
      }
    });

    FieldService.updateFieldTypeOption(
      gridId: gridId,
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
