///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserEvent extends $pb.ProtobufEnum {
  static const UserEvent InitUser = UserEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InitUser');
  static const UserEvent SignIn = UserEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SignIn');
  static const UserEvent SignUp = UserEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SignUp');
  static const UserEvent SignOut = UserEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SignOut');
  static const UserEvent UpdateUser = UserEvent._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateUser');
  static const UserEvent GetUserProfile = UserEvent._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetUserProfile');

  static const $core.List<UserEvent> values = <UserEvent> [
    InitUser,
    SignIn,
    SignUp,
    SignOut,
    UpdateUser,
    GetUserProfile,
  ];

  static final $core.Map<$core.int, UserEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserEvent? valueOf($core.int value) => _byValue[value];

  const UserEvent._($core.int v, $core.String n) : super(v, n);
}

