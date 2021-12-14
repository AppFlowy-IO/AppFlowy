///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = const {
  '1': 'ErrorCode',
  '2': const [
    const {'1': 'Internal', '2': 0},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSDAoISW50ZXJuYWwQAA==');
@$core.Deprecated('Use flowyErrorDescriptor instead')
const FlowyError$json = const {
  '1': 'FlowyError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 5, '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `FlowyError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flowyErrorDescriptor = $convert.base64Decode('CgpGbG93eUVycm9yEhIKBGNvZGUYASABKAVSBGNvZGUSEAoDbXNnGAIgASgJUgNtc2c=');
