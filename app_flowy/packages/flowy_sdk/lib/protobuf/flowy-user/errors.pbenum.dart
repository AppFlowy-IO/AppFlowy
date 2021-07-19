///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserErrorCode extends $pb.ProtobufEnum {
  static const UserErrorCode Unknown = UserErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const UserErrorCode UserDatabaseInitFailed = UserErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseInitFailed');
  static const UserErrorCode UserDatabaseWriteLocked = UserErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseWriteLocked');
  static const UserErrorCode UserDatabaseReadLocked = UserErrorCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseReadLocked');
  static const UserErrorCode UserDatabaseDidNotMatch = UserErrorCode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseDidNotMatch');
  static const UserErrorCode UserDatabaseInternalError = UserErrorCode._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseInternalError');
  static const UserErrorCode UserNotLoginYet = UserErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotLoginYet');
  static const UserErrorCode ReadCurrentIdFailed = UserErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadCurrentIdFailed');
  static const UserErrorCode WriteCurrentIdFailed = UserErrorCode._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WriteCurrentIdFailed');
  static const UserErrorCode EmailInvalid = UserErrorCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailInvalid');
  static const UserErrorCode PasswordInvalid = UserErrorCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordInvalid');
  static const UserErrorCode UserNameInvalid = UserErrorCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameInvalid');
  static const UserErrorCode UserWorkspaceInvalid = UserErrorCode._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserWorkspaceInvalid');
  static const UserErrorCode UserIdInvalid = UserErrorCode._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');

  static const $core.List<UserErrorCode> values = <UserErrorCode> [
    Unknown,
    UserDatabaseInitFailed,
    UserDatabaseWriteLocked,
    UserDatabaseReadLocked,
    UserDatabaseDidNotMatch,
    UserDatabaseInternalError,
    UserNotLoginYet,
    ReadCurrentIdFailed,
    WriteCurrentIdFailed,
    EmailInvalid,
    PasswordInvalid,
    UserNameInvalid,
    UserWorkspaceInvalid,
    UserIdInvalid,
  ];

  static final $core.Map<$core.int, UserErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserErrorCode? valueOf($core.int value) => _byValue[value];

  const UserErrorCode._($core.int v, $core.String n) : super(v, n);
}

