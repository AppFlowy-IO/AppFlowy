///
//  Generated code. Do not modify.
//  source: workspace.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspacePBDescriptor instead')
const WorkspacePB$json = const {
  '1': 'WorkspacePB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'apps', '3': 4, '4': 1, '5': 11, '6': '.RepeatedAppPB', '10': 'apps'},
    const {'1': 'modified_time', '3': 5, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 6, '4': 1, '5': 3, '10': 'createTime'},
  ],
};

/// Descriptor for `WorkspacePB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspacePBDescriptor = $convert.base64Decode('CgtXb3Jrc3BhY2VQQhIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEiIKBGFwcHMYBCABKAsyDi5SZXBlYXRlZEFwcFBCUgRhcHBzEiMKDW1vZGlmaWVkX3RpbWUYBSABKANSDG1vZGlmaWVkVGltZRIfCgtjcmVhdGVfdGltZRgGIAEoA1IKY3JlYXRlVGltZQ==');
@$core.Deprecated('Use repeatedWorkspacePBDescriptor instead')
const RepeatedWorkspacePB$json = const {
  '1': 'RepeatedWorkspacePB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.WorkspacePB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedWorkspacePB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedWorkspacePBDescriptor = $convert.base64Decode('ChNSZXBlYXRlZFdvcmtzcGFjZVBCEiIKBWl0ZW1zGAEgAygLMgwuV29ya3NwYWNlUEJSBWl0ZW1z');
@$core.Deprecated('Use createWorkspacePayloadPBDescriptor instead')
const CreateWorkspacePayloadPB$json = const {
  '1': 'CreateWorkspacePayloadPB',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 2, '4': 1, '5': 9, '10': 'desc'},
  ],
};

/// Descriptor for `CreateWorkspacePayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createWorkspacePayloadPBDescriptor = $convert.base64Decode('ChhDcmVhdGVXb3Jrc3BhY2VQYXlsb2FkUEISEgoEbmFtZRgBIAEoCVIEbmFtZRISCgRkZXNjGAIgASgJUgRkZXNj');
@$core.Deprecated('Use workspaceIdPBDescriptor instead')
const WorkspaceIdPB$json = const {
  '1': 'WorkspaceIdPB',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'value'},
  ],
  '8': const [
    const {'1': 'one_of_value'},
  ],
};

/// Descriptor for `WorkspaceIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceIdPBDescriptor = $convert.base64Decode('Cg1Xb3Jrc3BhY2VJZFBCEhYKBXZhbHVlGAEgASgJSABSBXZhbHVlQg4KDG9uZV9vZl92YWx1ZQ==');
@$core.Deprecated('Use workspaceSettingPBDescriptor instead')
const WorkspaceSettingPB$json = const {
  '1': 'WorkspaceSettingPB',
  '2': const [
    const {'1': 'workspace', '3': 1, '4': 1, '5': 11, '6': '.WorkspacePB', '10': 'workspace'},
    const {'1': 'latest_view', '3': 2, '4': 1, '5': 11, '6': '.ViewPB', '9': 0, '10': 'latestView'},
  ],
  '8': const [
    const {'1': 'one_of_latest_view'},
  ],
};

/// Descriptor for `WorkspaceSettingPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceSettingPBDescriptor = $convert.base64Decode('ChJXb3Jrc3BhY2VTZXR0aW5nUEISKgoJd29ya3NwYWNlGAEgASgLMgwuV29ya3NwYWNlUEJSCXdvcmtzcGFjZRIqCgtsYXRlc3RfdmlldxgCIAEoCzIHLlZpZXdQQkgAUgpsYXRlc3RWaWV3QhQKEm9uZV9vZl9sYXRlc3Rfdmlldw==');
@$core.Deprecated('Use updateWorkspacePayloadPBDescriptor instead')
const UpdateWorkspacePayloadPB$json = const {
  '1': 'UpdateWorkspacePayloadPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
  ],
};

/// Descriptor for `UpdateWorkspacePayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateWorkspacePayloadPBDescriptor = $convert.base64Decode('ChhVcGRhdGVXb3Jrc3BhY2VQYXlsb2FkUEISDgoCaWQYASABKAlSAmlkEhQKBG5hbWUYAiABKAlIAFIEbmFtZRIUCgRkZXNjGAMgASgJSAFSBGRlc2NCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2M=');
