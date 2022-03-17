
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

class GridEventUpdateCell {
     CellMetaChangeset request;
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

