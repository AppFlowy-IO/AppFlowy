
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class FolderEventCreateWorkspace {
     CreateWorkspacePayloadPB request;
     FolderEventCreateWorkspace(this.request);

    Future<Either<WorkspacePB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CreateWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(WorkspacePB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadCurrentWorkspace {
    FolderEventReadCurrentWorkspace();

    Future<Either<WorkspaceSettingPB, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.ReadCurrentWorkspace.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(WorkspaceSettingPB.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventReadWorkspaces {
     WorkspaceIdPB request;
     FolderEventReadWorkspaces(this.request);

    Future<Either<RepeatedWorkspacePB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadWorkspaces.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedWorkspacePB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteWorkspace {
     WorkspaceIdPB request;
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
     WorkspaceIdPB request;
     FolderEventOpenWorkspace(this.request);

    Future<Either<WorkspacePB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.OpenWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(WorkspacePB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadWorkspaceApps {
     WorkspaceIdPB request;
     FolderEventReadWorkspaceApps(this.request);

    Future<Either<RepeatedAppPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadWorkspaceApps.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedAppPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventCreateApp {
     CreateAppPayloadPB request;
     FolderEventCreateApp(this.request);

    Future<Either<AppPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CreateApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(AppPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteApp {
     AppIdPB request;
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
     AppIdPB request;
     FolderEventReadApp(this.request);

    Future<Either<AppPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(AppPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventUpdateApp {
     UpdateAppPayloadPB request;
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
     CreateViewPayloadPB request;
     FolderEventCreateView(this.request);

    Future<Either<ViewPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.CreateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ViewPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventReadView {
     ViewIdPB request;
     FolderEventReadView(this.request);

    Future<Either<ViewPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ViewPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventUpdateView {
     UpdateViewPayloadPB request;
     FolderEventUpdateView(this.request);

    Future<Either<ViewPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.UpdateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ViewPB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventDeleteView {
     RepeatedViewIdPB request;
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
     ViewPB request;
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

class FolderEventCloseView {
     ViewIdPB request;
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

class FolderEventReadViewInfo {
     ViewIdPB request;
     FolderEventReadViewInfo(this.request);

    Future<Either<ViewInfoPB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ReadViewInfo.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(ViewInfoPB.fromBuffer(okBytes)),
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

class FolderEventSetLatestView {
     ViewIdPB request;
     FolderEventSetLatestView(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.SetLatestView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventMoveFolderItem {
     MoveFolderItemPayloadPB request;
     FolderEventMoveFolderItem(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.MoveFolderItem.toString()
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

    Future<Either<RepeatedTrashPB, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = FolderEvent.ReadTrash.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(RepeatedTrashPB.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class FolderEventPutbackTrash {
     TrashIdPB request;
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
     RepeatedTrashIdPB request;
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

