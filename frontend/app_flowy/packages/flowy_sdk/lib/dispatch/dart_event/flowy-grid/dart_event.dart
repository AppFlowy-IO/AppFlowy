
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class GridEventGetGridData {
     GridId request;
     GridEventGetGridData(this.request);

    Future<Either<Grid, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetGridData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Grid.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetGridBlocks {
     QueryGridBlocksPayload request;
     GridEventGetGridBlocks(this.request);

    Future<Either<RepeatedGridBlock, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetGridBlocks.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedGridBlock.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetFields {
     QueryFieldPayload request;
     GridEventGetFields(this.request);

    Future<Either<RepeatedField, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetFields.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedField.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateField {
     FieldChangesetPayload request;
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
     UpdateFieldTypeOptionPayload request;
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

class GridEventInsertField {
     InsertFieldPayload request;
     GridEventInsertField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.InsertField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDeleteField {
     FieldIdentifierPayload request;
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
     EditFieldPayload request;
     GridEventSwitchToField(this.request);

    Future<Either<FieldTypeOptionData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.SwitchToField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(FieldTypeOptionData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDuplicateField {
     FieldIdentifierPayload request;
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

class GridEventMoveItem {
     MoveItemPayload request;
     GridEventMoveItem(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.MoveItem.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetFieldTypeOption {
     EditFieldPayload request;
     GridEventGetFieldTypeOption(this.request);

    Future<Either<FieldTypeOptionData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetFieldTypeOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(FieldTypeOptionData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventNewSelectOption {
     CreateSelectOptionPayload request;
     GridEventNewSelectOption(this.request);

    Future<Either<SelectOption, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.NewSelectOption.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(SelectOption.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetSelectOptionCellData {
     CellIdentifierPayload request;
     GridEventGetSelectOptionCellData(this.request);

    Future<Either<SelectOptionCellData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetSelectOptionCellData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(SelectOptionCellData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateSelectOption {
     SelectOptionChangesetPayload request;
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

class GridEventCreateRow {
     CreateRowPayload request;
     GridEventCreateRow(this.request);

    Future<Either<Row, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.CreateRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Row.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventGetRow {
     RowIdentifierPayload request;
     GridEventGetRow(this.request);

    Future<Either<Row, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetRow.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Row.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventDeleteRow {
     RowIdentifierPayload request;
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
     RowIdentifierPayload request;
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

class GridEventGetCell {
     CellIdentifierPayload request;
     GridEventGetCell(this.request);

    Future<Either<Cell, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetCell.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Cell.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventUpdateCell {
     CellChangeset request;
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
     SelectOptionCellChangesetPayload request;
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
     DateChangesetPayload request;
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

class GridEventGetDateCellData {
     CellIdentifierPayload request;
     GridEventGetDateCellData(this.request);

    Future<Either<DateCellData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetDateCellData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DateCellData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

