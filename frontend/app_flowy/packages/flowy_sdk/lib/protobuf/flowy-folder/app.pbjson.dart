///
//  Generated code. Do not modify.
//  source: app.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use appPBDescriptor instead')
const AppPB$json = const {
  '1': 'AppPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'belongings', '3': 5, '4': 1, '5': 11, '6': '.RepeatedViewPB', '10': 'belongings'},
    const {'1': 'version', '3': 6, '4': 1, '5': 3, '10': 'version'},
    const {'1': 'modified_time', '3': 7, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 8, '4': 1, '5': 3, '10': 'createTime'},
  ],
};

/// Descriptor for `AppPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appPBDescriptor = $convert.base64Decode('CgVBcHBQQhIOCgJpZBgBIAEoCVICaWQSIQoMd29ya3NwYWNlX2lkGAIgASgJUgt3b3Jrc3BhY2VJZBISCgRuYW1lGAMgASgJUgRuYW1lEhIKBGRlc2MYBCABKAlSBGRlc2MSLwoKYmVsb25naW5ncxgFIAEoCzIPLlJlcGVhdGVkVmlld1BCUgpiZWxvbmdpbmdzEhgKB3ZlcnNpb24YBiABKANSB3ZlcnNpb24SIwoNbW9kaWZpZWRfdGltZRgHIAEoA1IMbW9kaWZpZWRUaW1lEh8KC2NyZWF0ZV90aW1lGAggASgDUgpjcmVhdGVUaW1l');
@$core.Deprecated('Use repeatedAppPBDescriptor instead')
const RepeatedAppPB$json = const {
  '1': 'RepeatedAppPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.AppPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedAppPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedAppPBDescriptor = $convert.base64Decode('Cg1SZXBlYXRlZEFwcFBCEhwKBWl0ZW1zGAEgAygLMgYuQXBwUEJSBWl0ZW1z');
@$core.Deprecated('Use createAppPayloadPBDescriptor instead')
const CreateAppPayloadPB$json = const {
  '1': 'CreateAppPayloadPB',
  '2': const [
    const {'1': 'workspace_id', '3': 1, '4': 1, '5': 9, '10': 'workspaceId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStylePB', '10': 'colorStyle'},
  ],
};

/// Descriptor for `CreateAppPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAppPayloadPBDescriptor = $convert.base64Decode('ChJDcmVhdGVBcHBQYXlsb2FkUEISIQoMd29ya3NwYWNlX2lkGAEgASgJUgt3b3Jrc3BhY2VJZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSLgoLY29sb3Jfc3R5bGUYBCABKAsyDS5Db2xvclN0eWxlUEJSCmNvbG9yU3R5bGU=');
@$core.Deprecated('Use colorStylePBDescriptor instead')
const ColorStylePB$json = const {
  '1': 'ColorStylePB',
  '2': const [
    const {'1': 'theme_color', '3': 1, '4': 1, '5': 9, '10': 'themeColor'},
  ],
};

/// Descriptor for `ColorStylePB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorStylePBDescriptor = $convert.base64Decode('CgxDb2xvclN0eWxlUEISHwoLdGhlbWVfY29sb3IYASABKAlSCnRoZW1lQ29sb3I=');
@$core.Deprecated('Use appIdPBDescriptor instead')
const AppIdPB$json = const {
  '1': 'AppIdPB',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `AppIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appIdPBDescriptor = $convert.base64Decode('CgdBcHBJZFBCEhQKBXZhbHVlGAEgASgJUgV2YWx1ZQ==');
@$core.Deprecated('Use updateAppPayloadPBDescriptor instead')
const UpdateAppPayloadPB$json = const {
  '1': 'UpdateAppPayloadPB',
  '2': const [
    const {'1': 'app_id', '3': 1, '4': 1, '5': 9, '10': 'appId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'color_style', '3': 4, '4': 1, '5': 11, '6': '.ColorStylePB', '9': 2, '10': 'colorStyle'},
    const {'1': 'is_trash', '3': 5, '4': 1, '5': 8, '9': 3, '10': 'isTrash'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_color_style'},
    const {'1': 'one_of_is_trash'},
  ],
};

/// Descriptor for `UpdateAppPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAppPayloadPBDescriptor = $convert.base64Decode('ChJVcGRhdGVBcHBQYXlsb2FkUEISFQoGYXBwX2lkGAEgASgJUgVhcHBJZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFAoEZGVzYxgDIAEoCUgBUgRkZXNjEjAKC2NvbG9yX3N0eWxlGAQgASgLMg0uQ29sb3JTdHlsZVBCSAJSCmNvbG9yU3R5bGUSGwoIaXNfdHJhc2gYBSABKAhIA1IHaXNUcmFzaEINCgtvbmVfb2ZfbmFtZUINCgtvbmVfb2ZfZGVzY0IUChJvbmVfb2ZfY29sb3Jfc3R5bGVCEQoPb25lX29mX2lzX3RyYXNo');
