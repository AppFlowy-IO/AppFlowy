import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';
import 'type_option_data_controller.dart';

abstract class TypeOptionParser<T> {
  T fromBuffer(List<int> buffer);
}

// Number
typedef NumberTypeOptionContext = TypeOptionContext<NumberTypeOptionPB>;

class NumberTypeOptionWidgetDataParser
    extends TypeOptionParser<NumberTypeOptionPB> {
  @override
  NumberTypeOptionPB fromBuffer(List<int> buffer) {
    return NumberTypeOptionPB.fromBuffer(buffer);
  }
}

// RichText
typedef RichTextTypeOptionContext = TypeOptionContext<RichTextTypeOptionPB>;

class RichTextTypeOptionWidgetDataParser
    extends TypeOptionParser<RichTextTypeOptionPB> {
  @override
  RichTextTypeOptionPB fromBuffer(List<int> buffer) {
    return RichTextTypeOptionPB.fromBuffer(buffer);
  }
}

// Checkbox
typedef CheckboxTypeOptionContext = TypeOptionContext<CheckboxTypeOptionPB>;

class CheckboxTypeOptionWidgetDataParser
    extends TypeOptionParser<CheckboxTypeOptionPB> {
  @override
  CheckboxTypeOptionPB fromBuffer(List<int> buffer) {
    return CheckboxTypeOptionPB.fromBuffer(buffer);
  }
}

// URL
typedef URLTypeOptionContext = TypeOptionContext<URLTypeOptionPB>;

class URLTypeOptionWidgetDataParser extends TypeOptionParser<URLTypeOptionPB> {
  @override
  URLTypeOptionPB fromBuffer(List<int> buffer) {
    return URLTypeOptionPB.fromBuffer(buffer);
  }
}

// Date
typedef DateTypeOptionContext = TypeOptionContext<DateTypeOptionPB>;

class DateTypeOptionDataParser extends TypeOptionParser<DateTypeOptionPB> {
  @override
  DateTypeOptionPB fromBuffer(List<int> buffer) {
    return DateTypeOptionPB.fromBuffer(buffer);
  }
}

// SingleSelect
typedef SingleSelectTypeOptionContext
    = TypeOptionContext<SingleSelectTypeOptionPB>;

class SingleSelectTypeOptionWidgetDataParser
    extends TypeOptionParser<SingleSelectTypeOptionPB> {
  @override
  SingleSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return SingleSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef MultiSelectTypeOptionContext
    = TypeOptionContext<MultiSelectTypeOptionPB>;

class MultiSelectTypeOptionWidgetDataParser
    extends TypeOptionParser<MultiSelectTypeOptionPB> {
  @override
  MultiSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return MultiSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef ChecklistTypeOptionContext = TypeOptionContext<ChecklistTypeOptionPB>;

class ChecklistTypeOptionWidgetDataParser
    extends TypeOptionParser<ChecklistTypeOptionPB> {
  @override
  ChecklistTypeOptionPB fromBuffer(List<int> buffer) {
    return ChecklistTypeOptionPB.fromBuffer(buffer);
  }
}

class TypeOptionContext<T extends GeneratedMessage> {
  T? _typeOptionObject;
  final TypeOptionParser<T> dataParser;
  final TypeOptionController _dataController;

  TypeOptionContext({
    required this.dataParser,
    required TypeOptionController dataController,
  }) : _dataController = dataController;

  String get viewId => _dataController.loader.viewId;

  String get fieldId => _dataController.field.id;

  Future<T> loadTypeOptionData({
    void Function(T)? onCompleted,
    required void Function(FlowyError) onError,
  }) async {
    await _dataController.reloadTypeOption().then((result) {
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

abstract class ITypeOptionLoader {
  String get viewId;
  String get fieldName;

  Future<Either<TypeOptionPB, FlowyError>> initialize();
}

/// Uses when editing a existing field
class FieldTypeOptionLoader {
  final String viewId;
  final FieldPB field;

  FieldTypeOptionLoader({
    required this.viewId,
    required this.field,
  });

  Future<Either<TypeOptionPB, FlowyError>> load() {
    final payload = TypeOptionPathPB.create()
      ..viewId = viewId
      ..fieldId = field.id
      ..fieldType = field.fieldType;

    return DatabaseEventGetTypeOption(payload).send();
  }
}
