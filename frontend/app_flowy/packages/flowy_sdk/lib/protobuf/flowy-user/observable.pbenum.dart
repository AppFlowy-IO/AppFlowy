///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserNotification extends $pb.ProtobufEnum {
  static const UserNotification Unknown = UserNotification._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const UserNotification UserAuthChanged = UserNotification._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserAuthChanged');
  static const UserNotification UserProfileUpdated = UserNotification._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserProfileUpdated');
  static const UserNotification UserUnauthorized = UserNotification._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');

  static const $core.List<UserNotification> values = <UserNotification> [
    Unknown,
    UserAuthChanged,
    UserProfileUpdated,
    UserUnauthorized,
  ];

  static final $core.Map<$core.int, UserNotification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserNotification? valueOf($core.int value) => _byValue[value];

  const UserNotification._($core.int v, $core.String n) : super(v, n);
}

