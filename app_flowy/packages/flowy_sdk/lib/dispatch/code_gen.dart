/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';

class UserEventSignIn {
  UserSignInParams payload;

  UserEventSignIn(this.payload);
  Future<Either<UserSignInResult, FlowyError>> send() {
    var request = FFIRequest.create()..event = UserEvent.SignIn.toString();
    return protobufToBytes(payload).fold(
      (payload) {
        request.payload = payload;
        return Dispatch.asyncRequest(request).then((response) {
          try {
            if (response.code != FFIStatusCode.Ok) {
              return right(FlowyError.from(response));
            } else {
              final pb = UserSignInResult.fromBuffer(response.payload);
              return left(pb);
            }
          } catch (e, s) {
            final error =
                FlowyError.fromError('${e.runtimeType}. Stack trace: $s');
            return right(error);
          }
        });
      },
      (err) => Future(() {
        return right(FlowyError.fromError(err));
      }),
    );
  }
}
