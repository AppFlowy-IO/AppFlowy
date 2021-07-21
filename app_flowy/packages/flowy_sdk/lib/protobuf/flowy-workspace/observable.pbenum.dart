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
  static const WorkspaceObservable WorkspaceUpdateDesc = WorkspaceObservable._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceUpdateDesc');
  static const WorkspaceObservable WorkspaceAddApp = WorkspaceObservable._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceAddApp');
  static const WorkspaceObservable AppUpdateDesc = WorkspaceObservable._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppUpdateDesc');
  static const WorkspaceObservable AppAddView = WorkspaceObservable._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppAddView');
  static const WorkspaceObservable ViewUpdateDesc = WorkspaceObservable._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ViewUpdateDesc');

  static const $core.List<WorkspaceObservable> values = <WorkspaceObservable> [
    Unknown,
    WorkspaceUpdateDesc,
    WorkspaceAddApp,
    AppUpdateDesc,
    AppAddView,
    ViewUpdateDesc,
  ];

  static final $core.Map<$core.int, WorkspaceObservable> _byValue = $pb.ProtobufEnum.initByValue(values);
  static WorkspaceObservable? valueOf($core.int value) => _byValue[value];

  const WorkspaceObservable._($core.int v, $core.String n) : super(v, n);
}

