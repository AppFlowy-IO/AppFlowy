import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';

class SelectOptionCellBackendService {
  final DatabaseCellContext cellContext;
  SelectOptionCellBackendService({required this.cellContext});

  String get viewId => cellContext.viewId;
  String get fieldId => cellContext.fieldInfo.id;
  RowId get rowId => cellContext.rowId;

  Future<Either<Unit, FlowyError>> create({
    required String name,
    bool isSelected = true,
  }) {
    return TypeOptionBackendService(viewId: viewId, fieldId: fieldId)
        .newOption(name: name)
        .then(
      (result) {
        return result.fold(
          (option) {
            final payload = RepeatedSelectOptionPayload.create()
              ..viewId = viewId
              ..fieldId = fieldId
              ..rowId = rowId;

            if (isSelected) {
              payload.items.add(option);
            } else {
              payload.items.add(option);
            }
            return DatabaseEventInsertOrUpdateSelectOption(payload).send();
          },
          (r) => right(r),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOptionPB option,
  }) {
    final payload = RepeatedSelectOptionPayload.create()
      ..items.add(option)
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;
    return DatabaseEventInsertOrUpdateSelectOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required Iterable<SelectOptionPB> options,
  }) {
    final payload = RepeatedSelectOptionPayload.create()
      ..items.addAll(options)
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventDeleteSelectOption(payload).send();
  }

  Future<Either<SelectOptionCellDataPB, FlowyError>> getCellData() {
    final payload = CellIdPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventGetSelectOptionCellData(payload).send();
  }

  Future<Either<void, FlowyError>> select({
    required Iterable<String> optionIds,
  }) {
    final payload = SelectOptionCellChangesetPB.create()
      ..cellIdentifier = _cellIdentifier()
      ..insertOptionIds.addAll(optionIds);
    return DatabaseEventUpdateSelectOptionCell(payload).send();
  }

  Future<Either<void, FlowyError>> unSelect({
    required Iterable<String> optionIds,
  }) {
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
