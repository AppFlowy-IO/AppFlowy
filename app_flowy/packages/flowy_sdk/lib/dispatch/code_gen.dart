

/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';
class UserEventGetStatus {
    UserEventGetStatus();

    Future<Either<UserDetail, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetStatus.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(UserDetail.fromBuffer(bytes)),
        (error) => right(error),
      ));
    }
}

class UserEventSignIn {
     SignInRequest request;
     UserEventSignIn(this.request);

    Future<Either<UserDetail, FlowyError>> send() {
     return requestToBytes(request).fold(
         (bytes) {
            final request = FFIRequest.create()
             ..event = UserEvent.SignIn.toString()
             ..payload = bytes;

           return Dispatch.asyncRequest(request)
               .then((bytesResult) => bytesResult.fold(
                 (bytes) => left(UserDetail.fromBuffer(bytes)),
                 (error) => right(error),
               ));
         },
         (err) => Future(() => right(err)),
       );
    }
}

class UserEventSignUp {
     SignUpRequest request;
     UserEventSignUp(this.request);

    Future<Either<UserDetail, FlowyError>> send() {
     return requestToBytes(request).fold(
         (bytes) {
            final request = FFIRequest.create()
             ..event = UserEvent.SignUp.toString()
             ..payload = bytes;

           return Dispatch.asyncRequest(request)
               .then((bytesResult) => bytesResult.fold(
                 (bytes) => left(UserDetail.fromBuffer(bytes)),
                 (error) => right(error),
               ));
         },
         (err) => Future(() => right(err)),
       );
    }
}

class UserEventSignOut {
    UserEventSignOut();

    Future<Either<Uint8List, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.SignOut.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (bytes) => left(bytes),
        (error) => right(error),
      ));
    }
}

