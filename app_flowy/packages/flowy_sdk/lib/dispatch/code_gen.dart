/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';

class UserEventAuthCheck {
  UserSignInParams params;
  UserEventAuthCheck(this.params);

  Future<Either<UserSignInResult, FlowyError>> send() {
    return paramsToBytes(params).fold(
      (bytes) {
        final request = FFIRequest.create()
          ..event = UserEvent.AuthCheck.toString()
          ..payload = bytes;

        return Dispatch.asyncRequest(request)
            .then((bytesResult) => bytesResult.fold(
                  (bytes) => left(UserSignInResult.fromBuffer(bytes)),
                  (error) => right(error),
                ));
      },
      (err) => Future(() => right(err)),
    );
  }
}

class UserEventSignIn {
  UserSignInParams params;
  UserEventSignIn(this.params);

  Future<Either<UserSignInResult, FlowyError>> send() {
    return paramsToBytes(params).fold(
      (bytes) {
        final request = FFIRequest.create()
          ..event = UserEvent.SignIn.toString()
          ..payload = bytes;

        return Dispatch.asyncRequest(request)
            .then((bytesResult) => bytesResult.fold(
                  (bytes) => left(UserSignInResult.fromBuffer(bytes)),
                  (error) => right(error),
                ));
      },
      (err) => Future(() => right(err)),
    );
  }
}
