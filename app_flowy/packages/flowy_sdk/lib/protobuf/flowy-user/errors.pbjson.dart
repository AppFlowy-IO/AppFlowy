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
    const {'1': 'UserTokenInvalid', '2': 54},
    const {'1': 'UserNotExist', '2': 55},
    const {'1': 'CreateDefaultWorkspaceFailed', '2': 60},
    const {'1': 'DefaultWorkspaceAlreadyExist', '2': 61},
    const {'1': 'ServerError', '2': 100},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSCwoHVW5rbm93bhAAEhoKFlVzZXJEYXRhYmFzZUluaXRGYWlsZWQQARIcChhBY3F1aXJlV3JpdGVMb2NrZWRGYWlsZWQQAhIbChdBY3F1aXJlUmVhZExvY2tlZEZhaWxlZBADEhsKF1VzZXJEYXRhYmFzZURpZE5vdE1hdGNoEAQSHQoZVXNlckRhdGFiYXNlSW50ZXJuYWxFcnJvchAFEhQKEFNxbEludGVybmFsRXJyb3IQBhIYChREYXRhYmFzZUNvbm5lY3RFcnJvchAHEhMKD1VzZXJOb3RMb2dpbllldBAKEhcKE1JlYWRDdXJyZW50SWRGYWlsZWQQCxIYChRXcml0ZUN1cnJlbnRJZEZhaWxlZBAMEhAKDEVtYWlsSXNFbXB0eRAUEhYKEkVtYWlsRm9ybWF0SW52YWxpZBAVEhYKEkVtYWlsQWxyZWFkeUV4aXN0cxAWEhMKD1Bhc3N3b3JkSXNFbXB0eRAeEhMKD1Bhc3N3b3JkVG9vTG9uZxAfEiQKIFBhc3N3b3JkQ29udGFpbnNGb3JiaWRDaGFyYWN0ZXJzECASGQoVUGFzc3dvcmRGb3JtYXRJbnZhbGlkECESFAoQUGFzc3dvcmROb3RNYXRjaBAiEhMKD1VzZXJOYW1lVG9vTG9uZxAoEicKI1VzZXJOYW1lQ29udGFpbnNGb3JiaWRkZW5DaGFyYWN0ZXJzECkSEwoPVXNlck5hbWVJc0VtcHR5ECoSGAoUVXNlcldvcmtzcGFjZUludmFsaWQQMhIRCg1Vc2VySWRJbnZhbGlkEDMSFAoQVXNlclRva2VuSW52YWxpZBA2EhAKDFVzZXJOb3RFeGlzdBA3EiAKHENyZWF0ZURlZmF1bHRXb3Jrc3BhY2VGYWlsZWQQPBIgChxEZWZhdWx0V29ya3NwYWNlQWxyZWFkeUV4aXN0ED0SDwoLU2VydmVyRXJyb3IQZA==');
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
