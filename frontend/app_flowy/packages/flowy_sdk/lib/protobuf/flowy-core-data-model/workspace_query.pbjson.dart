///
//  Generated code. Do not modify.
//  source: workspace_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use queryWorkspaceRequestDescriptor instead')
const QueryWorkspaceRequest$json = const {
  '1': 'QueryWorkspaceRequest',
  '2': const [
    const {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'workspaceId'},
  ],
  '8': const [
    const {'1': 'one_of_workspace_id'},
  ],
};

/// Descriptor for `QueryWorkspaceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryWorkspaceRequestDescriptor = $convert.base64Decode('ChVRdWVyeVdvcmtzcGFjZVJlcXVlc3QSIwoMd29ya3NwYWNlX2lkGAEgASgJSABSC3dvcmtzcGFjZUlkQhUKE29uZV9vZl93b3Jrc3BhY2VfaWQ=');
@$core.Deprecated('Use workspaceIdDescriptor instead')
const WorkspaceId$json = const {
  '1': 'WorkspaceId',
  '2': const [
    const {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'workspaceId'},
  ],
  '8': const [
    const {'1': 'one_of_workspace_id'},
  ],
};

/// Descriptor for `WorkspaceId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceIdDescriptor = $convert.base64Decode('CgtXb3Jrc3BhY2VJZBIjCgx3b3Jrc3BhY2VfaWQYASABKAlIAFILd29ya3NwYWNlSWRCFQoTb25lX29mX3dvcmtzcGFjZV9pZA==');
