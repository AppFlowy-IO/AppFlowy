///
//  Generated code. Do not modify.
//  source: user_profile.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserStatus extends $pb.ProtobufEnum {
  static const UserStatus Unknown = UserStatus._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const UserStatus Login = UserStatus._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Login');
  static const UserStatus Expired = UserStatus._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Expired');

  static const $core.List<UserStatus> values = <UserStatus> [
    Unknown,
    Login,
    Expired,
  ];

  static final $core.Map<$core.int, UserStatus> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserStatus? valueOf($core.int value) => _byValue[value];

  const UserStatus._($core.int v, $core.String n) : super(v, n);
}

