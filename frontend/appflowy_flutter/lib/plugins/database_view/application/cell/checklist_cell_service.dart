import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class ChecklistCellBackendService {
  final String viewId;
  final String fieldId;
  final String rowId;

  ChecklistCellBackendService({
    required this.viewId,
    required this.fieldId,
    required this.rowId,
  });

  Future<Either<Unit, FlowyError>> create({
    required String name,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..insertOptions.add(name);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required List<String> optionIds,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..deleteOptionIds.addAll(optionIds);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> select({
    required String optionId,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..selectedOptionIds.add(optionId);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOptionPB option,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..updateOptions.add(option);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<Either<ChecklistCellDataPB, FlowyError>> getCellData() {
    final payload = CellIdPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventGetChecklistCellData(payload).send();
  }
}
