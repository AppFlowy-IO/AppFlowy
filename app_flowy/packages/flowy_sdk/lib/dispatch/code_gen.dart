

/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';
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

