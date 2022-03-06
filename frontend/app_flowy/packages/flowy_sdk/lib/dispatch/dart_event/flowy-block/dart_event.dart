
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class BlockEventGetBlockData {
     BlockId request;
     BlockEventGetBlockData(this.request);

    Future<Either<BlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = BlockEvent.GetBlockData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(BlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class BlockEventApplyDelta {
     BlockDelta request;
     BlockEventApplyDelta(this.request);

    Future<Either<BlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = BlockEvent.ApplyDelta.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(BlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class BlockEventExportDocument {
     ExportPayload request;
     BlockEventExportDocument(this.request);

    Future<Either<ExportData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = BlockEvent.ExportDocument.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ExportData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

