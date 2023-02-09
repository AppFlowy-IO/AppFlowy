import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';

class TypeOptionFFIService {
  final String databaseId;
  final String fieldId;

  TypeOptionFFIService({
    required this.databaseId,
    required this.fieldId,
  });

  Future<Either<SelectOptionPB, FlowyError>> newOption({
    required String name,
  }) {
    final payload = CreateSelectOptionPayloadPB.create()
      ..optionName = name
      ..databaseId = databaseId
      ..fieldId = fieldId;

    return DatabaseEventCreateSelectOption(payload).send();
  }
}
