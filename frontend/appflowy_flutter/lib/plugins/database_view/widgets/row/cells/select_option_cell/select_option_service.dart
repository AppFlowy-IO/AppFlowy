import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';

class SelectOptionBackendService {
  final CellIdentifier cellId;
  SelectOptionBackendService({required this.cellId});

  String get viewId => cellId.viewId;
  String get fieldId => cellId.fieldInfo.id;
  String get rowId => cellId.rowId;

  Future<Either<Unit, FlowyError>> create(
      {required String name, bool isSelected = true}) {
    return TypeOptionBackendService(viewId: viewId, fieldId: fieldId)
        .newOption(name: name)
        .then(
      (result) {
        return result.fold(
          (option) {
            final cellIdentifier = CellIdPB.create()
              ..viewId = viewId
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

  Future<Either<SelectOptionCellDataPB, FlowyError>> getCellData() {
    final payload = CellIdPB.create()
      ..viewId = viewId
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
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;
  }
}
