///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userErrCodeDescriptor instead')
const UserErrCode$json = const {
  '1': 'UserErrCode',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserDatabaseInitFailed', '2': 1},
    const {'1': 'UserDatabaseWriteLocked', '2': 2},
    const {'1': 'UserDatabaseReadLocked', '2': 3},
    const {'1': 'UserDatabaseDidNotMatch', '2': 4},
    const {'1': 'UserDatabaseInternalError', '2': 5},
    const {'1': 'SqlInternalError', '2': 6},
    const {'1': 'UserNotLoginYet', '2': 10},
    const {'1': 'ReadCurrentIdFailed', '2': 11},
    const {'1': 'WriteCurrentIdFailed', '2': 12},
    const {'1': 'EmailInvalid', '2': 20},
    const {'1': 'PasswordInvalid', '2': 21},
    const {'1': 'UserNameInvalid', '2': 22},
    const {'1': 'UserWorkspaceInvalid', '2': 23},
    const {'1': 'UserIdInvalid', '2': 24},
    const {'1': 'CreateDefaultWorkspaceFailed', '2': 25},
    const {'1': 'DefaultWorkspaceAlreadyExist', '2': 26},
    const {'1': 'NetworkError', '2': 100},
  ],
};

/// Descriptor for `UserErrCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userErrCodeDescriptor = $convert.base64Decode('CgtVc2VyRXJyQ29kZRILCgdVbmtub3duEAASGgoWVXNlckRhdGFiYXNlSW5pdEZhaWxlZBABEhsKF1VzZXJEYXRhYmFzZVdyaXRlTG9ja2VkEAISGgoWVXNlckRhdGFiYXNlUmVhZExvY2tlZBADEhsKF1VzZXJEYXRhYmFzZURpZE5vdE1hdGNoEAQSHQoZVXNlckRhdGFiYXNlSW50ZXJuYWxFcnJvchAFEhQKEFNxbEludGVybmFsRXJyb3IQBhITCg9Vc2VyTm90TG9naW5ZZXQQChIXChNSZWFkQ3VycmVudElkRmFpbGVkEAsSGAoUV3JpdGVDdXJyZW50SWRGYWlsZWQQDBIQCgxFbWFpbEludmFsaWQQFBITCg9QYXNzd29yZEludmFsaWQQFRITCg9Vc2VyTmFtZUludmFsaWQQFhIYChRVc2VyV29ya3NwYWNlSW52YWxpZBAXEhEKDVVzZXJJZEludmFsaWQQGBIgChxDcmVhdGVEZWZhdWx0V29ya3NwYWNlRmFpbGVkEBkSIAocRGVmYXVsdFdvcmtzcGFjZUFscmVhZHlFeGlzdBAaEhAKDE5ldHdvcmtFcnJvchBk');
@$core.Deprecated('Use userErrorDescriptor instead')
const UserError$json = const {
  '1': 'UserError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.UserErrCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `UserError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userErrorDescriptor = $convert.base64Decode('CglVc2VyRXJyb3ISIAoEY29kZRgBIAEoDjIMLlVzZXJFcnJDb2RlUgRjb2RlEhAKA21zZxgCIAEoCVIDbXNn');
