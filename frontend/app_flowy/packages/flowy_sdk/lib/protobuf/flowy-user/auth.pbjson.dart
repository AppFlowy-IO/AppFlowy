///
//  Generated code. Do not modify.
//  source: auth.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use signInPayloadPBDescriptor instead')
const SignInPayloadPB$json = const {
  '1': 'SignInPayloadPB',
  '2': const [
    const {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `SignInPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signInPayloadPBDescriptor = $convert.base64Decode('Cg9TaWduSW5QYXlsb2FkUEISFAoFZW1haWwYASABKAlSBWVtYWlsEhoKCHBhc3N3b3JkGAIgASgJUghwYXNzd29yZBISCgRuYW1lGAMgASgJUgRuYW1l');
@$core.Deprecated('Use signInParamsDescriptor instead')
const SignInParams$json = const {
  '1': 'SignInParams',
  '2': const [
    const {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `SignInParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signInParamsDescriptor = $convert.base64Decode('CgxTaWduSW5QYXJhbXMSFAoFZW1haWwYASABKAlSBWVtYWlsEhoKCHBhc3N3b3JkGAIgASgJUghwYXNzd29yZBISCgRuYW1lGAMgASgJUgRuYW1l');
@$core.Deprecated('Use signInResponseDescriptor instead')
const SignInResponse$json = const {
  '1': 'SignInResponse',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'token', '3': 4, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `SignInResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signInResponseDescriptor = $convert.base64Decode('Cg5TaWduSW5SZXNwb25zZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIUCgVlbWFpbBgDIAEoCVIFZW1haWwSFAoFdG9rZW4YBCABKAlSBXRva2Vu');
@$core.Deprecated('Use signUpPayloadPBDescriptor instead')
const SignUpPayloadPB$json = const {
  '1': 'SignUpPayloadPB',
  '2': const [
    const {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `SignUpPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signUpPayloadPBDescriptor = $convert.base64Decode('Cg9TaWduVXBQYXlsb2FkUEISFAoFZW1haWwYASABKAlSBWVtYWlsEhIKBG5hbWUYAiABKAlSBG5hbWUSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3Jk');
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
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'token', '3': 4, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `SignUpResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signUpResponseDescriptor = $convert.base64Decode('Cg5TaWduVXBSZXNwb25zZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIUCgVlbWFpbBgDIAEoCVIFZW1haWwSFAoFdG9rZW4YBCABKAlSBXRva2Vu');
