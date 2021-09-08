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
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserDatabaseInitFailed', '2': 1},
    const {'1': 'AcquireWriteLockedFailed', '2': 2},
    const {'1': 'AcquireReadLockedFailed', '2': 3},
    const {'1': 'UserDatabaseDidNotMatch', '2': 4},
    const {'1': 'EmailIsEmpty', '2': 20},
    const {'1': 'EmailFormatInvalid', '2': 21},
    const {'1': 'EmailAlreadyExists', '2': 22},
    const {'1': 'PasswordIsEmpty', '2': 30},
    const {'1': 'PasswordTooLong', '2': 31},
    const {'1': 'PasswordContainsForbidCharacters', '2': 32},
    const {'1': 'PasswordFormatInvalid', '2': 33},
    const {'1': 'PasswordNotMatch', '2': 34},
    const {'1': 'UserNameTooLong', '2': 40},
    const {'1': 'ContainForbiddenCharacters', '2': 41},
    const {'1': 'UserNameIsEmpty', '2': 42},
    const {'1': 'UserWorkspaceInvalid', '2': 50},
    const {'1': 'UserIdInvalid', '2': 51},
    const {'1': 'UserUnauthorized', '2': 54},
    const {'1': 'UserNotExist', '2': 55},
    const {'1': 'InternalError', '2': 100},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSCwoHVW5rbm93bhAAEhoKFlVzZXJEYXRhYmFzZUluaXRGYWlsZWQQARIcChhBY3F1aXJlV3JpdGVMb2NrZWRGYWlsZWQQAhIbChdBY3F1aXJlUmVhZExvY2tlZEZhaWxlZBADEhsKF1VzZXJEYXRhYmFzZURpZE5vdE1hdGNoEAQSEAoMRW1haWxJc0VtcHR5EBQSFgoSRW1haWxGb3JtYXRJbnZhbGlkEBUSFgoSRW1haWxBbHJlYWR5RXhpc3RzEBYSEwoPUGFzc3dvcmRJc0VtcHR5EB4SEwoPUGFzc3dvcmRUb29Mb25nEB8SJAogUGFzc3dvcmRDb250YWluc0ZvcmJpZENoYXJhY3RlcnMQIBIZChVQYXNzd29yZEZvcm1hdEludmFsaWQQIRIUChBQYXNzd29yZE5vdE1hdGNoECISEwoPVXNlck5hbWVUb29Mb25nECgSHgoaQ29udGFpbkZvcmJpZGRlbkNoYXJhY3RlcnMQKRITCg9Vc2VyTmFtZUlzRW1wdHkQKhIYChRVc2VyV29ya3NwYWNlSW52YWxpZBAyEhEKDVVzZXJJZEludmFsaWQQMxIUChBVc2VyVW5hdXRob3JpemVkEDYSEAoMVXNlck5vdEV4aXN0EDcSEQoNSW50ZXJuYWxFcnJvchBk');
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
