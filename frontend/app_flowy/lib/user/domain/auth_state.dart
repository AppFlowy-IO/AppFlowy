import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.authenticated(UserProfile userProfile) = Authenticated;
  const factory AuthState.unauthenticated(UserError error) = Unauthenticated;
  const factory AuthState.initial() = _Initial;
}
