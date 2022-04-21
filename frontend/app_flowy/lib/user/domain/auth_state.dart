import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.authenticated(UserProfile userProfile) = Authenticated;
  const factory AuthState.unauthenticated(FlowyError error) = Unauthenticated;
  const factory AuthState.initial() = _Initial;
}
