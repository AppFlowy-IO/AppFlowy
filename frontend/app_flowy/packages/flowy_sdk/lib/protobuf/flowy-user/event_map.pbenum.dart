///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserEvent extends $pb.ProtobufEnum {
  static const UserEvent InitUser = UserEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InitUser');
  static const UserEvent SignIn = UserEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SignIn');
  static const UserEvent SignUp = UserEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SignUp');
  static const UserEvent SignOut = UserEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SignOut');
  static const UserEvent UpdateUserProfile = UserEvent._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateUserProfile');
  static const UserEvent GetUserProfile = UserEvent._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetUserProfile');
  static const UserEvent CheckUser = UserEvent._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CheckUser');
  static const UserEvent SetAppearanceSetting = UserEvent._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SetAppearanceSetting');
  static const UserEvent GetAppearanceSetting = UserEvent._(8, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetAppearanceSetting');
  static const UserEvent GetUserSetting = UserEvent._(9, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetUserSetting');

  static const $core.List<UserEvent> values = <UserEvent> [
    InitUser,
    SignIn,
    SignUp,
    SignOut,
    UpdateUserProfile,
    GetUserProfile,
    CheckUser,
    SetAppearanceSetting,
    GetAppearanceSetting,
    GetUserSetting,
  ];

  static final $core.Map<$core.int, UserEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserEvent? valueOf($core.int value) => _byValue[value];

  const UserEvent._($core.int v, $core.String n) : super(v, n);
}

