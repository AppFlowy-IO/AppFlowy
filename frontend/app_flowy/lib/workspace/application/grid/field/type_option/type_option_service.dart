import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';

class TypeOptionService {
  String fieldId;
  TypeOptionService({
    required this.fieldId,
  });

  Future<Either<SelectOption, FlowyError>> createOption(String name) {
    final payload = CreateSelectOptionPayload.create()..optionName = name;
    return GridEventCreateSelectOption(payload).send();
  }
}
