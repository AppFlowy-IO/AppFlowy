///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WorkspaceErrorCode extends $pb.ProtobufEnum {
  static const WorkspaceErrorCode Unknown = WorkspaceErrorCode._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const WorkspaceErrorCode WorkspaceNameInvalid = WorkspaceErrorCode._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceNameInvalid');
  static const WorkspaceErrorCode WorkspaceIdInvalid = WorkspaceErrorCode._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceIdInvalid');
  static const WorkspaceErrorCode AppColorStyleInvalid = WorkspaceErrorCode._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppColorStyleInvalid');
  static const WorkspaceErrorCode AppIdInvalid = WorkspaceErrorCode._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppIdInvalid');
  static const WorkspaceErrorCode DatabaseConnectionFail = WorkspaceErrorCode._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DatabaseConnectionFail');
  static const WorkspaceErrorCode DatabaseInternalError = WorkspaceErrorCode._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DatabaseInternalError');
  static const WorkspaceErrorCode UserInternalError = WorkspaceErrorCode._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserInternalError');
  static const WorkspaceErrorCode UserNotLoginYet = WorkspaceErrorCode._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserNotLoginYet');

  static const $core.List<WorkspaceErrorCode> values = <WorkspaceErrorCode> [
    Unknown,
    WorkspaceNameInvalid,
    WorkspaceIdInvalid,
    AppColorStyleInvalid,
    AppIdInvalid,
    DatabaseConnectionFail,
    DatabaseInternalError,
    UserInternalError,
    UserNotLoginYet,
  ];

  static final $core.Map<$core.int, WorkspaceErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceErrorCode? valueOf($core.int value) => _byValue[value];

  const WorkspaceErrorCode._($core.int v, $core.String n) : super(v, n);
}

