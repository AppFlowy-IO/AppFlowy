
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class GridEventCreateGrid {
     CreateGridPayload request;
     GridEventCreateGrid(this.request);

    Future<Either<Grid, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.CreateGrid.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Grid.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class GridEventOpenGrid {
     GridId request;
     GridEventOpenGrid(this.request);

    Future<Either<Grid, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = GridEvent.OpenGrid.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Grid.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

