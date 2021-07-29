///
//  Generated code. Do not modify.
//  source: app_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use updateAppRequestDescriptor instead')
const UpdateAppRequest$json = const {
  '1': 'UpdateAppRequest',
  '2': const [
    const {'1': 'app_id', '3': 1, '4': 1, '5': 9, '10': 'appId'},
    const {'1': 'workspace_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'workspaceId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'desc'},
    const {'1': 'color_style', '3': 5, '4': 1, '5': 11, '6': '.ColorStyle', '9': 3, '10': 'colorStyle'},
    const {'1': 'is_trash', '3': 6, '4': 1, '5': 8, '9': 4, '10': 'isTrash'},
  ],
  '8': const [
    const {'1': 'one_of_workspace_id'},
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_color_style'},
    const {'1': 'one_of_is_trash'},
  ],
};

/// Descriptor for `UpdateAppRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAppRequestDescriptor = $convert.base64Decode('ChBVcGRhdGVBcHBSZXF1ZXN0EhUKBmFwcF9pZBgBIAEoCVIFYXBwSWQSIwoMd29ya3NwYWNlX2lkGAIgASgJSABSC3dvcmtzcGFjZUlkEhQKBG5hbWUYAyABKAlIAVIEbmFtZRIUCgRkZXNjGAQgASgJSAJSBGRlc2MSLgoLY29sb3Jfc3R5bGUYBSABKAsyCy5Db2xvclN0eWxlSANSCmNvbG9yU3R5bGUSGwoIaXNfdHJhc2gYBiABKAhIBFIHaXNUcmFzaEIVChNvbmVfb2Zfd29ya3NwYWNlX2lkQg0KC29uZV9vZl9uYW1lQg0KC29uZV9vZl9kZXNjQhQKEm9uZV9vZl9jb2xvcl9zdHlsZUIRCg9vbmVfb2ZfaXNfdHJhc2g=');
