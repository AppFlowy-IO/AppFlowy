///
//  Generated code. Do not modify.
//  source: workspace_user_detail.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userWorkspaceDescriptor instead')
const UserWorkspace$json = const {
  '1': 'UserWorkspace',
  '2': const [
    const {'1': 'owner', '3': 1, '4': 1, '5': 9, '10': 'owner'},
    const {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
  ],
};

/// Descriptor for `UserWorkspace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userWorkspaceDescriptor = $convert.base64Decode('Cg1Vc2VyV29ya3NwYWNlEhQKBW93bmVyGAEgASgJUgVvd25lchIhCgx3b3Jrc3BhY2VfaWQYAiABKAlSC3dvcmtzcGFjZUlk');
@$core.Deprecated('Use userWorkspaceDetailDescriptor instead')
const UserWorkspaceDetail$json = const {
  '1': 'UserWorkspaceDetail',
  '2': const [
    const {'1': 'owner', '3': 1, '4': 1, '5': 9, '10': 'owner'},
    const {'1': 'workspace', '3': 2, '4': 1, '5': 11, '6': '.Workspace', '10': 'workspace'},
  ],
};

/// Descriptor for `UserWorkspaceDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userWorkspaceDetailDescriptor = $convert.base64Decode('ChNVc2VyV29ya3NwYWNlRGV0YWlsEhQKBW93bmVyGAEgASgJUgVvd25lchIoCgl3b3Jrc3BhY2UYAiABKAsyCi5Xb3Jrc3BhY2VSCXdvcmtzcGFjZQ==');
