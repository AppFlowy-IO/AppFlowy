import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'type_option_service.dart';

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
    bool isSelected = true,
  }) {
    return TypeOptionBackendService(viewId: viewId, fieldId: fieldId)
        .newOption(name: name)
        .then(
      (result) {
        return result.fold(
          (option) {
            final payload = RepeatedSelectOptionPayload()
              ..viewId = viewId
              ..fieldId = fieldId
              ..rowId = rowId
              ..items.add(option);

            return DatabaseEventInsertOrUpdateSelectOption(payload).send();
          },
          (r) => FlowyResult.failure(r),
        );
      },
    );
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

  Future<FlowyResult<SelectOptionCellDataPB, FlowyError>> getCellData() {
    final payload = CellIdPB()
      ..viewId = viewId
      ..fieldId = fieldId
      ..rowId = rowId;

    return DatabaseEventGetSelectOptionCellData(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> select({
    required Iterable<String> optionIds,
  }) {
    final payload = SelectOptionCellChangesetPB()
      ..cellIdentifier = _cellIdentifier()
      ..insertOptionIds.addAll(optionIds);

    return DatabaseEventUpdateSelectOptionCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> unSelect({
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
