///
//  Generated code. Do not modify.
//  source: code.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode Internal = ErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Internal');
  static const ErrorCode UserUnauthorized = ErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const ErrorCode RecordNotFound = ErrorCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RecordNotFound');
  static const ErrorCode UserIdIsEmpty = ErrorCode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdIsEmpty');
  static const ErrorCode WorkspaceNameInvalid = ErrorCode._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameInvalid');
  static const ErrorCode WorkspaceIdInvalid = ErrorCode._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceIdInvalid');
  static const ErrorCode AppColorStyleInvalid = ErrorCode._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppColorStyleInvalid');
  static const ErrorCode WorkspaceDescTooLong = ErrorCode._(8, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDescTooLong');
  static const ErrorCode WorkspaceNameTooLong = ErrorCode._(9, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameTooLong');
  static const ErrorCode AppIdInvalid = ErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppIdInvalid');
  static const ErrorCode AppNameInvalid = ErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppNameInvalid');
  static const ErrorCode ViewNameInvalid = ErrorCode._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameInvalid');
  static const ErrorCode ViewThumbnailInvalid = ErrorCode._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewThumbnailInvalid');
  static const ErrorCode ViewIdInvalid = ErrorCode._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewIdInvalid');
  static const ErrorCode ViewDescTooLong = ErrorCode._(15, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDescTooLong');
  static const ErrorCode ViewDataInvalid = ErrorCode._(16, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDataInvalid');
  static const ErrorCode ViewNameTooLong = ErrorCode._(17, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameTooLong');
  static const ErrorCode HttpServerConnectError = ErrorCode._(18, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'HttpServerConnectError');
  static const ErrorCode EmailIsEmpty = ErrorCode._(19, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailIsEmpty');
  static const ErrorCode EmailFormatInvalid = ErrorCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailFormatInvalid');
  static const ErrorCode EmailAlreadyExists = ErrorCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EmailAlreadyExists');
  static const ErrorCode PasswordIsEmpty = ErrorCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordIsEmpty');
  static const ErrorCode PasswordTooLong = ErrorCode._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordTooLong');
  static const ErrorCode PasswordContainsForbidCharacters = ErrorCode._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordContainsForbidCharacters');
  static const ErrorCode PasswordFormatInvalid = ErrorCode._(25, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordFormatInvalid');
  static const ErrorCode PasswordNotMatch = ErrorCode._(26, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PasswordNotMatch');
  static const ErrorCode UserNameTooLong = ErrorCode._(27, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameTooLong');
  static const ErrorCode UserNameContainForbiddenCharacters = ErrorCode._(28, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameContainForbiddenCharacters');
  static const ErrorCode UserNameIsEmpty = ErrorCode._(29, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNameIsEmpty');
  static const ErrorCode UserIdInvalid = ErrorCode._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserIdInvalid');
  static const ErrorCode UserNotExist = ErrorCode._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotExist');
  static const ErrorCode TextTooLong = ErrorCode._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TextTooLong');
  static const ErrorCode GridIdIsEmpty = ErrorCode._(33, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridIdIsEmpty');
  static const ErrorCode GridViewIdIsEmpty = ErrorCode._(34, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GridViewIdIsEmpty');
  static const ErrorCode BlockIdIsEmpty = ErrorCode._(35, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'BlockIdIsEmpty');
  static const ErrorCode RowIdIsEmpty = ErrorCode._(36, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RowIdIsEmpty');
  static const ErrorCode OptionIdIsEmpty = ErrorCode._(37, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OptionIdIsEmpty');
  static const ErrorCode FieldIdIsEmpty = ErrorCode._(38, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FieldIdIsEmpty');
  static const ErrorCode FieldDoesNotExist = ErrorCode._(39, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FieldDoesNotExist');
  static const ErrorCode SelectOptionNameIsEmpty = ErrorCode._(40, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SelectOptionNameIsEmpty');
  static const ErrorCode FieldNotExists = ErrorCode._(41, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FieldNotExists');
  static const ErrorCode FieldInvalidOperation = ErrorCode._(42, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FieldInvalidOperation');
  static const ErrorCode FilterIdIsEmpty = ErrorCode._(43, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FilterIdIsEmpty');
  static const ErrorCode FieldRecordNotFound = ErrorCode._(44, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FieldRecordNotFound');
  static const ErrorCode TypeOptionDataIsEmpty = ErrorCode._(45, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TypeOptionDataIsEmpty');
  static const ErrorCode GroupIdIsEmpty = ErrorCode._(46, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GroupIdIsEmpty');
  static const ErrorCode InvalidDateTimeFormat = ErrorCode._(47, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InvalidDateTimeFormat');
  static const ErrorCode UnexpectedEmptyString = ErrorCode._(48, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UnexpectedEmptyString');
  static const ErrorCode InvalidData = ErrorCode._(49, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InvalidData');
  static const ErrorCode Serde = ErrorCode._(50, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Serde');
  static const ErrorCode ProtobufSerde = ErrorCode._(51, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ProtobufSerde');
  static const ErrorCode OutOfBounds = ErrorCode._(52, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OutOfBounds');

  static const $core.List<ErrorCode> values = <ErrorCode> [
    Internal,
    UserUnauthorized,
    RecordNotFound,
    UserIdIsEmpty,
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
    HttpServerConnectError,
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
    GridIdIsEmpty,
    GridViewIdIsEmpty,
    BlockIdIsEmpty,
    RowIdIsEmpty,
    OptionIdIsEmpty,
    FieldIdIsEmpty,
    FieldDoesNotExist,
    SelectOptionNameIsEmpty,
    FieldNotExists,
    FieldInvalidOperation,
    FilterIdIsEmpty,
    FieldRecordNotFound,
    TypeOptionDataIsEmpty,
    GroupIdIsEmpty,
    InvalidDateTimeFormat,
    UnexpectedEmptyString,
    InvalidData,
    Serde,
    ProtobufSerde,
    OutOfBounds,
  ];

  static final $core.Map<$core.int, ErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorCode? valueOf($core.int value) => _byValue[value];

  const ErrorCode._($core.int v, $core.String n) : super(v, n);
}

