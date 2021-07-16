///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WorkspaceEvent extends $pb.ProtobufEnum {
  static const WorkspaceEvent CreateWorkspace = WorkspaceEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateWorkspace');
  static const WorkspaceEvent GetWorkspaceUserDetail = WorkspaceEvent._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetWorkspaceUserDetail');

  static const $core.List<WorkspaceEvent> values = <WorkspaceEvent> [
    CreateWorkspace,
    GetWorkspaceUserDetail,
  ];

  static final $core.Map<$core.int, WorkspaceEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceEvent? valueOf($core.int value) => _byValue[value];

  const WorkspaceEvent._($core.int v, $core.String n) : super(v, n);
}

