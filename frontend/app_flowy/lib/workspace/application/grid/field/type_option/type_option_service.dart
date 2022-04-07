import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';

class TypeOptionService {
  final String fieldId;
  TypeOptionService({
    required this.fieldId,
  });

  Future<Either<SelectOption, FlowyError>> newOption(String name, {bool selected = false}) {
    final payload = SelectOptionName.create()..name = name;
    return GridEventNewSelectOption(payload).send();
  }
}
