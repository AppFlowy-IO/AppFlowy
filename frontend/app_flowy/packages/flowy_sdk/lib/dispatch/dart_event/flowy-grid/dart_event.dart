
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class GridEventGetGrid {
     GridIdPB request;
     GridEventGetGrid(this.request);

    Future<Either<GridPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetGrid.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(GridPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetGridSetting {
     GridIdPB request;
     GridEventGetGridSetting(this.request);

    Future<Either<GridSettingPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetGridSetting.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(GridSettingPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateGridSetting {
     GridSettingChangesetPB request;
     GridEventUpdateGridSetting(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateGridSetting.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetAllFilters {
     GridIdPB request;
     GridEventGetAllFilters(this.request);

    Future<Either<RepeatedFilterPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetAllFilters.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedFilterPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetFields {
     GetFieldPayloadPB request;
     GridEventGetFields(this.request);

    Future<Either<RepeatedFieldPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetFields.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedFieldPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateField {
     FieldChangesetPB request;
     GridEventUpdateField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateFieldTypeOption {
     TypeOptionChangesetPB request;
     GridEventUpdateFieldTypeOption(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateFieldTypeOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDeleteField {
     DeleteFieldPayloadPB request;
     GridEventDeleteField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.DeleteField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventSwitchToField {
     EditFieldChangesetPB request;
     GridEventSwitchToField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.SwitchToField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDuplicateField {
     DuplicateFieldPayloadPB request;
     GridEventDuplicateField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.DuplicateField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventMoveField {
     MoveFieldPayloadPB request;
     GridEventMoveField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.MoveField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetFieldTypeOption {
     TypeOptionPathPB request;
     GridEventGetFieldTypeOption(this.request);

    Future<Either<TypeOptionPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetFieldTypeOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(TypeOptionPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventCreateFieldTypeOption {
     CreateFieldPayloadPB request;
     GridEventCreateFieldTypeOption(this.request);

    Future<Either<TypeOptionPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.CreateFieldTypeOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(TypeOptionPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventNewSelectOption {
     CreateSelectOptionPayloadPB request;
     GridEventNewSelectOption(this.request);

    Future<Either<SelectOptionPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.NewSelectOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(SelectOptionPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetSelectOptionCellData {
     CellPathPB request;
     GridEventGetSelectOptionCellData(this.request);

    Future<Either<SelectOptionCellDataPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetSelectOptionCellData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(SelectOptionCellDataPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateSelectOption {
     SelectOptionChangesetPB request;
     GridEventUpdateSelectOption(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateSelectOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventCreateTableRow {
     CreateTableRowPayloadPB request;
     GridEventCreateTableRow(this.request);

    Future<Either<RowPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.CreateTableRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RowPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetRow {
     RowIdPB request;
     GridEventGetRow(this.request);

    Future<Either<OptionalRowPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(OptionalRowPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDeleteRow {
     RowIdPB request;
     GridEventDeleteRow(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.DeleteRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDuplicateRow {
     RowIdPB request;
     GridEventDuplicateRow(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.DuplicateRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventMoveRow {
     MoveRowPayloadPB request;
     GridEventMoveRow(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.MoveRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetCell {
     CellPathPB request;
     GridEventGetCell(this.request);

    Future<Either<CellPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetCell.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(CellPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateCell {
     CellChangesetPB request;
     GridEventUpdateCell(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateCell.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateSelectOptionCell {
     SelectOptionCellChangesetPB request;
     GridEventUpdateSelectOptionCell(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateSelectOptionCell.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateDateCell {
     DateChangesetPB request;
     GridEventUpdateDateCell(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.UpdateDateCell.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetGroup {
     GridIdPB request;
     GridEventGetGroup(this.request);

    Future<Either<RepeatedGroupPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetGroup.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedGroupPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventCreateBoardCard {
     CreateBoardCardPayloadPB request;
     GridEventCreateBoardCard(this.request);

    Future<Either<RowPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.CreateBoardCard.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RowPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventMoveGroup {
     MoveGroupPayloadPB request;
     GridEventMoveGroup(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.MoveGroup.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventMoveGroupRow {
     MoveGroupRowPayloadPB request;
     GridEventMoveGroupRow(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.MoveGroupRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGroupByField {
     MoveGroupRowPayloadPB request;
     GridEventGroupByField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GroupByField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

