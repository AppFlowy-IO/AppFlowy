

/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';
class EditorEventCreateDoc {
     CreateDocRequest request;
     EditorEventCreateDoc(this.request);

    Future<Either<DocInfo, EditorError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.CreateDoc.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocInfo.fromBuffer(okBytes)),
           (errBytes) => right(EditorError.fromBuffer(errBytes)),
        ));
    }
}

class EditorEventUpdateDoc {
     UpdateDocRequest request;
     EditorEventUpdateDoc(this.request);

    Future<Either<Unit, EditorError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.UpdateDoc.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(EditorError.fromBuffer(errBytes)),
        ));
    }
}

class EditorEventReadDocInfo {
     QueryDocRequest request;
     EditorEventReadDocInfo(this.request);

    Future<Either<DocInfo, EditorError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.ReadDocInfo.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocInfo.fromBuffer(okBytes)),
           (errBytes) => right(EditorError.fromBuffer(errBytes)),
        ));
    }
}

class EditorEventReadDocData {
     QueryDocDataRequest request;
     EditorEventReadDocData(this.request);

    Future<Either<DocData, EditorError>> send() {
    final request = FFIRequest.create()
          ..event = EditorEvent.ReadDocData.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(DocData.fromBuffer(okBytes)),
           (errBytes) => right(EditorError.fromBuffer(errBytes)),
        ));
    }
}

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

class WorkspaceEventGetCurWorkspace {
    WorkspaceEventGetCurWorkspace();

    Future<Either<Workspace, WorkspaceError>> send() {
     final request = FFIRequest.create()
        ..event = WorkspaceEvent.GetCurWorkspace.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(Workspace.fromBuffer(okBytes)),
        (errBytes) => right(WorkspaceError.fromBuffer(errBytes)),
      ));
    }
}

class WorkspaceEventGetWorkspace {
     QueryWorkspaceRequest request;
     WorkspaceEventGetWorkspace(this.request);

    Future<Either<Workspace, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.GetWorkspace.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(Workspace.fromBuffer(okBytes)),
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

class WorkspaceEventGetApp {
     QueryAppRequest request;
     WorkspaceEventGetApp(this.request);

    Future<Either<App, WorkspaceError>> send() {
    final request = FFIRequest.create()
          ..event = WorkspaceEvent.GetApp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(App.fromBuffer(okBytes)),
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

