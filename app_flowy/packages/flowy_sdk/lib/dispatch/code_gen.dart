

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

class WorkspaceEventReadWorkspace {
     QueryWorkspaceRequest request;
     WorkspaceEventReadWorkspace(this.request);

    Future<Either<Workspace, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.ReadWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Workspace.fromBuffer(okBytes)),
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

class WorkspaceEventReadAllWorkspace {
    WorkspaceEventReadAllWorkspace();

    Future<Either<Workspaces, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.ReadAllWorkspace.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(Workspaces.fromBuffer(okBytes)),
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

    Future<Either<Unit, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.UpdateView.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
        ));
    }
}

class WorkspaceEventDeleteView {
     DeleteViewRequest request;
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

class EditorEventCreateDoc {
     CreateDocRequest request;
     EditorEventCreateDoc(this.request);

    Future<Either<DocInfo, DocError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.CreateDoc.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocInfo.fromBuffer(okBytes)),
           (errBytes) => right(DocError.fromBuffer(errBytes)),
        ));
    }
}

class EditorEventUpdateDoc {
     UpdateDocRequest request;
     EditorEventUpdateDoc(this.request);

    Future<Either<Unit, DocError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.UpdateDoc.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(DocError.fromBuffer(errBytes)),
        ));
    }
}

class EditorEventReadDocInfo {
     QueryDocRequest request;
     EditorEventReadDocInfo(this.request);

    Future<Either<DocInfo, DocError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.ReadDocInfo.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocInfo.fromBuffer(okBytes)),
           (errBytes) => right(DocError.fromBuffer(errBytes)),
        ));
    }
}

class EditorEventReadDocData {
     QueryDocDataRequest request;
     EditorEventReadDocData(this.request);

    Future<Either<DocData, DocError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.ReadDocData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocData.fromBuffer(okBytes)),
           (errBytes) => right(DocError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventGetStatus {
    UserEventGetStatus();

    Future<Either<UserDetail, UserError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetStatus.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserDetail.fromBuffer(okBytes)),
        (errBytes) => right(UserError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventSignIn {
     SignInRequest request;
     UserEventSignIn(this.request);

    Future<Either<UserDetail, UserError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignIn.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserDetail.fromBuffer(okBytes)),
           (errBytes) => right(UserError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventSignUp {
     SignUpRequest request;
     UserEventSignUp(this.request);

    Future<Either<UserDetail, UserError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignUp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserDetail.fromBuffer(okBytes)),
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

    Future<Either<UserDetail, UserError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.UpdateUser.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserDetail.fromBuffer(okBytes)),
           (errBytes) => right(UserError.fromBuffer(errBytes)),
        ));
    }
}

