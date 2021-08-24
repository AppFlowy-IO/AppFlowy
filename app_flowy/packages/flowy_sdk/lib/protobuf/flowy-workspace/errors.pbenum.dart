///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WsErrCode extends $pb.ProtobufEnum {
  static const WsErrCode Unknown = WsErrCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const WsErrCode WorkspaceNameInvalid = WsErrCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameInvalid');
  static const WsErrCode WorkspaceIdInvalid = WsErrCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceIdInvalid');
  static const WsErrCode AppColorStyleInvalid = WsErrCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppColorStyleInvalid');
  static const WsErrCode AppIdInvalid = WsErrCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppIdInvalid');
  static const WsErrCode AppNameInvalid = WsErrCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppNameInvalid');
  static const WsErrCode ViewNameInvalid = WsErrCode._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewNameInvalid');
  static const WsErrCode ViewThumbnailInvalid = WsErrCode._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewThumbnailInvalid');
  static const WsErrCode ViewIdInvalid = WsErrCode._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewIdInvalid');
  static const WsErrCode ViewDescInvalid = WsErrCode._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDescInvalid');
  static const WsErrCode DatabaseConnectionFail = WsErrCode._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DatabaseConnectionFail');
  static const WsErrCode WorkspaceDatabaseError = WsErrCode._(101, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDatabaseError');
  static const WsErrCode UserInternalError = WsErrCode._(102, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserInternalError');
  static const WsErrCode UserNotLoginYet = WsErrCode._(103, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotLoginYet');
  static const WsErrCode ServerError = WsErrCode._(1000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ServerError');

  static const $core.List<WsErrCode> values = <WsErrCode> [
    Unknown,
    WorkspaceNameInvalid,
    WorkspaceIdInvalid,
    AppColorStyleInvalid,
    AppIdInvalid,
    AppNameInvalid,
    ViewNameInvalid,
    ViewThumbnailInvalid,
    ViewIdInvalid,
    ViewDescInvalid,
    DatabaseConnectionFail,
    WorkspaceDatabaseError,
    UserInternalError,
    UserNotLoginYet,
    ServerError,
  ];

  static final $core.Map<$core.int, WsErrCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WsErrCode? valueOf($core.int value) => _byValue[value];

  const WsErrCode._($core.int v, $core.String n) : super(v, n);
}

