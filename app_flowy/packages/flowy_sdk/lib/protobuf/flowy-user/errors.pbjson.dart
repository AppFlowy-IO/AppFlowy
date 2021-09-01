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
    const {'1': 'UserDatabaseWriteLocked', '2': 2},
    const {'1': 'UserDatabaseReadLocked', '2': 3},
    const {'1': 'UserDatabaseDidNotMatch', '2': 4},
    const {'1': 'UserDatabaseInternalError', '2': 5},
    const {'1': 'SqlInternalError', '2': 6},
    const {'1': 'DatabaseConnectError', '2': 7},
    const {'1': 'UserNotLoginYet', '2': 10},
    const {'1': 'ReadCurrentIdFailed', '2': 11},
    const {'1': 'WriteCurrentIdFailed', '2': 12},
    const {'1': 'EmailIsEmpty', '2': 20},
    const {'1': 'EmailFormatInvalid', '2': 21},
    const {'1': 'EmailAlreadyExists', '2': 22},
    const {'1': 'PasswordIsEmpty', '2': 30},
    const {'1': 'PasswordTooLong', '2': 31},
    const {'1': 'PasswordContainsForbidCharacters', '2': 32},
    const {'1': 'PasswordFormatInvalid', '2': 33},
    const {'1': 'PasswordNotMatch', '2': 34},
    const {'1': 'UserNameTooLong', '2': 40},
    const {'1': 'UserNameContainsForbiddenCharacters', '2': 41},
    const {'1': 'UserNameIsEmpty', '2': 42},
    const {'1': 'UserWorkspaceInvalid', '2': 50},
    const {'1': 'UserIdInvalid', '2': 51},
    const {'1': 'CreateDefaultWorkspaceFailed', '2': 52},
    const {'1': 'DefaultWorkspaceAlreadyExist', '2': 53},
    const {'1': 'ServerError', '2': 100},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSCwoHVW5rbm93bhAAEhoKFlVzZXJEYXRhYmFzZUluaXRGYWlsZWQQARIbChdVc2VyRGF0YWJhc2VXcml0ZUxvY2tlZBACEhoKFlVzZXJEYXRhYmFzZVJlYWRMb2NrZWQQAxIbChdVc2VyRGF0YWJhc2VEaWROb3RNYXRjaBAEEh0KGVVzZXJEYXRhYmFzZUludGVybmFsRXJyb3IQBRIUChBTcWxJbnRlcm5hbEVycm9yEAYSGAoURGF0YWJhc2VDb25uZWN0RXJyb3IQBxITCg9Vc2VyTm90TG9naW5ZZXQQChIXChNSZWFkQ3VycmVudElkRmFpbGVkEAsSGAoUV3JpdGVDdXJyZW50SWRGYWlsZWQQDBIQCgxFbWFpbElzRW1wdHkQFBIWChJFbWFpbEZvcm1hdEludmFsaWQQFRIWChJFbWFpbEFscmVhZHlFeGlzdHMQFhITCg9QYXNzd29yZElzRW1wdHkQHhITCg9QYXNzd29yZFRvb0xvbmcQHxIkCiBQYXNzd29yZENvbnRhaW5zRm9yYmlkQ2hhcmFjdGVycxAgEhkKFVBhc3N3b3JkRm9ybWF0SW52YWxpZBAhEhQKEFBhc3N3b3JkTm90TWF0Y2gQIhITCg9Vc2VyTmFtZVRvb0xvbmcQKBInCiNVc2VyTmFtZUNvbnRhaW5zRm9yYmlkZGVuQ2hhcmFjdGVycxApEhMKD1VzZXJOYW1lSXNFbXB0eRAqEhgKFFVzZXJXb3Jrc3BhY2VJbnZhbGlkEDISEQoNVXNlcklkSW52YWxpZBAzEiAKHENyZWF0ZURlZmF1bHRXb3Jrc3BhY2VGYWlsZWQQNBIgChxEZWZhdWx0V29ya3NwYWNlQWxyZWFkeUV4aXN0EDUSDwoLU2VydmVyRXJyb3IQZA==');
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
