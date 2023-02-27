import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.authenticated(UserProfilePB userProfile) =
      Authenticated;
  const factory AuthState.unauthenticated(FlowyError error) = Unauthenticated;
  const factory AuthState.initial() = _Initial;
}
