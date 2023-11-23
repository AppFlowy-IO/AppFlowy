import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

import '../field_service.dart';
import 'type_option_context.dart';

class TypeOptionController {
  late TypeOptionPB _typeOption;
  final FieldTypeOptionLoader loader;
  final PublishNotifier<FieldPB> _fieldNotifier = PublishNotifier();

  /// Returns a [TypeOptionController] used to modify the specified
  /// [FieldPB]'s data
  ///
  /// Should call [reloadTypeOption] if the passed-in [FieldInfo]
  /// is null
  ///
  TypeOptionController({
    required this.loader,
    required FieldPB field,
  }) {
    _typeOption = TypeOptionPB.create()
      ..viewId = loader.viewId
      ..field_2 = field;
  }

  Future<Either<TypeOptionPB, FlowyError>> reloadTypeOption() async {
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

    FieldBackendService(viewId: loader.viewId, fieldId: field.id)
        .updateField(name: name);
  }

  set typeOptionData(List<int> typeOptionData) {
    _typeOption = _typeOption.rebuild((rebuildData) {
      if (typeOptionData.isNotEmpty) {
        rebuildData.typeOptionData = typeOptionData;
      }
    });

    FieldBackendService.updateFieldTypeOption(
      viewId: loader.viewId,
      fieldId: field.id,
      typeOptionData: typeOptionData,
    );
  }

  Future<void> switchToField(FieldType newFieldType) async {
    final payload = UpdateFieldTypePayloadPB.create()
      ..viewId = loader.viewId
      ..fieldId = field.id
      ..fieldType = newFieldType;

    final result = await DatabaseEventUpdateFieldType(payload).send();
    await result.fold(
      (_) {
        // Should load the type-option data after switching to a new field.
        // After loading the type-option data, the editor widget that uses
        // the type-option data will be rebuild.
        reloadTypeOption();
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

  void dispose() {
    _fieldNotifier.dispose();
  }
}
