
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class TextBlockEventGetBlockData {
     TextBlockId request;
     TextBlockEventGetBlockData(this.request);

    Future<Either<TextBlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = TextBlockEvent.GetBlockData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(TextBlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class TextBlockEventApplyDelta {
     TextBlockDelta request;
     TextBlockEventApplyDelta(this.request);

    Future<Either<TextBlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = TextBlockEvent.ApplyDelta.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(TextBlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class TextBlockEventExportDocument {
     ExportPayload request;
     TextBlockEventExportDocument(this.request);

    Future<Either<ExportData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = TextBlockEvent.ExportDocument.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ExportData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

