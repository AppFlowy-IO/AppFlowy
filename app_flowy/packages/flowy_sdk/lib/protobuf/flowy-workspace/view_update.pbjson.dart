///
//  Generated code. Do not modify.
//  source: view_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use updateViewRequestDescriptor instead')
const UpdateViewRequest$json = const {
  '1': 'UpdateViewRequest',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'thumbnail'},
    const {'1': 'is_trash', '3': 5, '4': 1, '5': 8, '9': 3, '10': 'isTrash'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_thumbnail'},
    const {'1': 'one_of_is_trash'},
  ],
};

/// Descriptor for `UpdateViewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateViewRequestDescriptor = $convert.base64Decode('ChFVcGRhdGVWaWV3UmVxdWVzdBIXCgd2aWV3X2lkGAEgASgJUgZ2aWV3SWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhQKBGRlc2MYAyABKAlIAVIEZGVzYxIeCgl0aHVtYm5haWwYBCABKAlIAlIJdGh1bWJuYWlsEhsKCGlzX3RyYXNoGAUgASgISANSB2lzVHJhc2hCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2NCEgoQb25lX29mX3RodW1ibmFpbEIRCg9vbmVfb2ZfaXNfdHJhc2g=');
@$core.Deprecated('Use updateViewParamsDescriptor instead')
const UpdateViewParams$json = const {
  '1': 'UpdateViewParams',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'thumbnail'},
    const {'1': 'is_trash', '3': 5, '4': 1, '5': 8, '9': 3, '10': 'isTrash'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_thumbnail'},
    const {'1': 'one_of_is_trash'},
  ],
};

/// Descriptor for `UpdateViewParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateViewParamsDescriptor = $convert.base64Decode('ChBVcGRhdGVWaWV3UGFyYW1zEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFAoEZGVzYxgDIAEoCUgBUgRkZXNjEh4KCXRodW1ibmFpbBgEIAEoCUgCUgl0aHVtYm5haWwSGwoIaXNfdHJhc2gYBSABKAhIA1IHaXNUcmFzaEINCgtvbmVfb2ZfbmFtZUINCgtvbmVfb2ZfZGVzY0ISChBvbmVfb2ZfdGh1bWJuYWlsQhEKD29uZV9vZl9pc190cmFzaA==');
@$core.Deprecated('Use docDeltaRequestDescriptor instead')
const DocDeltaRequest$json = const {
  '1': 'DocDeltaRequest',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `DocDeltaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docDeltaRequestDescriptor = $convert.base64Decode('Cg9Eb2NEZWx0YVJlcXVlc3QSFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEhIKBGRhdGEYAiABKAxSBGRhdGE=');
