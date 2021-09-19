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
    const {'1': 'InternalError', '2': 0},
    const {'1': 'DuplicateSource', '2': 1},
    const {'1': 'UnsupportedMessage', '2': 2},
    const {'1': 'Unauthorized', '2': 3},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSEQoNSW50ZXJuYWxFcnJvchAAEhMKD0R1cGxpY2F0ZVNvdXJjZRABEhYKElVuc3VwcG9ydGVkTWVzc2FnZRACEhAKDFVuYXV0aG9yaXplZBAD');
@$core.Deprecated('Use wsErrorDescriptor instead')
const WsError$json = const {
  '1': 'WsError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.ErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `WsError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsErrorDescriptor = $convert.base64Decode('CgdXc0Vycm9yEh4KBGNvZGUYASABKA4yCi5FcnJvckNvZGVSBGNvZGUSEAoDbXNnGAIgASgJUgNtc2c=');
