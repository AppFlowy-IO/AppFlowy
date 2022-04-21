///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FolderEvent extends $pb.ProtobufEnum {
  static const FolderEvent CreateWorkspace = FolderEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateWorkspace');
  static const FolderEvent ReadCurWorkspace = FolderEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadCurWorkspace');
  static const FolderEvent ReadWorkspaces = FolderEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadWorkspaces');
  static const FolderEvent DeleteWorkspace = FolderEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteWorkspace');
  static const FolderEvent OpenWorkspace = FolderEvent._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OpenWorkspace');
  static const FolderEvent ReadWorkspaceApps = FolderEvent._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadWorkspaceApps');
  static const FolderEvent CreateApp = FolderEvent._(101, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateApp');
  static const FolderEvent DeleteApp = FolderEvent._(102, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteApp');
  static const FolderEvent ReadApp = FolderEvent._(103, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadApp');
  static const FolderEvent UpdateApp = FolderEvent._(104, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateApp');
  static const FolderEvent CreateView = FolderEvent._(201, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateView');
  static const FolderEvent ReadView = FolderEvent._(202, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadView');
  static const FolderEvent UpdateView = FolderEvent._(203, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateView');
  static const FolderEvent DeleteView = FolderEvent._(204, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteView');
  static const FolderEvent DuplicateView = FolderEvent._(205, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DuplicateView');
  static const FolderEvent CopyLink = FolderEvent._(206, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CopyLink');
  static const FolderEvent SetLatestView = FolderEvent._(207, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SetLatestView');
  static const FolderEvent CloseView = FolderEvent._(208, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CloseView');
  static const FolderEvent ReadTrash = FolderEvent._(300, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ReadTrash');
  static const FolderEvent PutbackTrash = FolderEvent._(301, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PutbackTrash');
  static const FolderEvent DeleteTrash = FolderEvent._(302, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteTrash');
  static const FolderEvent RestoreAllTrash = FolderEvent._(303, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RestoreAllTrash');
  static const FolderEvent DeleteAllTrash = FolderEvent._(304, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteAllTrash');

  static const $core.List<FolderEvent> values = <FolderEvent> [
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
    DuplicateView,
    CopyLink,
    SetLatestView,
    CloseView,
    ReadTrash,
    PutbackTrash,
    DeleteTrash,
    RestoreAllTrash,
    DeleteAllTrash,
  ];

  static final $core.Map<$core.int, FolderEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FolderEvent? valueOf($core.int value) => _byValue[value];

  const FolderEvent._($core.int v, $core.String n) : super(v, n);
}

