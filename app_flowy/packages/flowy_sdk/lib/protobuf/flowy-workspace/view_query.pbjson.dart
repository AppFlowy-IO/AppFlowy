///
//  Generated code. Do not modify.
//  source: view_query.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use queryViewRequestDescriptor instead')
const QueryViewRequest$json = const {
  '1': 'QueryViewRequest',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'is_trash', '3': 2, '4': 1, '5': 8, '10': 'isTrash'},
    const {'1': 'read_belongings', '3': 3, '4': 1, '5': 8, '10': 'readBelongings'},
  ],
};

/// Descriptor for `QueryViewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryViewRequestDescriptor = $convert.base64Decode('ChBRdWVyeVZpZXdSZXF1ZXN0EhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIZCghpc190cmFzaBgCIAEoCFIHaXNUcmFzaBInCg9yZWFkX2JlbG9uZ2luZ3MYAyABKAhSDnJlYWRCZWxvbmdpbmdz');
@$core.Deprecated('Use queryViewParamsDescriptor instead')
const QueryViewParams$json = const {
  '1': 'QueryViewParams',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'is_trash', '3': 2, '4': 1, '5': 8, '10': 'isTrash'},
    const {'1': 'read_belongings', '3': 3, '4': 1, '5': 8, '10': 'readBelongings'},
  ],
};

/// Descriptor for `QueryViewParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryViewParamsDescriptor = $convert.base64Decode('Cg9RdWVyeVZpZXdQYXJhbXMSFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEhkKCGlzX3RyYXNoGAIgASgIUgdpc1RyYXNoEicKD3JlYWRfYmVsb25naW5ncxgDIAEoCFIOcmVhZEJlbG9uZ2luZ3M=');
