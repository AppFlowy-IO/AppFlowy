///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WorkspaceObservable extends $pb.ProtobufEnum {
  static const WorkspaceObservable Unknown = WorkspaceObservable._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const WorkspaceObservable UserCreateWorkspace = WorkspaceObservable._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserCreateWorkspace');
  static const WorkspaceObservable UserDeleteWorkspace = WorkspaceObservable._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDeleteWorkspace');
  static const WorkspaceObservable WorkspaceUpdated = WorkspaceObservable._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceUpdated');
  static const WorkspaceObservable WorkspaceCreateApp = WorkspaceObservable._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceCreateApp');
  static const WorkspaceObservable WorkspaceDeleteApp = WorkspaceObservable._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDeleteApp');
  static const WorkspaceObservable WorkspaceListUpdated = WorkspaceObservable._(15, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceListUpdated');
  static const WorkspaceObservable AppUpdated = WorkspaceObservable._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppUpdated');
  static const WorkspaceObservable AppCreateView = WorkspaceObservable._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppCreateView');
  static const WorkspaceObservable AppDeleteView = WorkspaceObservable._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppDeleteView');
  static const WorkspaceObservable ViewUpdated = WorkspaceObservable._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewUpdated');
  static const WorkspaceObservable UserUnauthorized = WorkspaceObservable._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');

  static const $core.List<WorkspaceObservable> values = <WorkspaceObservable> [
    Unknown,
    UserCreateWorkspace,
    UserDeleteWorkspace,
    WorkspaceUpdated,
    WorkspaceCreateApp,
    WorkspaceDeleteApp,
    WorkspaceListUpdated,
    AppUpdated,
    AppCreateView,
    AppDeleteView,
    ViewUpdated,
    UserUnauthorized,
  ];

  static final $core.Map<$core.int, WorkspaceObservable> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceObservable? valueOf($core.int value) => _byValue[value];

  const WorkspaceObservable._($core.int v, $core.String n) : super(v, n);
}

