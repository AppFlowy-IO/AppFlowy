import 'package:flowy_sdk/protobuf/errors.pb.dart';
import 'package:flowy_sdk/protobuf/user_detail.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.authenticated(UserDetail userDetail) = Authenticated;
  const factory AuthState.unauthenticated(UserError error) = Unauthenticated;
  const factory AuthState.initial() = _Initial;
}
