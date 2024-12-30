import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:protobuf/protobuf.dart';

class ChecklistCellBackendService {
  ChecklistCellBackendService({
    required this.viewId,
    required this.fieldId,
    required this.rowId,
  });

  final String viewId;
  final String fieldId;
  final String rowId;

  Future<FlowyResult<void, FlowyError>> create({
    required String name,
    int? index,
  }) {
    final insert = ChecklistCellInsertPB()..name = name;
    if (index != null) {
      insert.index = index;
    }

    final payload = ChecklistCellDataChangesetPB()
      ..cellId = _makdeCellId()
      ..insertTask.add(insert);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> delete({
    required List<String> optionIds,
  }) {
    final payload = ChecklistCellDataChangesetPB()
      ..cellId = _makdeCellId()
      ..deleteTasks.addAll(optionIds);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> select({
    required String optionId,
  }) {
    final payload = ChecklistCellDataChangesetPB()
      ..cellId = _makdeCellId()
      ..completedTasks.add(optionId);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateName({
    required SelectOptionPB option,
    required name,
  }) {
    option.freeze();
    final newOption = option.rebuild((option) {
      option.name = name;
    });
    final payload = ChecklistCellDataChangesetPB()
      ..cellId = _makdeCellId()
      ..updateTasks.add(newOption);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> reorder({
    required fromTaskId,
    required toTaskId,
  }) {
    final payload = ChecklistCellDataChangesetPB()
      ..cellId = _makdeCellId()
      ..reorder = "$fromTaskId $toTaskId";

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  CellIdPB _makdeCellId() {
    return CellIdPB()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;
  }
}
