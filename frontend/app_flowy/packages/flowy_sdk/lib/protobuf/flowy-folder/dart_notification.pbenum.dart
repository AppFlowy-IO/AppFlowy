///
//  Generated code. Do not modify.
//  source: dart_notification.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FolderNotification extends $pb.ProtobufEnum {
  static const FolderNotification Unknown = FolderNotification._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const FolderNotification UserCreateWorkspace = FolderNotification._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserCreateWorkspace');
  static const FolderNotification UserDeleteWorkspace = FolderNotification._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDeleteWorkspace');
  static const FolderNotification WorkspaceUpdated = FolderNotification._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceUpdated');
  static const FolderNotification WorkspaceListUpdated = FolderNotification._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceListUpdated');
  static const FolderNotification WorkspaceAppsChanged = FolderNotification._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceAppsChanged');
  static const FolderNotification AppUpdated = FolderNotification._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppUpdated');
  static const FolderNotification AppViewsChanged = FolderNotification._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppViewsChanged');
  static const FolderNotification ViewUpdated = FolderNotification._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewUpdated');
  static const FolderNotification ViewDeleted = FolderNotification._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewDeleted');
  static const FolderNotification ViewRestored = FolderNotification._(33, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewRestored');
  static const FolderNotification UserUnauthorized = FolderNotification._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');
  static const FolderNotification TrashUpdated = FolderNotification._(1000, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TrashUpdated');

  static const $core.List<FolderNotification> values = <FolderNotification> [
    Unknown,
    UserCreateWorkspace,
    UserDeleteWorkspace,
    WorkspaceUpdated,
    WorkspaceListUpdated,
    WorkspaceAppsChanged,
    AppUpdated,
    AppViewsChanged,
    ViewUpdated,
    ViewDeleted,
    ViewRestored,
    UserUnauthorized,
    TrashUpdated,
  ];

  static final $core.Map<$core.int, FolderNotification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FolderNotification? valueOf($core.int value) => _byValue[value];

  const FolderNotification._($core.int v, $core.String n) : super(v, n);
}

