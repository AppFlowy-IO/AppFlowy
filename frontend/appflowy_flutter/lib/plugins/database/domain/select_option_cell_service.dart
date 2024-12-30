import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:nanoid/nanoid.dart';

class SelectOptionCellBackendService {
  SelectOptionCellBackendService({
    required this.viewId,
    required this.fieldId,
    required this.rowId,
  });

  final String viewId;
  final String fieldId;
  final String rowId;

  Future<FlowyResult<void, FlowyError>> create({
    required String name,
    SelectOptionColorPB? color,
    bool isSelected = true,
  }) {
    final option = SelectOptionPB()
      ..id = nanoid(4)
      ..name = name;
    if (color != null) {
      option.color = color;
    }

    final payload = RepeatedSelectOptionPayload()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId
      ..items.add(option);

    return DatabaseEventInsertOrUpdateSelectOption(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> update({
    required SelectOptionPB option,
  }) {
    final payload = RepeatedSelectOptionPayload()
      ..items.add(option)
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventInsertOrUpdateSelectOption(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> delete({
    required Iterable<SelectOptionPB> options,
  }) {
    final payload = RepeatedSelectOptionPayload()
      ..items.addAll(options)
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventDeleteSelectOption(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> select({
    required Iterable<String> optionIds,
  }) {
    final payload = SelectOptionCellChangesetPB()
      ..cellIdentifier = _cellIdentifier()
      ..insertOptionIds.addAll(optionIds);

    return DatabaseEventUpdateSelectOptionCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> unselect({
    required Iterable<String> optionIds,
  }) {
    final payload = SelectOptionCellChangesetPB()
      ..cellIdentifier = _cellIdentifier()
      ..deleteOptionIds.addAll(optionIds);

    return DatabaseEventUpdateSelectOptionCell(payload).send();
  }

  CellIdPB _cellIdentifier() {
    return CellIdPB()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;
  }
}
