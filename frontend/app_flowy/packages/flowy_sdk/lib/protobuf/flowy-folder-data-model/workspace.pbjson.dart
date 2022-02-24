///
//  Generated code. Do not modify.
//  source: workspace.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspaceDescriptor instead')
const Workspace$json = const {
  '1': 'Workspace',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'apps', '3': 4, '4': 1, '5': 11, '6': '.RepeatedApp', '10': 'apps'},
    const {'1': 'modified_time', '3': 5, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 6, '4': 1, '5': 3, '10': 'createTime'},
  ],
};

/// Descriptor for `Workspace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceDescriptor = $convert.base64Decode('CglXb3Jrc3BhY2USDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSEgoEZGVzYxgDIAEoCVIEZGVzYxIgCgRhcHBzGAQgASgLMgwuUmVwZWF0ZWRBcHBSBGFwcHMSIwoNbW9kaWZpZWRfdGltZRgFIAEoA1IMbW9kaWZpZWRUaW1lEh8KC2NyZWF0ZV90aW1lGAYgASgDUgpjcmVhdGVUaW1l');
@$core.Deprecated('Use repeatedWorkspaceDescriptor instead')
const RepeatedWorkspace$json = const {
  '1': 'RepeatedWorkspace',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Workspace', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedWorkspace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedWorkspaceDescriptor = $convert.base64Decode('ChFSZXBlYXRlZFdvcmtzcGFjZRIgCgVpdGVtcxgBIAMoCzIKLldvcmtzcGFjZVIFaXRlbXM=');
@$core.Deprecated('Use createWorkspacePayloadDescriptor instead')
const CreateWorkspacePayload$json = const {
  '1': 'CreateWorkspacePayload',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 2, '4': 1, '5': 9, '10': 'desc'},
  ],
};

/// Descriptor for `CreateWorkspacePayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createWorkspacePayloadDescriptor = $convert.base64Decode('ChZDcmVhdGVXb3Jrc3BhY2VQYXlsb2FkEhIKBG5hbWUYASABKAlSBG5hbWUSEgoEZGVzYxgCIAEoCVIEZGVzYw==');
@$core.Deprecated('Use createWorkspaceParamsDescriptor instead')
const CreateWorkspaceParams$json = const {
  '1': 'CreateWorkspaceParams',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 2, '4': 1, '5': 9, '10': 'desc'},
  ],
};

/// Descriptor for `CreateWorkspaceParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createWorkspaceParamsDescriptor = $convert.base64Decode('ChVDcmVhdGVXb3Jrc3BhY2VQYXJhbXMSEgoEbmFtZRgBIAEoCVIEbmFtZRISCgRkZXNjGAIgASgJUgRkZXNj');
@$core.Deprecated('Use workspaceIdDescriptor instead')
const WorkspaceId$json = const {
  '1': 'WorkspaceId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'value'},
  ],
  '8': const [
    const {'1': 'one_of_value'},
  ],
};

/// Descriptor for `WorkspaceId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceIdDescriptor = $convert.base64Decode('CgtXb3Jrc3BhY2VJZBIWCgV2YWx1ZRgBIAEoCUgAUgV2YWx1ZUIOCgxvbmVfb2ZfdmFsdWU=');
@$core.Deprecated('Use currentWorkspaceSettingDescriptor instead')
const CurrentWorkspaceSetting$json = const {
  '1': 'CurrentWorkspaceSetting',
  '2': const [
    const {'1': 'workspace', '3': 1, '4': 1, '5': 11, '6': '.Workspace', '10': 'workspace'},
    const {'1': 'latest_view', '3': 2, '4': 1, '5': 11, '6': '.View', '9': 0, '10': 'latestView'},
  ],
  '8': const [
    const {'1': 'one_of_latest_view'},
  ],
};

/// Descriptor for `CurrentWorkspaceSetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List currentWorkspaceSettingDescriptor = $convert.base64Decode('ChdDdXJyZW50V29ya3NwYWNlU2V0dGluZxIoCgl3b3Jrc3BhY2UYASABKAsyCi5Xb3Jrc3BhY2VSCXdvcmtzcGFjZRIoCgtsYXRlc3RfdmlldxgCIAEoCzIFLlZpZXdIAFIKbGF0ZXN0Vmlld0IUChJvbmVfb2ZfbGF0ZXN0X3ZpZXc=');
@$core.Deprecated('Use updateWorkspaceRequestDescriptor instead')
const UpdateWorkspaceRequest$json = const {
  '1': 'UpdateWorkspaceRequest',
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

/// Descriptor for `UpdateWorkspaceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateWorkspaceRequestDescriptor = $convert.base64Decode('ChZVcGRhdGVXb3Jrc3BhY2VSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFAoEZGVzYxgDIAEoCUgBUgRkZXNjQg0KC29uZV9vZl9uYW1lQg0KC29uZV9vZl9kZXNj');
@$core.Deprecated('Use updateWorkspaceParamsDescriptor instead')
const UpdateWorkspaceParams$json = const {
  '1': 'UpdateWorkspaceParams',
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

/// Descriptor for `UpdateWorkspaceParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateWorkspaceParamsDescriptor = $convert.base64Decode('ChVVcGRhdGVXb3Jrc3BhY2VQYXJhbXMSDgoCaWQYASABKAlSAmlkEhQKBG5hbWUYAiABKAlIAFIEbmFtZRIUCgRkZXNjGAMgASgJSAFSBGRlc2NCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2M=');
