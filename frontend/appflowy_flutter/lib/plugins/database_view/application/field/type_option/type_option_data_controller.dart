import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:appflowy_backend/log.dart';

import '../field_service.dart';
import 'type_option_context.dart';

class TypeOptionController {
  final String viewId;
  late TypeOptionPB _typeOption;
  final IFieldTypeOptionLoader loader;
  final PublishNotifier<FieldPB> _fieldNotifier = PublishNotifier();

  /// Returns a [TypeOptionController] used to modify the specified
  /// [FieldPB]'s data
  ///
  /// Should call [loadTypeOptionData] if the passed-in [FieldInfo]
  /// is null
  ///
  TypeOptionController({
    required this.viewId,
    required this.loader,
    FieldInfo? fieldInfo,
  }) {
    if (fieldInfo != null) {
      _typeOption = TypeOptionPB.create()
        ..viewId = viewId
        ..field_2 = fieldInfo.field;
    }
  }

  Future<Either<TypeOptionPB, FlowyError>> loadTypeOptionData() async {
    final result = await loader.load();
    return result.fold(
      (data) {
        data.freeze();
        _typeOption = data;
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
    return _typeOption.field_2;
  }

  T getTypeOption<T>(TypeOptionParser<T> parser) {
    return parser.fromBuffer(_typeOption.typeOptionData);
  }

  set fieldName(String name) {
    _typeOption = _typeOption.rebuild((rebuildData) {
      rebuildData.field_2 = rebuildData.field_2.rebuild((rebuildField) {
        rebuildField.name = name;
      });
    });

    _fieldNotifier.value = _typeOption.field_2;

    FieldBackendService(viewId: viewId, fieldId: field.id)
        .updateField(name: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _typeOption = _typeOption.rebuild((rebuildData) {
      if (typeOptionData.isNotEmpty) {
        rebuildData.typeOptionData = typeOptionData;
      }
    });

    FieldBackendService.updateFieldTypeOption(
      viewId: viewId,
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
