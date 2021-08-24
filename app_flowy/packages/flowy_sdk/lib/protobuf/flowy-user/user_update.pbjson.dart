///
//  Generated code. Do not modify.
//  source: user_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use updateUserRequestDescriptor instead')
const UpdateUserRequest$json = const {
  '1': 'UpdateUserRequest',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email'},
    const {'1': 'workspace', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'workspace'},
    const {'1': 'password', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'password'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_email'},
    const {'1': 'one_of_workspace'},
    const {'1': 'one_of_password'},
  ],
};

/// Descriptor for `UpdateUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserRequestDescriptor = $convert.base64Decode('ChFVcGRhdGVVc2VyUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhYKBWVtYWlsGAMgASgJSAFSBWVtYWlsEh4KCXdvcmtzcGFjZRgEIAEoCUgCUgl3b3Jrc3BhY2USHAoIcGFzc3dvcmQYBSABKAlIA1IIcGFzc3dvcmRCDQoLb25lX29mX25hbWVCDgoMb25lX29mX2VtYWlsQhIKEG9uZV9vZl93b3Jrc3BhY2VCEQoPb25lX29mX3Bhc3N3b3Jk');
@$core.Deprecated('Use updateUserParamsDescriptor instead')
const UpdateUserParams$json = const {
  '1': 'UpdateUserParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email'},
    const {'1': 'workspace', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'workspace'},
    const {'1': 'password', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'password'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_email'},
    const {'1': 'one_of_workspace'},
    const {'1': 'one_of_password'},
  ],
};

/// Descriptor for `UpdateUserParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserParamsDescriptor = $convert.base64Decode('ChBVcGRhdGVVc2VyUGFyYW1zEg4KAmlkGAEgASgJUgJpZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFgoFZW1haWwYAyABKAlIAVIFZW1haWwSHgoJd29ya3NwYWNlGAQgASgJSAJSCXdvcmtzcGFjZRIcCghwYXNzd29yZBgFIAEoCUgDUghwYXNzd29yZEINCgtvbmVfb2ZfbmFtZUIOCgxvbmVfb2ZfZW1haWxCEgoQb25lX29mX3dvcmtzcGFjZUIRCg9vbmVfb2ZfcGFzc3dvcmQ=');
