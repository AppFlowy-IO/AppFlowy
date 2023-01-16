///
//  Generated code. Do not modify.
//  source: user_profile.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userTokenPBDescriptor instead')
const UserTokenPB$json = const {
  '1': 'UserTokenPB',
  '2': const [
    const {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `UserTokenPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userTokenPBDescriptor = $convert.base64Decode('CgtVc2VyVG9rZW5QQhIUCgV0b2tlbhgBIAEoCVIFdG9rZW4=');
@$core.Deprecated('Use userSettingPBDescriptor instead')
const UserSettingPB$json = const {
  '1': 'UserSettingPB',
  '2': const [
    const {'1': 'user_folder', '3': 1, '4': 1, '5': 9, '10': 'userFolder'},
  ],
};

/// Descriptor for `UserSettingPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userSettingPBDescriptor = $convert.base64Decode('Cg1Vc2VyU2V0dGluZ1BCEh8KC3VzZXJfZm9sZGVyGAEgASgJUgp1c2VyRm9sZGVy');
@$core.Deprecated('Use userProfilePBDescriptor instead')
const UserProfilePB$json = const {
  '1': 'UserProfilePB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'token', '3': 4, '4': 1, '5': 9, '10': 'token'},
    const {'1': 'icon_url', '3': 5, '4': 1, '5': 9, '10': 'iconUrl'},
  ],
};

/// Descriptor for `UserProfilePB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfilePBDescriptor = $convert.base64Decode('Cg1Vc2VyUHJvZmlsZVBCEg4KAmlkGAEgASgJUgJpZBIUCgVlbWFpbBgCIAEoCVIFZW1haWwSEgoEbmFtZRgDIAEoCVIEbmFtZRIUCgV0b2tlbhgEIAEoCVIFdG9rZW4SGQoIaWNvbl91cmwYBSABKAlSB2ljb25Vcmw=');
@$core.Deprecated('Use updateUserProfilePayloadPBDescriptor instead')
const UpdateUserProfilePayloadPB$json = const {
  '1': 'UpdateUserProfilePayloadPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email'},
    const {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'password'},
    const {'1': 'icon_url', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'iconUrl'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_email'},
    const {'1': 'one_of_password'},
    const {'1': 'one_of_icon_url'},
  ],
};

/// Descriptor for `UpdateUserProfilePayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserProfilePayloadPBDescriptor = $convert.base64Decode('ChpVcGRhdGVVc2VyUHJvZmlsZVBheWxvYWRQQhIOCgJpZBgBIAEoCVICaWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhYKBWVtYWlsGAMgASgJSAFSBWVtYWlsEhwKCHBhc3N3b3JkGAQgASgJSAJSCHBhc3N3b3JkEhsKCGljb25fdXJsGAUgASgJSANSB2ljb25VcmxCDQoLb25lX29mX25hbWVCDgoMb25lX29mX2VtYWlsQhEKD29uZV9vZl9wYXNzd29yZEIRCg9vbmVfb2ZfaWNvbl91cmw=');
@$core.Deprecated('Use updateUserProfileParamsDescriptor instead')
const UpdateUserProfileParams$json = const {
  '1': 'UpdateUserProfileParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'email'},
    const {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'password'},
    const {'1': 'icon_url', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'iconUrl'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_email'},
    const {'1': 'one_of_password'},
    const {'1': 'one_of_icon_url'},
  ],
};

/// Descriptor for `UpdateUserProfileParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserProfileParamsDescriptor = $convert.base64Decode('ChdVcGRhdGVVc2VyUHJvZmlsZVBhcmFtcxIOCgJpZBgBIAEoCVICaWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhYKBWVtYWlsGAMgASgJSAFSBWVtYWlsEhwKCHBhc3N3b3JkGAQgASgJSAJSCHBhc3N3b3JkEhsKCGljb25fdXJsGAUgASgJSANSB2ljb25VcmxCDQoLb25lX29mX25hbWVCDgoMb25lX29mX2VtYWlsQhEKD29uZV9vZl9wYXNzd29yZEIRCg9vbmVfb2ZfaWNvbl91cmw=');
