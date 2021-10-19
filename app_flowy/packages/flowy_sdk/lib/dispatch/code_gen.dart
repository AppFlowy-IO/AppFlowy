

/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';
class WorkspaceEventCreateWorkspace {
     CreateWorkspaceRequest request;
     WorkspaceEventCreateWorkspace(this.request);

    Future<Either<Workspace, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.CreateWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Workspace.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventReadCurWorkspace {
    WorkspaceEventReadCurWorkspace();

    Future<Either<Workspace, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.ReadCurWorkspace.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(Workspace.fromBuffer(okBytes)),
        (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
      ));
    }
}

class WorkspaceEventReadWorkspaces {
     QueryWorkspaceRequest request;
     WorkspaceEventReadWorkspaces(this.request);

    Future<Either<RepeatedWorkspace, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.ReadWorkspaces.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedWorkspace.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventDeleteWorkspace {
     DeleteWorkspaceRequest request;
     WorkspaceEventDeleteWorkspace(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.DeleteWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventOpenWorkspace {
     QueryWorkspaceRequest request;
     WorkspaceEventOpenWorkspace(this.request);

    Future<Either<Workspace, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.OpenWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Workspace.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventReadWorkspaceApps {
     QueryWorkspaceRequest request;
     WorkspaceEventReadWorkspaceApps(this.request);

    Future<Either<RepeatedApp, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.ReadWorkspaceApps.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(RepeatedApp.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventCreateApp {
     CreateAppRequest request;
     WorkspaceEventCreateApp(this.request);

    Future<Either<App, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.CreateApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(App.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventDeleteApp {
     DeleteAppRequest request;
     WorkspaceEventDeleteApp(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.DeleteApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventReadApp {
     QueryAppRequest request;
     WorkspaceEventReadApp(this.request);

    Future<Either<App, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.ReadApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(App.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventUpdateApp {
     UpdateAppRequest request;
     WorkspaceEventUpdateApp(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.UpdateApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventCreateView {
     CreateViewRequest request;
     WorkspaceEventCreateView(this.request);

    Future<Either<View, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.CreateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(View.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventReadView {
     QueryViewRequest request;
     WorkspaceEventReadView(this.request);

    Future<Either<View, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.ReadView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(View.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventUpdateView {
     UpdateViewRequest request;
     WorkspaceEventUpdateView(this.request);

    Future<Either<View, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.UpdateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(View.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventDeleteView {
     QueryViewRequest request;
     WorkspaceEventDeleteView(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.DeleteView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventOpenView {
     QueryViewRequest request;
     WorkspaceEventOpenView(this.request);

    Future<Either<DocDelta, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.OpenView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocDelta.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventCloseView {
     QueryViewRequest request;
     WorkspaceEventCloseView(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.CloseView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventApplyDocDelta {
     DocDelta request;
     WorkspaceEventApplyDocDelta(this.request);

    Future<Either<DocDelta, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.ApplyDocDelta.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocDelta.fromBuffer(okBytes)),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventReadTrash {
    WorkspaceEventReadTrash();

    Future<Either<RepeatedTrash, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.ReadTrash.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(RepeatedTrash.fromBuffer(okBytes)),
        (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
      ));
    }
}

class WorkspaceEventPutbackTrash {
     TrashIdentifier request;
     WorkspaceEventPutbackTrash(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.PutbackTrash.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventDeleteTrash {
     TrashIdentifiers request;
     WorkspaceEventDeleteTrash(this.request);

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.DeleteTrash.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventRestoreAll {
    WorkspaceEventRestoreAll();

    Future<Either<Unit, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.RestoreAll.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
      ));
    }
}

class WorkspaceEventDeleteAll {
    WorkspaceEventDeleteAll();

    Future<Either<Unit, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.DeleteAll.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
      ));
    }
}

class WorkspaceEventInitWorkspace {
    WorkspaceEventInitWorkspace();

    Future<Either<Unit, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.InitWorkspace.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventInitUser {
    UserEventInitUser();

    Future<Either<Unit, UserError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.InitUser.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(UserError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventSignIn {
     SignInRequest request;
     UserEventSignIn(this.request);

    Future<Either<UserProfile, UserError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignIn.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserProfile.fromBuffer(okBytes)),
           (errBytes) => right(UserError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventSignUp {
     SignUpRequest request;
     UserEventSignUp(this.request);

    Future<Either<UserProfile, UserError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignUp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserProfile.fromBuffer(okBytes)),
           (errBytes) => right(UserError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventSignOut {
    UserEventSignOut();

    Future<Either<Unit, UserError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.SignOut.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(unit),
        (errBytes) => right(UserError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventUpdateUser {
     UpdateUserRequest request;
     UserEventUpdateUser(this.request);

    Future<Either<Unit, UserError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.UpdateUser.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(UserError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventGetUserProfile {
    UserEventGetUserProfile();

    Future<Either<UserProfile, UserError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetUserProfile.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserProfile.fromBuffer(okBytes)),
        (errBytes) => right(UserError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventCheckUser {
    UserEventCheckUser();

    Future<Either<UserProfile, UserError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.CheckUser.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserProfile.fromBuffer(okBytes)),
        (errBytes) => right(UserError.fromBuffer(errBytes)),
      ));
    }
}

