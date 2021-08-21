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
  static const UserErrCode EmailIsEmpty = UserErrCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailIsEmpty');
  static const UserErrCode EmailFormatInvalid = UserErrCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailFormatInvalid');
  static const UserErrCode EmailAlreadyExists = UserErrCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailAlreadyExists');
  static const UserErrCode PasswordIsEmpty = UserErrCode._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordIsEmpty');
  static const UserErrCode PasswordTooLong = UserErrCode._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordTooLong');
  static const UserErrCode PasswordContainsForbidCharacters = UserErrCode._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordContainsForbidCharacters');
  static const UserErrCode PasswordFormatInvalid = UserErrCode._(33, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordFormatInvalid');
  static const UserErrCode UserNameTooLong = UserErrCode._(40, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameTooLong');
  static const UserErrCode UserNameContainsForbiddenCharacters = UserErrCode._(41, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameContainsForbiddenCharacters');
  static const UserErrCode UserNameIsEmpty = UserErrCode._(42, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameIsEmpty');
  static const UserErrCode UserWorkspaceInvalid = UserErrCode._(50, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserWorkspaceInvalid');
  static const UserErrCode UserIdInvalid = UserErrCode._(51, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');
  static const UserErrCode CreateDefaultWorkspaceFailed = UserErrCode._(52, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateDefaultWorkspaceFailed');
  static const UserErrCode DefaultWorkspaceAlreadyExist = UserErrCode._(53, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DefaultWorkspaceAlreadyExist');
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
    EmailIsEmpty,
    EmailFormatInvalid,
    EmailAlreadyExists,
    PasswordIsEmpty,
    PasswordTooLong,
    PasswordContainsForbidCharacters,
    PasswordFormatInvalid,
    UserNameTooLong,
    UserNameContainsForbiddenCharacters,
    UserNameIsEmpty,
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

