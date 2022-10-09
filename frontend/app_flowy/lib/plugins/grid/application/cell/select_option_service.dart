import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'cell_service/cell_service.dart';

class SelectOptionService {
  final GridCellIdentifier cellId;
  SelectOptionService({required this.cellId});

  String get gridId => cellId.gridId;
  String get fieldId => cellId.fieldContext.id;
  String get rowId => cellId.rowId;

  Future<Either<Unit, FlowyError>> create({required String name}) {
    return TypeOptionFFIService(gridId: gridId, fieldId: fieldId)
        .newOption(name: name)
        .then(
      (result) {
        return result.fold(
          (option) {
            final cellIdentifier = GridCellIdPB.create()
              ..gridId = gridId
              ..fieldId = fieldId
              ..rowId = rowId;
            final payload = SelectOptionChangesetPayloadPB.create()
              ..insertOptions.add(option)
              ..cellIdentifier = cellIdentifier;
            return GridEventUpdateSelectOption(payload).send();
          },
          (r) => right(r),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOptionPB option,
  }) {
    final payload = SelectOptionChangesetPayloadPB.create()
      ..updateOptions.add(option)
      ..cellIdentifier = _cellIdentifier();
    return GridEventUpdateSelectOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required SelectOptionPB option,
  }) {
    final payload = SelectOptionChangesetPayloadPB.create()
      ..deleteOptions.add(option)
      ..cellIdentifier = _cellIdentifier();

    return GridEventUpdateSelectOption(payload).send();
  }

  Future<Either<SelectOptionCellDataPB, FlowyError>> getOptionContext() {
    final payload = GridCellIdPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;

    return GridEventGetSelectOptionCellData(payload).send();
  }

  Future<Either<void, FlowyError>> select({required String optionId}) {
    final payload = SelectOptionCellChangesetPayloadPB.create()
      ..cellIdentifier = _cellIdentifier()
      ..insertOptionIds.add(optionId);
    return GridEventUpdateSelectOptionCell(payload).send();
  }

  Future<Either<void, FlowyError>> unSelect({required String optionId}) {
    final payload = SelectOptionCellChangesetPayloadPB.create()
      ..cellIdentifier = _cellIdentifier()
      ..deleteOptionIds.add(optionId);
    return GridEventUpdateSelectOptionCell(payload).send();
  }

  GridCellIdPB _cellIdentifier() {
    return GridCellIdPB.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;
  }
}
