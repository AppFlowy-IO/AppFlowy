import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/cell_entities.pb.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'cell_service/cell_service.dart';

class SelectOptionFFIService {
  final GridCellIdentifier cellId;
  SelectOptionFFIService({required this.cellId});

  String get databaseId => cellId.databaseId;
  String get fieldId => cellId.fieldInfo.id;
  String get rowId => cellId.rowId;

  Future<Either<Unit, FlowyError>> create(
      {required String name, bool isSelected = true}) {
    return TypeOptionFFIService(databaseId: databaseId, fieldId: fieldId)
        .newOption(name: name)
        .then(
      (result) {
        return result.fold(
          (option) {
            final cellIdentifier = CellIdPB.create()
              ..databaseId = databaseId
              ..fieldId = fieldId
              ..rowId = rowId;
            final payload = SelectOptionChangesetPB.create()
              ..cellIdentifier = cellIdentifier;

            if (isSelected) {
              payload.insertOptions.add(option);
            } else {
              payload.updateOptions.add(option);
            }
            return DatabaseEventUpdateSelectOption(payload).send();
          },
          (r) => right(r),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOptionPB option,
  }) {
    final payload = SelectOptionChangesetPB.create()
      ..updateOptions.add(option)
      ..cellIdentifier = _cellIdentifier();
    return DatabaseEventUpdateSelectOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete(
      {required Iterable<SelectOptionPB> options}) {
    final payload = SelectOptionChangesetPB.create()
      ..deleteOptions.addAll(options)
      ..cellIdentifier = _cellIdentifier();

    return DatabaseEventUpdateSelectOption(payload).send();
  }

  Future<Either<SelectOptionCellDataPB, FlowyError>> getOptionContext() {
    final payload = CellIdPB.create()
      ..databaseId = databaseId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventGetSelectOptionCellData(payload).send();
  }

  Future<Either<void, FlowyError>> select(
      {required Iterable<String> optionIds}) {
    final payload = SelectOptionCellChangesetPB.create()
      ..cellIdentifier = _cellIdentifier()
      ..insertOptionIds.addAll(optionIds);
    return DatabaseEventUpdateSelectOptionCell(payload).send();
  }

  Future<Either<void, FlowyError>> unSelect(
      {required Iterable<String> optionIds}) {
    final payload = SelectOptionCellChangesetPB.create()
      ..cellIdentifier = _cellIdentifier()
      ..deleteOptionIds.addAll(optionIds);
    return DatabaseEventUpdateSelectOptionCell(payload).send();
  }

  CellIdPB _cellIdentifier() {
    return CellIdPB.create()
      ..databaseId = databaseId
      ..fieldId = fieldId
      ..rowId = rowId;
  }
}
