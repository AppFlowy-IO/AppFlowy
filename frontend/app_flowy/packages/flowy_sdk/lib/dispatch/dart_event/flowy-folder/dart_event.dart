
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class FolderEventCreateWorkspace {
     CreateWorkspacePayload request;
     FolderEventCreateWorkspace(this.request);

    Future<Either<Workspace, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CreateWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Workspace.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadCurWorkspace {
    FolderEventReadCurWorkspace();

    Future<Either<CurrentWorkspaceSetting, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.ReadCurWorkspace.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(CurrentWorkspaceSetting.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventReadWorkspaces {
     WorkspaceId request;
     FolderEventReadWorkspaces(this.request);

    Future<Either<RepeatedWorkspace, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadWorkspaces.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedWorkspace.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteWorkspace {
     WorkspaceId request;
     FolderEventDeleteWorkspace(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.DeleteWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventOpenWorkspace {
     WorkspaceId request;
     FolderEventOpenWorkspace(this.request);

    Future<Either<Workspace, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.OpenWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Workspace.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadWorkspaceApps {
     WorkspaceId request;
     FolderEventReadWorkspaceApps(this.request);

    Future<Either<RepeatedApp, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadWorkspaceApps.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedApp.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventCreateApp {
     CreateAppPayload request;
     FolderEventCreateApp(this.request);

    Future<Either<App, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CreateApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(App.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteApp {
     AppId request;
     FolderEventDeleteApp(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.DeleteApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadApp {
     AppId request;
     FolderEventReadApp(this.request);

    Future<Either<App, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(App.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventUpdateApp {
     UpdateAppPayload request;
     FolderEventUpdateApp(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.UpdateApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventCreateView {
     CreateViewPayload request;
     FolderEventCreateView(this.request);

    Future<Either<View, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CreateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(View.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadView {
     ViewId request;
     FolderEventReadView(this.request);

    Future<Either<View, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(View.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventUpdateView {
     UpdateViewPayload request;
     FolderEventUpdateView(this.request);

    Future<Either<View, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.UpdateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(View.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteView {
     RepeatedViewId request;
     FolderEventDeleteView(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.DeleteView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDuplicateView {
     ViewId request;
     FolderEventDuplicateView(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.DuplicateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventCopyLink {
    FolderEventCopyLink();

    Future<Either<Unit, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.CopyLink.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventOpenView {
     ViewId request;
     FolderEventOpenView(this.request);

    Future<Either<BlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.OpenView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(BlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventCloseView {
     ViewId request;
     FolderEventCloseView(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CloseView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadTrash {
    FolderEventReadTrash();

    Future<Either<RepeatedTrash, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.ReadTrash.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(RepeatedTrash.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventPutbackTrash {
     TrashId request;
     FolderEventPutbackTrash(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.PutbackTrash.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteTrash {
     RepeatedTrashId request;
     FolderEventDeleteTrash(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.DeleteTrash.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventRestoreAllTrash {
    FolderEventRestoreAllTrash();

    Future<Either<Unit, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.RestoreAllTrash.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventDeleteAllTrash {
    FolderEventDeleteAllTrash();

    Future<Either<Unit, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.DeleteAllTrash.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventApplyDocDelta {
     BlockDelta request;
     FolderEventApplyDocDelta(this.request);

    Future<Either<BlockDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ApplyDocDelta.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(BlockDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventExportDocument {
     ExportPayload request;
     FolderEventExportDocument(this.request);

    Future<Either<ExportData, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ExportDocument.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ExportData.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

