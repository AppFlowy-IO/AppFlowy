import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';

class SelectOptionService {
  SelectOptionService();

  Future<Either<Unit, FlowyError>> create({
    required String gridId,
    required String fieldId,
    required String rowId,
    required String name,
  }) {
    return GridEventNewSelectOption(SelectOptionName.create()..name = name).send().then(
      (result) {
        return result.fold(
          (option) {
            final cellIdentifier = CellIdentifierPayload.create()
              ..gridId = gridId
              ..fieldId = fieldId
              ..rowId = rowId;
            final payload = SelectOptionChangesetPayload.create()
              ..insertOption = option
              ..cellIdentifier = cellIdentifier;
            return GridEventApplySelectOptionChangeset(payload).send();
          },
          (r) => right(r),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> insert({
    required String gridId,
    required String fieldId,
    required String rowId,
    required SelectOption option,
  }) {
    final cellIdentifier = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;
    final payload = SelectOptionChangesetPayload.create()
      ..insertOption = option
      ..cellIdentifier = cellIdentifier;
    return GridEventApplySelectOptionChangeset(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required String gridId,
    required String fieldId,
    required String rowId,
    required SelectOption option,
  }) {
    final cellIdentifier = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;

    final payload = SelectOptionChangesetPayload.create()
      ..deleteOption = option
      ..cellIdentifier = cellIdentifier;

    return GridEventApplySelectOptionChangeset(payload).send();
  }

  Future<Either<SelectOptionContext, FlowyError>> getOpitonContext({
    required String gridId,
    required String fieldId,
    required String rowId,
  }) {
    final payload = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;

    return GridEventGetSelectOptionContext(payload).send();
  }

  Future<Either<void, FlowyError>> select({
    required String gridId,
    required String fieldId,
    required String rowId,
    required String optionId,
  }) {
    final payload = SelectOptionCellChangesetPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..insertOptionId = optionId;
    return GridEventApplySelectOptionCellChangeset(payload).send();
  }

  Future<Either<void, FlowyError>> remove({
    required String gridId,
    required String fieldId,
    required String rowId,
    required String optionId,
  }) {
    final payload = SelectOptionCellChangesetPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..deleteOptionId = optionId;
    return GridEventApplySelectOptionCellChangeset(payload).send();
  }
}
