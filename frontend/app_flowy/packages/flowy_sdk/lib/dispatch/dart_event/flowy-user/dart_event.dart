
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
     SignInPayloadPB request;
     UserEventSignIn(this.request);

    Future<Either<UserProfilePB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignIn.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserProfilePB.fromBuffer(okBytes)),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

class UserEventSignUp {
     SignUpPayloadPB request;
     UserEventSignUp(this.request);

    Future<Either<UserProfilePB, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.SignUp.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (okBytes) => left(UserProfilePB.fromBuffer(okBytes)),
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

class UserEventUpdateUserProfile {
     UpdateUserProfilePayloadPB request;
     UserEventUpdateUserProfile(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = UserEvent.UpdateUserProfile.toString()
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

    Future<Either<UserProfilePB, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetUserProfile.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserProfilePB.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventCheckUser {
    UserEventCheckUser();

    Future<Either<UserProfilePB, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.CheckUser.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserProfilePB.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventSetAppearanceSetting {
     AppearanceSettingsPB request;
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

    Future<Either<AppearanceSettingsPB, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetAppearanceSetting.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(AppearanceSettingsPB.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

class UserEventGetUserSetting {
    UserEventGetUserSetting();

    Future<Either<UserSettingPB, FlowyError>> send() {
     final request = FFIRequest.create()
        ..event = UserEvent.GetUserSetting.toString();

     return Dispatch.asyncRequest(request).then((bytesResult) => bytesResult.fold(
        (okBytes) => left(UserSettingPB.fromBuffer(okBytes)),
        (errBytes) => right(FlowyError.fromBuffer(errBytes)),
      ));
    }
}

