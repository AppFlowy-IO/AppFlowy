///
//  Generated code. Do not modify.
//  source: ffi_response.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use fFIStatusCodeDescriptor instead')
const FFIStatusCode$json = const {
  '1': 'FFIStatusCode',
  '2': const [
    const {'1': 'Ok', '2': 0},
    const {'1': 'Err', '2': 1},
    const {'1': 'Internal', '2': 2},
  ],
};

/// Descriptor for `FFIStatusCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fFIStatusCodeDescriptor = $convert.base64Decode('Cg1GRklTdGF0dXNDb2RlEgYKAk9rEAASBwoDRXJyEAESDAoISW50ZXJuYWwQAg==');
@$core.Deprecated('Use fFIResponseDescriptor instead')
const FFIResponse$json = const {
  '1': 'FFIResponse',
  '2': const [
    const {'1': 'payload', '3': 1, '4': 1, '5': 12, '10': 'payload'},
    const {'1': 'code', '3': 2, '4': 1, '5': 14, '6': '.FFIStatusCode', '10': 'code'},
  ],
};

/// Descriptor for `FFIResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fFIResponseDescriptor = $convert.base64Decode('CgtGRklSZXNwb25zZRIYCgdwYXlsb2FkGAEgASgMUgdwYXlsb2FkEiIKBGNvZGUYAiABKA4yDi5GRklTdGF0dXNDb2RlUgRjb2Rl');
