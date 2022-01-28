

/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';
class FolderEventCreateWorkspace {
     CreateWorkspaceRequest request;
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
     QueryWorkspaceRequest request;
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
     QueryWorkspaceRequest request;
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
     QueryWorkspaceRequest request;
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
     QueryWorkspaceRequest request;
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
     CreateAppRequest request;
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
     QueryAppRequest request;
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
     QueryAppRequest request;
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
     UpdateAppRequest request;
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
     CreateViewRequest request;
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
     QueryViewRequest request;
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
     UpdateViewRequest request;
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
     QueryViewRequest request;
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
     QueryViewRequest request;
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

class FolderEventOpenDocument {
     QueryViewRequest request;
     FolderEventOpenDocument(this.request);

    Future<Either<DocumentDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.OpenDocument.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocumentDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventCloseView {
     QueryViewRequest request;
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
     DocumentDelta request;
     FolderEventApplyDocDelta(this.request);

    Future<Either<DocumentDelta, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = FolderEvent.ApplyDocDelta.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocumentDelta.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class FolderEventExportDocument {
     ExportRequest request;
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

class NetworkEventUpdateNetworkType {
     NetworkState request;
     NetworkEventUpdateNetworkType(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = NetworkEvent.UpdateNetworkType.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventInitUser {
    UserEventInitUser();

    Future<Either<Unit, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.InitUser.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventSignIn {
     SignInRequest request;
     UserEventSignIn(this.request);

    Future<Either<UserProfile, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignIn.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserProfile.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventSignUp {
     SignUpRequest request;
     UserEventSignUp(this.request);

    Future<Either<UserProfile, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignUp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserProfile.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventSignOut {
    UserEventSignOut();

    Future<Either<Unit, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.SignOut.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventUpdateUser {
     UpdateUserRequest request;
     UserEventUpdateUser(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.UpdateUser.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventGetUserProfile {
    UserEventGetUserProfile();

    Future<Either<UserProfile, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetUserProfile.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserProfile.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventCheckUser {
    UserEventCheckUser();

    Future<Either<UserProfile, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.CheckUser.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserProfile.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventUpdateAppearanceSetting {
     AppearanceSettings request;
     UserEventUpdateAppearanceSetting(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.UpdateAppearanceSetting.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventGetAppearanceSetting {
    UserEventGetAppearanceSetting();

    Future<Either<AppearanceSettings, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetAppearanceSetting.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(AppearanceSettings.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

