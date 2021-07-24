///
//  Generated code. Do not modify.
//  source: app_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createAppRequestDescriptor instead')
const CreateAppRequest$json = const {
  '1': 'CreateAppRequest',
  '2': const [
    const {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStyle', '10': 'colorStyle'},
  ],
};

/// Descriptor for `CreateAppRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAppRequestDescriptor = $convert.base64Decode('ChBDcmVhdGVBcHBSZXF1ZXN0EiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEiwKC2NvbG9yX3N0eWxlGAQgASgLMgsuQ29sb3JTdHlsZVIKY29sb3JTdHlsZQ==');
@$core.Deprecated('Use colorStyleDescriptor instead')
const ColorStyle$json = const {
  '1': 'ColorStyle',
  '2': const [
    const {'1': 'theme_color', '3': 1, '4': 1, '5': 9, '10': 'themeColor'},
  ],
};

/// Descriptor for `ColorStyle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorStyleDescriptor = $convert.base64Decode('CgpDb2xvclN0eWxlEh8KC3RoZW1lX2NvbG9yGAEgASgJUgp0aGVtZUNvbG9y');
@$core.Deprecated('Use appDescriptor instead')
const App$json = const {
  '1': 'App',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'views', '3': 5, '4': 1, '5': 11, '6': '.RepeatedView', '10': 'views'},
  ],
};

/// Descriptor for `App`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appDescriptor = $convert.base64Decode('CgNBcHASDgoCaWQYASABKAlSAmlkEiEKDHdvcmtzcGFjZV9pZBgCIAEoCVILd29ya3NwYWNlSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRISCgRkZXNjGAQgASgJUgRkZXNjEiMKBXZpZXdzGAUgASgLMg0uUmVwZWF0ZWRWaWV3UgV2aWV3cw==');
@$core.Deprecated('Use repeatedAppDescriptor instead')
const RepeatedApp$json = const {
  '1': 'RepeatedApp',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.App', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedApp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedAppDescriptor = $convert.base64Decode('CgtSZXBlYXRlZEFwcBIaCgVpdGVtcxgBIAMoCzIELkFwcFIFaXRlbXM=');
