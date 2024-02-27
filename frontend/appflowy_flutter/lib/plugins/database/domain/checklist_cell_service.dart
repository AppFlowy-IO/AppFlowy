import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
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
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..insertOptions.add(name);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> delete({
    required List<String> optionIds,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..deleteOptionIds.addAll(optionIds);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> select({
    required String optionId,
  }) {
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..selectedOptionIds.add(optionId);

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
    final payload = ChecklistCellDataChangesetPB.create()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..updateOptions.add(newOption);

    return DatabaseEventUpdateChecklistCell(payload).send();
  }
}
