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
  static const ErrorCode WorkspaceNameInvalid = ErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameInvalid');
  static const ErrorCode WorkspaceIdInvalid = ErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceIdInvalid');
  static const ErrorCode AppColorStyleInvalid = ErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppColorStyleInvalid');
  static const ErrorCode WorkspaceDescTooLong = ErrorCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDescTooLong');
  static const ErrorCode WorkspaceNameTooLong = ErrorCode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameTooLong');
  static const ErrorCode AppIdInvalid = ErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppIdInvalid');
  static const ErrorCode AppNameInvalid = ErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppNameInvalid');
  static const ErrorCode ViewNameInvalid = ErrorCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameInvalid');
  static const ErrorCode ViewThumbnailInvalid = ErrorCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewThumbnailInvalid');
  static const ErrorCode ViewIdInvalid = ErrorCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewIdInvalid');
  static const ErrorCode ViewDescTooLong = ErrorCode._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDescTooLong');
  static const ErrorCode ViewDataInvalid = ErrorCode._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDataInvalid');
  static const ErrorCode ViewNameTooLong = ErrorCode._(25, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameTooLong');
  static const ErrorCode UserUnauthorized = ErrorCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const ErrorCode WsConnectError = ErrorCode._(200, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WsConnectError');
  static const ErrorCode InternalError = ErrorCode._(1000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InternalError');
  static const ErrorCode RecordNotFound = ErrorCode._(1001, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RecordNotFound');

  static const $core.List<ErrorCode> values = <ErrorCode> [
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
    UserUnauthorized,
    WsConnectError,
    InternalError,
    RecordNotFound,
  ];

  static final $core.Map<$core.int, ErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorCode? valueOf($core.int value) => _byValue[value];

  const ErrorCode._($core.int v, $core.String n) : super(v, n);
}

