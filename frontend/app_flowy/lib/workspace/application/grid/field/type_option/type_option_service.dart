import 'dart:typed_data';

import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';

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

abstract class TypeOptionDataBuilder<T> {
  T fromBuffer(List<int> buffer);
}

class TypeOptionContext {
  final GridFieldContext _fieldContext;

  TypeOptionContext({
    required GridFieldContext fieldContext,
  }) : _fieldContext = fieldContext;

  String get gridId => _fieldContext.gridId;

  Field get field => _fieldContext.field;

  Uint8List get data => Uint8List.fromList(_fieldContext.typeOptionData);
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
  final TypeOptionDataBuilder dataBuilder;

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
