///
//  Generated code. Do not modify.
//  source: app.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use appDescriptor instead')
const App$json = const {
  '1': 'App',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'belongings', '3': 5, '4': 1, '5': 11, '6': '.RepeatedView', '10': 'belongings'},
    const {'1': 'version', '3': 6, '4': 1, '5': 3, '10': 'version'},
    const {'1': 'modified_time', '3': 7, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 8, '4': 1, '5': 3, '10': 'createTime'},
  ],
};

/// Descriptor for `App`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appDescriptor = $convert.base64Decode('CgNBcHASDgoCaWQYASABKAlSAmlkEiEKDHdvcmtzcGFjZV9pZBgCIAEoCVILd29ya3NwYWNlSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRISCgRkZXNjGAQgASgJUgRkZXNjEi0KCmJlbG9uZ2luZ3MYBSABKAsyDS5SZXBlYXRlZFZpZXdSCmJlbG9uZ2luZ3MSGAoHdmVyc2lvbhgGIAEoA1IHdmVyc2lvbhIjCg1tb2RpZmllZF90aW1lGAcgASgDUgxtb2RpZmllZFRpbWUSHwoLY3JlYXRlX3RpbWUYCCABKANSCmNyZWF0ZVRpbWU=');
@$core.Deprecated('Use repeatedAppDescriptor instead')
const RepeatedApp$json = const {
  '1': 'RepeatedApp',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.App', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedApp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedAppDescriptor = $convert.base64Decode('CgtSZXBlYXRlZEFwcBIaCgVpdGVtcxgBIAMoCzIELkFwcFIFaXRlbXM=');
@$core.Deprecated('Use createAppPayloadDescriptor instead')
const CreateAppPayload$json = const {
  '1': 'CreateAppPayload',
  '2': const [
    const {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStyle', '10': 'colorStyle'},
  ],
};

/// Descriptor for `CreateAppPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAppPayloadDescriptor = $convert.base64Decode('ChBDcmVhdGVBcHBQYXlsb2FkEiEKDHdvcmtzcGFjZV9pZBgBIAEoCVILd29ya3NwYWNlSWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEiwKC2NvbG9yX3N0eWxlGAQgASgLMgsuQ29sb3JTdHlsZVIKY29sb3JTdHlsZQ==');
@$core.Deprecated('Use colorStyleDescriptor instead')
const ColorStyle$json = const {
  '1': 'ColorStyle',
  '2': const [
    const {'1': 'theme_color', '3': 1, '4': 1, '5': 9, '10': 'themeColor'},
  ],
};

/// Descriptor for `ColorStyle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorStyleDescriptor = $convert.base64Decode('CgpDb2xvclN0eWxlEh8KC3RoZW1lX2NvbG9yGAEgASgJUgp0aGVtZUNvbG9y');
@$core.Deprecated('Use createAppParamsDescriptor instead')
const CreateAppParams$json = const {
  '1': 'CreateAppParams',
  '2': const [
    const {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStyle', '10': 'colorStyle'},
  ],
};

/// Descriptor for `CreateAppParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAppParamsDescriptor = $convert.base64Decode('Cg9DcmVhdGVBcHBQYXJhbXMSIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSLAoLY29sb3Jfc3R5bGUYBCABKAsyCy5Db2xvclN0eWxlUgpjb2xvclN0eWxl');
@$core.Deprecated('Use appIdDescriptor instead')
const AppId$json = const {
  '1': 'AppId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `AppId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appIdDescriptor = $convert.base64Decode('CgVBcHBJZBIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');
@$core.Deprecated('Use updateAppPayloadDescriptor instead')
const UpdateAppPayload$json = const {
  '1': 'UpdateAppPayload',
  '2': const [
    const {'1': 'app_id', '3': 1, '4': 1, '5': 9, '10': 'appId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStyle', '9': 2, '10': 'colorStyle'},
    const {'1': 'is_trash', '3': 5, '4': 1, '5': 8, '9': 3, '10': 'isTrash'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_color_style'},
    const {'1': 'one_of_is_trash'},
  ],
};

/// Descriptor for `UpdateAppPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAppPayloadDescriptor = $convert.base64Decode('ChBVcGRhdGVBcHBQYXlsb2FkEhUKBmFwcF9pZBgBIAEoCVIFYXBwSWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhQKBGRlc2MYAyABKAlIAVIEZGVzYxIuCgtjb2xvcl9zdHlsZRgEIAEoCzILLkNvbG9yU3R5bGVIAlIKY29sb3JTdHlsZRIbCghpc190cmFzaBgFIAEoCEgDUgdpc1RyYXNoQg0KC29uZV9vZl9uYW1lQg0KC29uZV9vZl9kZXNjQhQKEm9uZV9vZl9jb2xvcl9zdHlsZUIRCg9vbmVfb2ZfaXNfdHJhc2g=');
@$core.Deprecated('Use updateAppParamsDescriptor instead')
const UpdateAppParams$json = const {
  '1': 'UpdateAppParams',
  '2': const [
    const {'1': 'app_id', '3': 1, '4': 1, '5': 9, '10': 'appId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStyle', '9': 2, '10': 'colorStyle'},
    const {'1': 'is_trash', '3': 5, '4': 1, '5': 8, '9': 3, '10': 'isTrash'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_color_style'},
    const {'1': 'one_of_is_trash'},
  ],
};

/// Descriptor for `UpdateAppParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAppParamsDescriptor = $convert.base64Decode('Cg9VcGRhdGVBcHBQYXJhbXMSFQoGYXBwX2lkGAEgASgJUgVhcHBJZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFAoEZGVzYxgDIAEoCUgBUgRkZXNjEi4KC2NvbG9yX3N0eWxlGAQgASgLMgsuQ29sb3JTdHlsZUgCUgpjb2xvclN0eWxlEhsKCGlzX3RyYXNoGAUgASgISANSB2lzVHJhc2hCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2NCFAoSb25lX29mX2NvbG9yX3N0eWxlQhEKD29uZV9vZl9pc190cmFzaA==');
