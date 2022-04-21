import 'dart:typed_data';

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

class TypeOptionContext {
  final String gridId;
  final Field field;
  final Uint8List data;
  const TypeOptionContext({
    required this.gridId,
    required this.field,
    required this.data,
  });
}
