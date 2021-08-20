///
//  Generated code. Do not modify.
//  source: sign_up.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use signUpRequestDescriptor instead')
const SignUpRequest$json = const {
  '1': 'SignUpRequest',
  '2': const [
    const {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `SignUpRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signUpRequestDescriptor = $convert.base64Decode('Cg1TaWduVXBSZXF1ZXN0EhQKBWVtYWlsGAEgASgJUgVlbWFpbBISCgRuYW1lGAIgASgJUgRuYW1lEhoKCHBhc3N3b3JkGAMgASgJUghwYXNzd29yZA==');
@$core.Deprecated('Use signUpParamsDescriptor instead')
const SignUpParams$json = const {
  '1': 'SignUpParams',
  '2': const [
    const {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `SignUpParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signUpParamsDescriptor = $convert.base64Decode('CgxTaWduVXBQYXJhbXMSFAoFZW1haWwYASABKAlSBWVtYWlsEhIKBG5hbWUYAiABKAlSBG5hbWUSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3Jk');
@$core.Deprecated('Use signUpResponseDescriptor instead')
const SignUpResponse$json = const {
  '1': 'SignUpResponse',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 8, '10': 'name'},
    const {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
  ],
};

/// Descriptor for `SignUpResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signUpResponseDescriptor = $convert.base64Decode('Cg5TaWduVXBSZXNwb25zZRISCgRuYW1lGAEgASgIUgRuYW1lEhQKBWVtYWlsGAIgASgJUgVlbWFpbA==');
