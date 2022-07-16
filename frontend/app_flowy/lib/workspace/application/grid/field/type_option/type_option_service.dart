import 'dart:typed_data';

import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:protobuf/protobuf.dart';

class TypeOptionService {
  final String gridId;
  final String fieldId;

  TypeOptionService({
    required this.gridId,
    required this.fieldId,
  });

  Future<Either<SelectOption, FlowyError>> newOption({
    required String name,
  }) {
    final fieldIdentifier = FieldIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId;

    final payload = CreateSelectOptionPayload.create()
      ..optionName = name
      ..fieldIdentifier = fieldIdentifier;

    return GridEventNewSelectOption(payload).send();
  }
}

abstract class TypeOptionDataParser<T> {
  T fromBuffer(List<int> buffer);
}

class TypeOptionWidgetContext<T extends GeneratedMessage> {
  T? _typeOptionObject;
  final TypeOptionDataController _dataController;
  final TypeOptionDataParser<T> dataParser;

  TypeOptionWidgetContext({
    required this.dataParser,
    required TypeOptionDataController dataController,
  }) : _dataController = dataController;

  String get gridId => _dataController.gridId;

  Field get field => _dataController.field;

  T get typeOption {
    if (_typeOptionObject != null) {
      return _typeOptionObject!;
    }

    final T object = dataParser.fromBuffer(_dataController.typeOptionData);
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

class TypeOptionContext2<T> {
  final String gridId;
  final Field field;
  final FieldService _fieldService;
  T? _data;
  final TypeOptionDataParser dataBuilder;

  TypeOptionContext2({
    required this.gridId,
    required this.field,
    required this.dataBuilder,
    Uint8List? data,
  }) : _fieldService = FieldService(gridId: gridId, fieldId: field.id) {
    if (data != null) {
      _data = dataBuilder.fromBuffer(data);
    }
  }

  Future<Either<T, FlowyError>> typeOptionData() {
    if (_data != null) {
      return Future(() => left(_data!));
    }

    return _fieldService.getFieldTypeOptionData(fieldType: field.fieldType).then((result) {
      return result.fold(
        (data) {
          _data = dataBuilder.fromBuffer(data.typeOptionData);
          return left(_data!);
        },
        (err) => right(err),
      );
    });
  }
}
