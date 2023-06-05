import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checkbox_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checklist_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database/multi_select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/number_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/single_select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/text_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/url_type_option.pb.dart';
import 'package:protobuf/protobuf.dart';

import 'type_option_data_controller.dart';

abstract class TypeOptionParser<T> {
  T fromBuffer(final List<int> buffer);
}

// Number
typedef NumberTypeOptionContext = TypeOptionContext<NumberTypeOptionPB>;

class NumberTypeOptionWidgetDataParser
    extends TypeOptionParser<NumberTypeOptionPB> {
  @override
  NumberTypeOptionPB fromBuffer(final List<int> buffer) {
    return NumberTypeOptionPB.fromBuffer(buffer);
  }
}

// RichText
typedef RichTextTypeOptionContext = TypeOptionContext<RichTextTypeOptionPB>;

class RichTextTypeOptionWidgetDataParser
    extends TypeOptionParser<RichTextTypeOptionPB> {
  @override
  RichTextTypeOptionPB fromBuffer(final List<int> buffer) {
    return RichTextTypeOptionPB.fromBuffer(buffer);
  }
}

// Checkbox
typedef CheckboxTypeOptionContext = TypeOptionContext<CheckboxTypeOptionPB>;

class CheckboxTypeOptionWidgetDataParser
    extends TypeOptionParser<CheckboxTypeOptionPB> {
  @override
  CheckboxTypeOptionPB fromBuffer(final List<int> buffer) {
    return CheckboxTypeOptionPB.fromBuffer(buffer);
  }
}

// URL
typedef URLTypeOptionContext = TypeOptionContext<URLTypeOptionPB>;

class URLTypeOptionWidgetDataParser extends TypeOptionParser<URLTypeOptionPB> {
  @override
  URLTypeOptionPB fromBuffer(final List<int> buffer) {
    return URLTypeOptionPB.fromBuffer(buffer);
  }
}

// Date
typedef DateTypeOptionContext = TypeOptionContext<DateTypeOptionPB>;

class DateTypeOptionDataParser extends TypeOptionParser<DateTypeOptionPB> {
  @override
  DateTypeOptionPB fromBuffer(final List<int> buffer) {
    return DateTypeOptionPB.fromBuffer(buffer);
  }
}

// SingleSelect
typedef SingleSelectTypeOptionContext
    = TypeOptionContext<SingleSelectTypeOptionPB>;

class SingleSelectTypeOptionWidgetDataParser
    extends TypeOptionParser<SingleSelectTypeOptionPB> {
  @override
  SingleSelectTypeOptionPB fromBuffer(final List<int> buffer) {
    return SingleSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef MultiSelectTypeOptionContext
    = TypeOptionContext<MultiSelectTypeOptionPB>;

class MultiSelectTypeOptionWidgetDataParser
    extends TypeOptionParser<MultiSelectTypeOptionPB> {
  @override
  MultiSelectTypeOptionPB fromBuffer(final List<int> buffer) {
    return MultiSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef ChecklistTypeOptionContext = TypeOptionContext<ChecklistTypeOptionPB>;

class ChecklistTypeOptionWidgetDataParser
    extends TypeOptionParser<ChecklistTypeOptionPB> {
  @override
  ChecklistTypeOptionPB fromBuffer(final List<int> buffer) {
    return ChecklistTypeOptionPB.fromBuffer(buffer);
  }
}

class TypeOptionContext<T extends GeneratedMessage> {
  T? _typeOptionObject;
  final TypeOptionParser<T> dataParser;
  final TypeOptionController _dataController;

  TypeOptionContext({
    required this.dataParser,
    required final TypeOptionController dataController,
  }) : _dataController = dataController;

  String get viewId => _dataController.viewId;

  String get fieldId => _dataController.field.id;

  Future<T> loadTypeOptionData({
    final void Function(T)? onCompleted,
    required final void Function(FlowyError) onError,
  }) async {
    await _dataController.loadTypeOptionData().then((final result) {
      result.fold((final l) => null, (final err) => onError(err));
    });

    onCompleted?.call(typeOption);
    return typeOption;
  }

  T get typeOption {
    if (_typeOptionObject != null) {
      return _typeOptionObject!;
    }

    final T object = _dataController.getTypeOption(dataParser);
    _typeOptionObject = object;
    return object;
  }

  set typeOption(final T typeOption) {
    _dataController.typeOptionData = typeOption.writeToBuffer();
    _typeOptionObject = typeOption;
  }
}

abstract class TypeOptionFieldDelegate {
  void onFieldChanged(final void Function(String) callback);
  void dispose();
}

abstract class IFieldTypeOptionLoader {
  String get viewId;
  Future<Either<TypeOptionPB, FlowyError>> load();

  Future<Either<Unit, FlowyError>> switchToField(
    final String fieldId,
    final FieldType fieldType,
  ) {
    final payload = UpdateFieldTypePayloadPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return DatabaseEventUpdateFieldType(payload).send();
  }
}

/// Uses when creating a new field
class NewFieldTypeOptionLoader extends IFieldTypeOptionLoader {
  TypeOptionPB? fieldTypeOption;

  @override
  final String viewId;
  NewFieldTypeOptionLoader({
    required this.viewId,
  });

  /// Creates the field type option if the fieldTypeOption is null.
  /// Otherwise, it loads the type option data from the backend.
  @override
  Future<Either<TypeOptionPB, FlowyError>> load() {
    if (fieldTypeOption != null) {
      final payload = TypeOptionPathPB.create()
        ..viewId = viewId
        ..fieldId = fieldTypeOption!.field_2.id
        ..fieldType = fieldTypeOption!.field_2.fieldType;

      return DatabaseEventGetTypeOption(payload).send();
    } else {
      final payload = CreateFieldPayloadPB.create()
        ..viewId = viewId
        ..fieldType = FieldType.RichText;

      return DatabaseEventCreateTypeOption(payload).send().then((final result) {
        return result.fold(
          (final newFieldTypeOption) {
            fieldTypeOption = newFieldTypeOption;
            return left(newFieldTypeOption);
          },
          (final err) => right(err),
        );
      });
    }
  }
}

/// Uses when editing a existing field
class FieldTypeOptionLoader extends IFieldTypeOptionLoader {
  @override
  final String viewId;
  final FieldPB field;

  FieldTypeOptionLoader({
    required this.viewId,
    required this.field,
  });

  @override
  Future<Either<TypeOptionPB, FlowyError>> load() {
    final payload = TypeOptionPathPB.create()
      ..viewId = viewId
      ..fieldId = field.id
      ..fieldType = field.fieldType;

    return DatabaseEventGetTypeOption(payload).send();
  }
}
