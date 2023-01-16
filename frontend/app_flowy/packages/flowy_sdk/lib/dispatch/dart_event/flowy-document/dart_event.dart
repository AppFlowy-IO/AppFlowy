
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class DocumentEventGetDocument {
     OpenDocumentContextPB request;
     DocumentEventGetDocument(this.request);

    Future<Either<DocumentSnapshotPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = DocumentEvent.GetDocument.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocumentSnapshotPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class DocumentEventApplyEdit {
     EditPayloadPB request;
     DocumentEventApplyEdit(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = DocumentEvent.ApplyEdit.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class DocumentEventExportDocument {
     ExportPayloadPB request;
     DocumentEventExportDocument(this.request);

    Future<Either<ExportDataPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = DocumentEvent.ExportDocument.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ExportDataPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

