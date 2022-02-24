
/// Auto generate. Do not edit
part of '../../dispatch.dart';
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
     SignInPayload request;
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
     SignUpPayload request;
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
     UpdateUserPayload request;
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

class UserEventSetAppearanceSetting {
     AppearanceSettings request;
     UserEventSetAppearanceSetting(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SetAppearanceSetting.toString()
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

