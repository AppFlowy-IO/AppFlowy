///
//  Generated code. Do not modify.
//  source: code.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode Internal = ErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Internal');
  static const ErrorCode UserUnauthorized = ErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const ErrorCode RecordNotFound = ErrorCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RecordNotFound');
  static const ErrorCode WorkspaceNameInvalid = ErrorCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameInvalid');
  static const ErrorCode WorkspaceIdInvalid = ErrorCode._(101, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceIdInvalid');
  static const ErrorCode AppColorStyleInvalid = ErrorCode._(102, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppColorStyleInvalid');
  static const ErrorCode WorkspaceDescTooLong = ErrorCode._(103, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDescTooLong');
  static const ErrorCode WorkspaceNameTooLong = ErrorCode._(104, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameTooLong');
  static const ErrorCode AppIdInvalid = ErrorCode._(110, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppIdInvalid');
  static const ErrorCode AppNameInvalid = ErrorCode._(111, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppNameInvalid');
  static const ErrorCode ViewNameInvalid = ErrorCode._(120, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameInvalid');
  static const ErrorCode ViewThumbnailInvalid = ErrorCode._(121, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewThumbnailInvalid');
  static const ErrorCode ViewIdInvalid = ErrorCode._(122, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewIdInvalid');
  static const ErrorCode ViewDescTooLong = ErrorCode._(123, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDescTooLong');
  static const ErrorCode ViewDataInvalid = ErrorCode._(124, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDataInvalid');
  static const ErrorCode ViewNameTooLong = ErrorCode._(125, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameTooLong');
  static const ErrorCode ConnectError = ErrorCode._(200, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ConnectError');
  static const ErrorCode EmailIsEmpty = ErrorCode._(300, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailIsEmpty');
  static const ErrorCode EmailFormatInvalid = ErrorCode._(301, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailFormatInvalid');
  static const ErrorCode EmailAlreadyExists = ErrorCode._(302, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailAlreadyExists');
  static const ErrorCode PasswordIsEmpty = ErrorCode._(303, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordIsEmpty');
  static const ErrorCode PasswordTooLong = ErrorCode._(304, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordTooLong');
  static const ErrorCode PasswordContainsForbidCharacters = ErrorCode._(305, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordContainsForbidCharacters');
  static const ErrorCode PasswordFormatInvalid = ErrorCode._(306, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordFormatInvalid');
  static const ErrorCode PasswordNotMatch = ErrorCode._(307, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordNotMatch');
  static const ErrorCode UserNameTooLong = ErrorCode._(308, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameTooLong');
  static const ErrorCode UserNameContainForbiddenCharacters = ErrorCode._(309, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameContainForbiddenCharacters');
  static const ErrorCode UserNameIsEmpty = ErrorCode._(310, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameIsEmpty');
  static const ErrorCode UserIdInvalid = ErrorCode._(311, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');
  static const ErrorCode UserNotExist = ErrorCode._(312, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotExist');
  static const ErrorCode TextTooLong = ErrorCode._(400, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TextTooLong');
  static const ErrorCode InvalidData = ErrorCode._(401, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InvalidData');

  static const $core.List<ErrorCode> values = <ErrorCode> [
    Internal,
    UserUnauthorized,
    RecordNotFound,
    WorkspaceNameInvalid,
    WorkspaceIdInvalid,
    AppColorStyleInvalid,
    WorkspaceDescTooLong,
    WorkspaceNameTooLong,
    AppIdInvalid,
    AppNameInvalid,
    ViewNameInvalid,
    ViewThumbnailInvalid,
    ViewIdInvalid,
    ViewDescTooLong,
    ViewDataInvalid,
    ViewNameTooLong,
    ConnectError,
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
    UserNotExist,
    TextTooLong,
    InvalidData,
  ];

  static final $core.Map<$core.int, ErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorCode? valueOf($core.int value) => _byValue[value];

  const ErrorCode._($core.int v, $core.String n) : super(v, n);
}

