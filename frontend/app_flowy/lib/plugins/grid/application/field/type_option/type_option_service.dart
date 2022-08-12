import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';

class TypeOptionFFIService {
  final String gridId;
  final String fieldId;

  TypeOptionFFIService({
    required this.gridId,
    required this.fieldId,
  });

  Future<Either<SelectOptionPB, FlowyError>> newOption({
    required String name,
  }) {
    final payload = CreateSelectOptionPayloadPB.create()
      ..optionName = name
      ..gridId = gridId
      ..fieldId = fieldId;

    return GridEventNewSelectOption(payload).send();
  }
}
