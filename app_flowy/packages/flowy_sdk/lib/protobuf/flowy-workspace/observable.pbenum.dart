///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WorkspaceNotification extends $pb.ProtobufEnum {
  static const WorkspaceNotification Unknown = WorkspaceNotification._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const WorkspaceNotification UserCreateWorkspace = WorkspaceNotification._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserCreateWorkspace');
  static const WorkspaceNotification UserDeleteWorkspace = WorkspaceNotification._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDeleteWorkspace');
  static const WorkspaceNotification WorkspaceUpdated = WorkspaceNotification._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceUpdated');
  static const WorkspaceNotification WorkspaceListUpdated = WorkspaceNotification._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceListUpdated');
  static const WorkspaceNotification WorkspaceAppsChanged = WorkspaceNotification._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceAppsChanged');
  static const WorkspaceNotification AppUpdated = WorkspaceNotification._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppUpdated');
  static const WorkspaceNotification AppViewsChanged = WorkspaceNotification._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppViewsChanged');
  static const WorkspaceNotification ViewUpdated = WorkspaceNotification._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewUpdated');
  static const WorkspaceNotification UserUnauthorized = WorkspaceNotification._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const WorkspaceNotification TrashUpdated = WorkspaceNotification._(1000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TrashUpdated');

  static const $core.List<WorkspaceNotification> values = <WorkspaceNotification> [
    Unknown,
    UserCreateWorkspace,
    UserDeleteWorkspace,
    WorkspaceUpdated,
    WorkspaceListUpdated,
    WorkspaceAppsChanged,
    AppUpdated,
    AppViewsChanged,
    ViewUpdated,
    UserUnauthorized,
    TrashUpdated,
  ];

  static final $core.Map<$core.int, WorkspaceNotification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceNotification? valueOf($core.int value) => _byValue[value];

  const WorkspaceNotification._($core.int v, $core.String n) : super(v, n);
}

