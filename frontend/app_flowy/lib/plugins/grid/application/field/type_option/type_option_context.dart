import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/checkbox_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/checklist_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/multi_select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/number_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/single_select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/text_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/url_type_option.pb.dart';
import 'package:protobuf/protobuf.dart';

import 'type_option_data_controller.dart';

abstract class TypeOptionDataParser<T> {
  T fromBuffer(List<int> buffer);
}

// Number
typedef NumberTypeOptionContext = TypeOptionContext<NumberTypeOptionPB>;

class NumberTypeOptionWidgetDataParser
    extends TypeOptionDataParser<NumberTypeOptionPB> {
  @override
  NumberTypeOptionPB fromBuffer(List<int> buffer) {
    return NumberTypeOptionPB.fromBuffer(buffer);
  }
}

// RichText
typedef RichTextTypeOptionContext = TypeOptionContext<RichTextTypeOptionPB>;

class RichTextTypeOptionWidgetDataParser
    extends TypeOptionDataParser<RichTextTypeOptionPB> {
  @override
  RichTextTypeOptionPB fromBuffer(List<int> buffer) {
    return RichTextTypeOptionPB.fromBuffer(buffer);
  }
}

// Checkbox
typedef CheckboxTypeOptionContext = TypeOptionContext<CheckboxTypeOptionPB>;

class CheckboxTypeOptionWidgetDataParser
    extends TypeOptionDataParser<CheckboxTypeOptionPB> {
  @override
  CheckboxTypeOptionPB fromBuffer(List<int> buffer) {
    return CheckboxTypeOptionPB.fromBuffer(buffer);
  }
}

// URL
typedef URLTypeOptionContext = TypeOptionContext<URLTypeOptionPB>;

class URLTypeOptionWidgetDataParser
    extends TypeOptionDataParser<URLTypeOptionPB> {
  @override
  URLTypeOptionPB fromBuffer(List<int> buffer) {
    return URLTypeOptionPB.fromBuffer(buffer);
  }
}

// Date
typedef DateTypeOptionContext = TypeOptionContext<DateTypeOptionPB>;

class DateTypeOptionDataParser extends TypeOptionDataParser<DateTypeOptionPB> {
  @override
  DateTypeOptionPB fromBuffer(List<int> buffer) {
    return DateTypeOptionPB.fromBuffer(buffer);
  }
}

// SingleSelect
typedef SingleSelectTypeOptionContext
    = TypeOptionContext<SingleSelectTypeOptionPB>;

class SingleSelectTypeOptionWidgetDataParser
    extends TypeOptionDataParser<SingleSelectTypeOptionPB> {
  @override
  SingleSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return SingleSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef MultiSelectTypeOptionContext
    = TypeOptionContext<MultiSelectTypeOptionPB>;

class MultiSelectTypeOptionWidgetDataParser
    extends TypeOptionDataParser<MultiSelectTypeOptionPB> {
  @override
  MultiSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return MultiSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef ChecklistTypeOptionContext = TypeOptionContext<ChecklistTypeOptionPB>;

class ChecklistTypeOptionWidgetDataParser
    extends TypeOptionDataParser<ChecklistTypeOptionPB> {
  @override
  ChecklistTypeOptionPB fromBuffer(List<int> buffer) {
    return ChecklistTypeOptionPB.fromBuffer(buffer);
  }
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

  String get fieldId => _dataController.field.id;

  Future<T> loadTypeOptionData({
    void Function(T)? onCompleted,
    required void Function(FlowyError) onError,
  }) async {
    await _dataController.loadTypeOptionData().then((result) {
      result.fold((l) => null, (err) => onError(err));
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
  Future<Either<TypeOptionPB, FlowyError>> load();

  Future<Either<Unit, FlowyError>> switchToField(
      String fieldId, FieldType fieldType) {
    final payload = EditFieldChangesetPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..fieldType = fieldType;

    return GridEventSwitchToField(payload).send();
  }
}

/// Uses when creating a new field
class NewFieldTypeOptionLoader extends IFieldTypeOptionLoader {
  TypeOptionPB? fieldTypeOption;

  @override
  final String gridId;
  NewFieldTypeOptionLoader({
    required this.gridId,
  });

  /// Creates the field type option if the fieldTypeOption is null.
  /// Otherwise, it loads the type option data from the backend.
  @override
  Future<Either<TypeOptionPB, FlowyError>> load() {
    if (fieldTypeOption != null) {
      final payload = TypeOptionPathPB.create()
        ..gridId = gridId
        ..fieldId = fieldTypeOption!.field_2.id
        ..fieldType = fieldTypeOption!.field_2.fieldType;

      return GridEventGetFieldTypeOption(payload).send();
    } else {
      final payload = CreateFieldPayloadPB.create()
        ..gridId = gridId
        ..fieldType = FieldType.RichText;

      return GridEventCreateFieldTypeOption(payload).send().then((result) {
        return result.fold(
          (newFieldTypeOption) {
            fieldTypeOption = newFieldTypeOption;
            return left(newFieldTypeOption);
          },
          (err) => right(err),
        );
      });
    }
  }
}

/// Uses when editing a existing field
class FieldTypeOptionLoader extends IFieldTypeOptionLoader {
  @override
  final String gridId;
  final FieldPB field;

  FieldTypeOptionLoader({
    required this.gridId,
    required this.field,
  });

  @override
  Future<Either<TypeOptionPB, FlowyError>> load() {
    final payload = TypeOptionPathPB.create()
      ..gridId = gridId
      ..fieldId = field.id
      ..fieldType = field.fieldType;

    return GridEventGetFieldTypeOption(payload).send();
  }
}
