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
    const {'1': 'EmailIsEmpty', '2': 0},
    const {'1': 'EmailFormatInvalid', '2': 1},
    const {'1': 'EmailAlreadyExists', '2': 2},
    const {'1': 'PasswordIsEmpty', '2': 10},
    const {'1': 'PasswordTooLong', '2': 11},
    const {'1': 'PasswordContainsForbidCharacters', '2': 12},
    const {'1': 'PasswordFormatInvalid', '2': 13},
    const {'1': 'PasswordNotMatch', '2': 14},
    const {'1': 'UserNameTooLong', '2': 20},
    const {'1': 'UserNameContainForbiddenCharacters', '2': 21},
    const {'1': 'UserNameIsEmpty', '2': 22},
    const {'1': 'UserIdInvalid', '2': 23},
    const {'1': 'UserUnauthorized', '2': 24},
    const {'1': 'UserNotExist', '2': 25},
    const {'1': 'InternalError', '2': 100},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSEAoMRW1haWxJc0VtcHR5EAASFgoSRW1haWxGb3JtYXRJbnZhbGlkEAESFgoSRW1haWxBbHJlYWR5RXhpc3RzEAISEwoPUGFzc3dvcmRJc0VtcHR5EAoSEwoPUGFzc3dvcmRUb29Mb25nEAsSJAogUGFzc3dvcmRDb250YWluc0ZvcmJpZENoYXJhY3RlcnMQDBIZChVQYXNzd29yZEZvcm1hdEludmFsaWQQDRIUChBQYXNzd29yZE5vdE1hdGNoEA4SEwoPVXNlck5hbWVUb29Mb25nEBQSJgoiVXNlck5hbWVDb250YWluRm9yYmlkZGVuQ2hhcmFjdGVycxAVEhMKD1VzZXJOYW1lSXNFbXB0eRAWEhEKDVVzZXJJZEludmFsaWQQFxIUChBVc2VyVW5hdXRob3JpemVkEBgSEAoMVXNlck5vdEV4aXN0EBkSEQoNSW50ZXJuYWxFcnJvchBk');
@$core.Deprecated('Use userErrorDescriptor instead')
const UserError$json = const {
  '1': 'UserError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.ErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `UserError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userErrorDescriptor = $convert.base64Decode('CglVc2VyRXJyb3ISHgoEY29kZRgBIAEoDjIKLkVycm9yQ29kZVIEY29kZRIQCgNtc2cYAiABKAlSA21zZw==');
