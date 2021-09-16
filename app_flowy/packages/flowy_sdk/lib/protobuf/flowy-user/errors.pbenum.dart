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
  static const ErrorCode EmailIsEmpty = ErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailIsEmpty');
  static const ErrorCode EmailFormatInvalid = ErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailFormatInvalid');
  static const ErrorCode EmailAlreadyExists = ErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailAlreadyExists');
  static const ErrorCode PasswordIsEmpty = ErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordIsEmpty');
  static const ErrorCode PasswordTooLong = ErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordTooLong');
  static const ErrorCode PasswordContainsForbidCharacters = ErrorCode._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordContainsForbidCharacters');
  static const ErrorCode PasswordFormatInvalid = ErrorCode._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordFormatInvalid');
  static const ErrorCode PasswordNotMatch = ErrorCode._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordNotMatch');
  static const ErrorCode UserNameTooLong = ErrorCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameTooLong');
  static const ErrorCode UserNameContainForbiddenCharacters = ErrorCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameContainForbiddenCharacters');
  static const ErrorCode UserNameIsEmpty = ErrorCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameIsEmpty');
  static const ErrorCode UserIdInvalid = ErrorCode._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');
  static const ErrorCode UserUnauthorized = ErrorCode._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const ErrorCode UserNotExist = ErrorCode._(25, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotExist');
  static const ErrorCode InternalError = ErrorCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InternalError');

  static const $core.List<ErrorCode> values = <ErrorCode> [
    EmailIsEmpty,
    EmailFormatInvalid,
    EmailAlreadyExists,
    PasswordIsEmpty,
    PasswordTooLong,
    PasswordContainsForbidCharacters,
    PasswordFormatInvalid,
    PasswordNotMatch,
    UserNameTooLong,
    UserNameContainForbiddenCharacters,
    UserNameIsEmpty,
    UserIdInvalid,
    UserUnauthorized,
    UserNotExist,
    InternalError,
  ];

  static final $core.Map<$core.int, ErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorCode? valueOf($core.int value) => _byValue[value];

  const ErrorCode._($core.int v, $core.String n) : super(v, n);
}

