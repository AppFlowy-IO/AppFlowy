///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class WorkspaceObservableType extends $pb.ProtobufEnum {
  static const WorkspaceObservableType Unknown = WorkspaceObservableType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const WorkspaceObservableType WorkspaceUpdated = WorkspaceObservableType._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceUpdated');
  static const WorkspaceObservableType AppDescUpdated = WorkspaceObservableType._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppDescUpdated');
  static const WorkspaceObservableType AppViewsUpdated = WorkspaceObservableType._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppViewsUpdated');
  static const WorkspaceObservableType ViewUpdated = WorkspaceObservableType._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewUpdated');

  static const $core.List<WorkspaceObservableType> values = <WorkspaceObservableType> [
    Unknown,
    WorkspaceUpdated,
    AppDescUpdated,
    AppViewsUpdated,
    ViewUpdated,
  ];

  static final $core.Map<$core.int, WorkspaceObservableType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceObservableType? valueOf($core.int value) => _byValue[value];

  const WorkspaceObservableType._($core.int v, $core.String n) : super(v, n);
}

