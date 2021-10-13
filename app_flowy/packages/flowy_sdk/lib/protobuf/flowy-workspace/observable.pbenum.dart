///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Notification extends $pb.ProtobufEnum {
  static const Notification Unknown = Notification._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const Notification UserCreateWorkspace = Notification._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserCreateWorkspace');
  static const Notification UserDeleteWorkspace = Notification._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserDeleteWorkspace');
  static const Notification WorkspaceUpdated = Notification._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceUpdated');
  static const Notification WorkspaceCreateApp = Notification._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceCreateApp');
  static const Notification WorkspaceDeleteApp = Notification._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDeleteApp');
  static const Notification WorkspaceListUpdated = Notification._(15, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceListUpdated');
  static const Notification AppUpdated = Notification._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppUpdated');
  static const Notification AppViewsChanged = Notification._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppViewsChanged');
  static const Notification ViewUpdated = Notification._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewUpdated');
  static const Notification UserUnauthorized = Notification._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserUnauthorized');

  static const $core.List<Notification> values = <Notification> [
    Unknown,
    UserCreateWorkspace,
    UserDeleteWorkspace,
    WorkspaceUpdated,
    WorkspaceCreateApp,
    WorkspaceDeleteApp,
    WorkspaceListUpdated,
    AppUpdated,
    AppViewsChanged,
    ViewUpdated,
    UserUnauthorized,
  ];

  static final $core.Map<$core.int, Notification> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Notification? valueOf($core.int value) => _byValue[value];

  const Notification._($core.int v, $core.String n) : super(v, n);
}

