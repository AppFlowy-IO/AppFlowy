import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class TypeOptionBackendService {
  final String viewId;
  final String fieldId;

  TypeOptionBackendService({
    required this.viewId,
    required this.fieldId,
  });

  Future<Either<SelectOptionPB, FlowyError>> newOption({
    required String name,
  }) {
    final payload = CreateSelectOptionPayloadPB.create()
      ..optionName = name
      ..viewId = viewId
      ..fieldId = fieldId;

    return DatabaseEventCreateSelectOption(payload).send();
  }
}
