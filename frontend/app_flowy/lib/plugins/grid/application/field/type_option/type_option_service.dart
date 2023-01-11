import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/select_type_option.pb.dart';

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
