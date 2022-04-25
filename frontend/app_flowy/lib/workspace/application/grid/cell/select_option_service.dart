import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';

import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';

import 'cell_service.dart';

class SelectOptionCellDataLoader extends GridCellDataLoader<SelectOptionContext> {
  final SelectOptionService service;
  final GridCell gridCell;
  SelectOptionCellDataLoader({
    required this.gridCell,
  }) : service = SelectOptionService(gridCell: gridCell);
  @override
  Future<SelectOptionContext?> loadData() async {
    return service.getOpitonContext().then((result) {
      return result.fold(
        (data) => data,
        (err) {
          Log.error(err);
          return null;
        },
      );
    });
  }
}

class SelectOptionService {
  final GridCell gridCell;
  SelectOptionService({required this.gridCell});

  String get gridId => gridCell.gridId;
  String get fieldId => gridCell.field.id;
  String get rowId => gridCell.rowId;

  Future<Either<Unit, FlowyError>> create({required String name}) {
    return TypeOptionService(gridId: gridId, fieldId: fieldId).newOption(name: name).then(
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
            return GridEventUpdateSelectOption(payload).send();
          },
          (r) => right(r),
        );
      },
    );
  }

  Future<Either<Unit, FlowyError>> update({
    required SelectOption option,
  }) {
    final cellIdentifier = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;
    final payload = SelectOptionChangesetPayload.create()
      ..updateOption = option
      ..cellIdentifier = cellIdentifier;
    return GridEventUpdateSelectOption(payload).send();
  }

  Future<Either<Unit, FlowyError>> delete({
    required SelectOption option,
  }) {
    final cellIdentifier = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;

    final payload = SelectOptionChangesetPayload.create()
      ..deleteOption = option
      ..cellIdentifier = cellIdentifier;

    return GridEventUpdateSelectOption(payload).send();
  }

  Future<Either<SelectOptionContext, FlowyError>> getOpitonContext() {
    final payload = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;

    return GridEventGetSelectOptionContext(payload).send();
  }

  Future<Either<void, FlowyError>> select({required String optionId}) {
    final payload = SelectOptionCellChangesetPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..insertOptionId = optionId;
    return GridEventUpdateCellSelectOption(payload).send();
  }

  Future<Either<void, FlowyError>> unSelect({required String optionId}) {
    final payload = SelectOptionCellChangesetPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..deleteOptionId = optionId;
    return GridEventUpdateCellSelectOption(payload).send();
  }
}
