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
  static const WorkspaceEvent ReadCurWorkspace = WorkspaceEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadCurWorkspace');
  static const WorkspaceEvent ReadWorkspaces = WorkspaceEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadWorkspaces');
  static const WorkspaceEvent DeleteWorkspace = WorkspaceEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteWorkspace');
  static const WorkspaceEvent OpenWorkspace = WorkspaceEvent._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OpenWorkspace');
  static const WorkspaceEvent ReadWorkspaceApps = WorkspaceEvent._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadWorkspaceApps');
  static const WorkspaceEvent CreateApp = WorkspaceEvent._(101, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateApp');
  static const WorkspaceEvent DeleteApp = WorkspaceEvent._(102, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteApp');
  static const WorkspaceEvent ReadApp = WorkspaceEvent._(103, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadApp');
  static const WorkspaceEvent UpdateApp = WorkspaceEvent._(104, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateApp');
  static const WorkspaceEvent CreateView = WorkspaceEvent._(201, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateView');
  static const WorkspaceEvent ReadView = WorkspaceEvent._(202, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadView');
  static const WorkspaceEvent UpdateView = WorkspaceEvent._(203, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateView');
  static const WorkspaceEvent DeleteView = WorkspaceEvent._(204, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteView');
  static const WorkspaceEvent OpenView = WorkspaceEvent._(205, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OpenView');
  static const WorkspaceEvent ApplyDocDelta = WorkspaceEvent._(206, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ApplyDocDelta');

  static const $core.List<WorkspaceEvent> values = <WorkspaceEvent> [
    CreateWorkspace,
    ReadCurWorkspace,
    ReadWorkspaces,
    DeleteWorkspace,
    OpenWorkspace,
    ReadWorkspaceApps,
    CreateApp,
    DeleteApp,
    ReadApp,
    UpdateApp,
    CreateView,
    ReadView,
    UpdateView,
    DeleteView,
    OpenView,
    ApplyDocDelta,
  ];

  static final $core.Map<$core.int, WorkspaceEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceEvent? valueOf($core.int value) => _byValue[value];

  const WorkspaceEvent._($core.int v, $core.String n) : super(v, n);
}

