///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspaceErrorCodeDescriptor instead')
const WorkspaceErrorCode$json = const {
  '1': 'WorkspaceErrorCode',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'WorkspaceNameInvalid', '2': 1},
    const {'1': 'WorkspaceIdInvalid', '2': 2},
    const {'1': 'AppColorStyleInvalid', '2': 3},
    const {'1': 'AppIdInvalid', '2': 4},
    const {'1': 'DatabaseConnectionFail', '2': 5},
    const {'1': 'DatabaseInternalError', '2': 6},
    const {'1': 'UserInternalError', '2': 10},
    const {'1': 'UserNotLoginYet', '2': 11},
  ],
};

/// Descriptor for `WorkspaceErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceErrorCodeDescriptor = $convert.base64Decode('ChJXb3Jrc3BhY2VFcnJvckNvZGUSCwoHVW5rbm93bhAAEhgKFFdvcmtzcGFjZU5hbWVJbnZhbGlkEAESFgoSV29ya3NwYWNlSWRJbnZhbGlkEAISGAoUQXBwQ29sb3JTdHlsZUludmFsaWQQAxIQCgxBcHBJZEludmFsaWQQBBIaChZEYXRhYmFzZUNvbm5lY3Rpb25GYWlsEAUSGQoVRGF0YWJhc2VJbnRlcm5hbEVycm9yEAYSFQoRVXNlckludGVybmFsRXJyb3IQChITCg9Vc2VyTm90TG9naW5ZZXQQCw==');
@$core.Deprecated('Use workspaceErrorDescriptor instead')
const WorkspaceError$json = const {
  '1': 'WorkspaceError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.WorkspaceErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `WorkspaceError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceErrorDescriptor = $convert.base64Decode('Cg5Xb3Jrc3BhY2VFcnJvchInCgRjb2RlGAEgASgOMhMuV29ya3NwYWNlRXJyb3JDb2RlUgRjb2RlEhAKA21zZxgCIAEoCVIDbXNn');
