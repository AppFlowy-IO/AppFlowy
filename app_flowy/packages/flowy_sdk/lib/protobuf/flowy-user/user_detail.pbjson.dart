///
//  Generated code. Do not modify.
//  source: user_detail.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userStatusDescriptor instead')
const UserStatus$json = const {
  '1': 'UserStatus',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'Login', '2': 1},
    const {'1': 'Expired', '2': 2},
  ],
};

/// Descriptor for `UserStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userStatusDescriptor = $convert.base64Decode('CgpVc2VyU3RhdHVzEgsKB1Vua25vd24QABIJCgVMb2dpbhABEgsKB0V4cGlyZWQQAg==');
@$core.Deprecated('Use userTokenDescriptor instead')
const UserToken$json = const {
  '1': 'UserToken',
  '2': const [
    const {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `UserToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userTokenDescriptor = $convert.base64Decode('CglVc2VyVG9rZW4SFAoFdG9rZW4YASABKAlSBXRva2Vu');
@$core.Deprecated('Use userDetailDescriptor instead')
const UserDetail$json = const {
  '1': 'UserDetail',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `UserDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDetailDescriptor = $convert.base64Decode('CgpVc2VyRGV0YWlsEg4KAmlkGAEgASgJUgJpZBIUCgVlbWFpbBgCIAEoCVIFZW1haWwSEgoEbmFtZRgDIAEoCVIEbmFtZQ==');
@$core.Deprecated('Use updateUserRequestDescriptor instead')
const UpdateUserRequest$json = const {
  '1': 'UpdateUserRequest',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email'},
    const {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'password'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_email'},
    const {'1': 'one_of_password'},
  ],
};

/// Descriptor for `UpdateUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserRequestDescriptor = $convert.base64Decode('ChFVcGRhdGVVc2VyUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhYKBWVtYWlsGAMgASgJSAFSBWVtYWlsEhwKCHBhc3N3b3JkGAQgASgJSAJSCHBhc3N3b3JkQg0KC29uZV9vZl9uYW1lQg4KDG9uZV9vZl9lbWFpbEIRCg9vbmVfb2ZfcGFzc3dvcmQ=');
@$core.Deprecated('Use updateUserParamsDescriptor instead')
const UpdateUserParams$json = const {
  '1': 'UpdateUserParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email'},
    const {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'password'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_email'},
    const {'1': 'one_of_password'},
  ],
};

/// Descriptor for `UpdateUserParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserParamsDescriptor = $convert.base64Decode('ChBVcGRhdGVVc2VyUGFyYW1zEg4KAmlkGAEgASgJUgJpZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFgoFZW1haWwYAyABKAlIAVIFZW1haWwSHAoIcGFzc3dvcmQYBCABKAlIAlIIcGFzc3dvcmRCDQoLb25lX29mX25hbWVCDgoMb25lX29mX2VtYWlsQhEKD29uZV9vZl9wYXNzd29yZA==');
