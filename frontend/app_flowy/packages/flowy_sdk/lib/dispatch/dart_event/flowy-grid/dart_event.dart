
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

class GridEventCreateField {
     CreateFieldPayload request;
     GridEventCreateField(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.CreateField.toString()
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

    Future<Either<EditFieldContext, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.SwitchToField.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(EditFieldContext.fromBuffer(okBytes)),
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

class GridEventGetEditFieldContext {
     GetEditFieldContextPayload request;
     GridEventGetEditFieldContext(this.request);

    Future<Either<EditFieldContext, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetEditFieldContext.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(EditFieldContext.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventNewSelectOption {
     SelectOptionName request;
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

class GridEventGetSelectOptionContext {
     CellIdentifierPayload request;
     GridEventGetSelectOptionContext(this.request);

    Future<Either<SelectOptionContext, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.GetSelectOptionContext.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(SelectOptionContext.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventApplySelectOptionChangeset {
     SelectOptionChangesetPayload request;
     GridEventApplySelectOptionChangeset(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.ApplySelectOptionChangeset.toString()
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

class GridEventApplySelectOptionCellChangeset {
     SelectOptionCellChangesetPayload request;
     GridEventApplySelectOptionCellChangeset(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.ApplySelectOptionCellChangeset.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

