///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class UserErrCode extends $pb.ProtobufEnum {
  static const UserErrCode Unknown = UserErrCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const UserErrCode UserDatabaseInitFailed = UserErrCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseInitFailed');
  static const UserErrCode UserDatabaseWriteLocked = UserErrCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseWriteLocked');
  static const UserErrCode UserDatabaseReadLocked = UserErrCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseReadLocked');
  static const UserErrCode UserDatabaseDidNotMatch = UserErrCode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseDidNotMatch');
  static const UserErrCode UserDatabaseInternalError = UserErrCode._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseInternalError');
  static const UserErrCode SqlInternalError = UserErrCode._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SqlInternalError');
  static const UserErrCode UserNotLoginYet = UserErrCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotLoginYet');
  static const UserErrCode ReadCurrentIdFailed = UserErrCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadCurrentIdFailed');
  static const UserErrCode WriteCurrentIdFailed = UserErrCode._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WriteCurrentIdFailed');
  static const UserErrCode EmailInvalid = UserErrCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailInvalid');
  static const UserErrCode PasswordInvalid = UserErrCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordInvalid');
  static const UserErrCode UserNameInvalid = UserErrCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameInvalid');
  static const UserErrCode UserWorkspaceInvalid = UserErrCode._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserWorkspaceInvalid');
  static const UserErrCode UserIdInvalid = UserErrCode._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');
  static const UserErrCode CreateDefaultWorkspaceFailed = UserErrCode._(25, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateDefaultWorkspaceFailed');
  static const UserErrCode DefaultWorkspaceAlreadyExist = UserErrCode._(26, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DefaultWorkspaceAlreadyExist');
  static const UserErrCode NetworkError = UserErrCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NetworkError');

  static const $core.List<UserErrCode> values = <UserErrCode> [
    Unknown,
    UserDatabaseInitFailed,
    UserDatabaseWriteLocked,
    UserDatabaseReadLocked,
    UserDatabaseDidNotMatch,
    UserDatabaseInternalError,
    SqlInternalError,
    UserNotLoginYet,
    ReadCurrentIdFailed,
    WriteCurrentIdFailed,
    EmailInvalid,
    PasswordInvalid,
    UserNameInvalid,
    UserWorkspaceInvalid,
    UserIdInvalid,
    CreateDefaultWorkspaceFailed,
    DefaultWorkspaceAlreadyExist,
    NetworkError,
  ];

  static final $core.Map<$core.int, UserErrCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UserErrCode? valueOf($core.int value) => _byValue[value];

  const UserErrCode._($core.int v, $core.String n) : super(v, n);
}

