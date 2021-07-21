///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspaceObservableTypeDescriptor instead')
const WorkspaceObservableType$json = const {
  '1': 'WorkspaceObservableType',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'WorkspaceUpdated', '2': 10},
    const {'1': 'AppDescUpdated', '2': 20},
    const {'1': 'AppViewsUpdated', '2': 21},
    const {'1': 'ViewUpdated', '2': 30},
  ],
};

/// Descriptor for `WorkspaceObservableType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceObservableTypeDescriptor = $convert.base64Decode('ChdXb3Jrc3BhY2VPYnNlcnZhYmxlVHlwZRILCgdVbmtub3duEAASFAoQV29ya3NwYWNlVXBkYXRlZBAKEhIKDkFwcERlc2NVcGRhdGVkEBQSEwoPQXBwVmlld3NVcGRhdGVkEBUSDwoLVmlld1VwZGF0ZWQQHg==');
