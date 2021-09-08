///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode Unknown = ErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const ErrorCode UserDatabaseInitFailed = ErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseInitFailed');
  static const ErrorCode AcquireWriteLockedFailed = ErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AcquireWriteLockedFailed');
  static const ErrorCode AcquireReadLockedFailed = ErrorCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AcquireReadLockedFailed');
  static const ErrorCode UserDatabaseDidNotMatch = ErrorCode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDatabaseDidNotMatch');
  static const ErrorCode EmailIsEmpty = ErrorCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailIsEmpty');
  static const ErrorCode EmailFormatInvalid = ErrorCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailFormatInvalid');
  static const ErrorCode EmailAlreadyExists = ErrorCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailAlreadyExists');
  static const ErrorCode PasswordIsEmpty = ErrorCode._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordIsEmpty');
  static const ErrorCode PasswordTooLong = ErrorCode._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordTooLong');
  static const ErrorCode PasswordContainsForbidCharacters = ErrorCode._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordContainsForbidCharacters');
  static const ErrorCode PasswordFormatInvalid = ErrorCode._(33, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordFormatInvalid');
  static const ErrorCode PasswordNotMatch = ErrorCode._(34, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordNotMatch');
  static const ErrorCode UserNameTooLong = ErrorCode._(40, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameTooLong');
  static const ErrorCode ContainForbiddenCharacters = ErrorCode._(41, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ContainForbiddenCharacters');
  static const ErrorCode UserNameIsEmpty = ErrorCode._(42, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameIsEmpty');
  static const ErrorCode UserWorkspaceInvalid = ErrorCode._(50, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserWorkspaceInvalid');
  static const ErrorCode UserIdInvalid = ErrorCode._(51, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');
  static const ErrorCode UserUnauthorized = ErrorCode._(54, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const ErrorCode UserNotExist = ErrorCode._(55, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotExist');
  static const ErrorCode InternalError = ErrorCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InternalError');

  static const $core.List<ErrorCode> values = <ErrorCode> [
    Unknown,
    UserDatabaseInitFailed,
    AcquireWriteLockedFailed,
    AcquireReadLockedFailed,
    UserDatabaseDidNotMatch,
    EmailIsEmpty,
    EmailFormatInvalid,
    EmailAlreadyExists,
    PasswordIsEmpty,
    PasswordTooLong,
    PasswordContainsForbidCharacters,
    PasswordFormatInvalid,
    PasswordNotMatch,
    UserNameTooLong,
    ContainForbiddenCharacters,
    UserNameIsEmpty,
    UserWorkspaceInvalid,
    UserIdInvalid,
    UserUnauthorized,
    UserNotExist,
    InternalError,
  ];

  static final $core.Map<$core.int, ErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorCode? valueOf($core.int value) => _byValue[value];

  const ErrorCode._($core.int v, $core.String n) : super(v, n);
}

