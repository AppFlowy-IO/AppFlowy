import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class ChecklistCellBackendService {
  final CellIdentifier cellId;

  ChecklistCellBackendService({required this.cellId});

  Future<Either<Unit, FlowyError>> create({
    required String name,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = cellId.viewId
      ..fieldId = cellId.fieldInfo.id
      ..rowId = cellId.rowId
      ..insertOptions.add(name);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required List<String> optionIds,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = cellId.viewId
      ..fieldId = cellId.fieldInfo.id
      ..rowId = cellId.rowId
      ..deleteOptionIds.addAll(optionIds);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> select({
    required String optionId,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = cellId.viewId
      ..fieldId = cellId.fieldInfo.id
      ..rowId = cellId.rowId
      ..selectedOptionIds.add(optionId);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOptionPB option,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = cellId.viewId
      ..fieldId = cellId.fieldInfo.id
      ..rowId = cellId.rowId
      ..updateOptions.add(option);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<ChecklistCellDataPB, FlowyError>> getCellData() {
    final payload = CellIdPB.create()
      ..fieldId = cellId.fieldInfo.id
      ..viewId = cellId.viewId
      ..rowId = cellId.rowId
      ..rowId = cellId.rowId;

    return DatabaseEventGetChecklistCellData(payload).send();
  }
}
