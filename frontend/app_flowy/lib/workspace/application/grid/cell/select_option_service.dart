import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'cell_service/cell_service.dart';

class SelectOptionService {
  final GridCellIdentifier cellId;
  SelectOptionService({required this.cellId});

  String get gridId => cellId.gridId;
  String get fieldId => cellId.field.id;
  String get rowId => cellId.rowId;

  Future<Either<Unit, FlowyError>> create({required String name}) {
    return TypeOptionService(gridId: gridId, fieldId: fieldId).newOption(name: name).then(
      (result) {
        return result.fold(
          (option) {
            final cellIdentifier = CellIdentifierPayload.create()
              ..gridId = gridId
              ..fieldId = fieldId
              ..rowId = rowId;
            final payload = SelectOptionChangesetPayload.create()
              ..insertOption = option
              ..cellIdentifier = cellIdentifier;
            return GridEventUpdateSelectOption(payload).send();
          },
          (r) => right(r),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOption option,
  }) {
    final payload = SelectOptionChangesetPayload.create()
      ..updateOption = option
      ..cellIdentifier = _cellIdentifier();
    return GridEventUpdateSelectOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required SelectOption option,
  }) {
    final payload = SelectOptionChangesetPayload.create()
      ..deleteOption = option
      ..cellIdentifier = _cellIdentifier();

    return GridEventUpdateSelectOption(payload).send();
  }

  Future<Either<SelectOptionCellData, FlowyError>> getOpitonContext() {
    final payload = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;

    return GridEventGetSelectOptionCellData(payload).send();
  }

  Future<Either<void, FlowyError>> select({required String optionId}) {
    final payload = SelectOptionCellChangesetPayload.create()
      ..cellIdentifier = _cellIdentifier()
      ..insertOptionId = optionId;
    return GridEventUpdateSelectOptionCell(payload).send();
  }

  Future<Either<void, FlowyError>> unSelect({required String optionId}) {
    final payload = SelectOptionCellChangesetPayload.create()
      ..cellIdentifier = _cellIdentifier()
      ..deleteOptionId = optionId;
    return GridEventUpdateSelectOptionCell(payload).send();
  }

  CellIdentifierPayload _cellIdentifier() {
    return CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;
  }
}
