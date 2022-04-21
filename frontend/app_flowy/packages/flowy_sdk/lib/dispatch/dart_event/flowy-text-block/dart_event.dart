
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class BlockEventGetBlockData {
     TextBlockId request;
     BlockEventGetBlockData(this.request);

    Future<Either<TextBlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = BlockEvent.GetBlockData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(TextBlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class BlockEventApplyDelta {
     TextBlockDelta request;
     BlockEventApplyDelta(this.request);

    Future<Either<TextBlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = BlockEvent.ApplyDelta.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(TextBlockDelta.fromBuffer(okBytes)),
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

