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
  static const WorkspaceEvent CreateDefaultWorkspace = WorkspaceEvent._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateDefaultWorkspace');
  static const WorkspaceEvent CreateApp = WorkspaceEvent._(101, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateApp');
  static const WorkspaceEvent DeleteApp = WorkspaceEvent._(102, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteApp');
  static const WorkspaceEvent ReadApp = WorkspaceEvent._(103, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadApp');
  static const WorkspaceEvent UpdateApp = WorkspaceEvent._(104, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateApp');
  static const WorkspaceEvent CreateView = WorkspaceEvent._(201, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateView');
  static const WorkspaceEvent ReadView = WorkspaceEvent._(202, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadView');
  static const WorkspaceEvent UpdateView = WorkspaceEvent._(203, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateView');
  static const WorkspaceEvent DeleteView = WorkspaceEvent._(204, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteView');
  static const WorkspaceEvent DuplicateView = WorkspaceEvent._(205, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DuplicateView');
  static const WorkspaceEvent CopyLink = WorkspaceEvent._(206, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CopyLink');
  static const WorkspaceEvent OpenView = WorkspaceEvent._(207, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OpenView');
  static const WorkspaceEvent CloseView = WorkspaceEvent._(208, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CloseView');
  static const WorkspaceEvent ReadTrash = WorkspaceEvent._(300, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadTrash');
  static const WorkspaceEvent PutbackTrash = WorkspaceEvent._(301, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PutbackTrash');
  static const WorkspaceEvent DeleteTrash = WorkspaceEvent._(302, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteTrash');
  static const WorkspaceEvent RestoreAll = WorkspaceEvent._(303, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RestoreAll');
  static const WorkspaceEvent DeleteAll = WorkspaceEvent._(304, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteAll');
  static const WorkspaceEvent ApplyDocDelta = WorkspaceEvent._(400, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ApplyDocDelta');
  static const WorkspaceEvent InitWorkspace = WorkspaceEvent._(1000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InitWorkspace');

  static const $core.List<WorkspaceEvent> values = <WorkspaceEvent> [
    CreateWorkspace,
    ReadCurWorkspace,
    ReadWorkspaces,
    DeleteWorkspace,
    OpenWorkspace,
    ReadWorkspaceApps,
    CreateDefaultWorkspace,
    CreateApp,
    DeleteApp,
    ReadApp,
    UpdateApp,
    CreateView,
    ReadView,
    UpdateView,
    DeleteView,
    DuplicateView,
    CopyLink,
    OpenView,
    CloseView,
    ReadTrash,
    PutbackTrash,
    DeleteTrash,
    RestoreAll,
    DeleteAll,
    ApplyDocDelta,
    InitWorkspace,
  ];

  static final $core.Map<$core.int, WorkspaceEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceEvent? valueOf($core.int value) => _byValue[value];

  const WorkspaceEvent._($core.int v, $core.String n) : super(v, n);
}

