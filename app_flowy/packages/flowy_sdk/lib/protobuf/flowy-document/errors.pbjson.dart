///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use docErrorCodeDescriptor instead')
const DocErrorCode$json = const {
  '1': 'DocErrorCode',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'EditorDBInternalError', '2': 1},
    const {'1': 'EditorDBConnFailed', '2': 2},
    const {'1': 'DocNameInvalid', '2': 10},
    const {'1': 'DocViewIdInvalid', '2': 11},
    const {'1': 'DocDescTooLong', '2': 12},
    const {'1': 'DocOpenFileError', '2': 13},
    const {'1': 'DocFilePathInvalid', '2': 14},
    const {'1': 'EditorUserNotLoginYet', '2': 100},
  ],
};

/// Descriptor for `DocErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List docErrorCodeDescriptor = $convert.base64Decode('CgxEb2NFcnJvckNvZGUSCwoHVW5rbm93bhAAEhkKFUVkaXRvckRCSW50ZXJuYWxFcnJvchABEhYKEkVkaXRvckRCQ29ubkZhaWxlZBACEhIKDkRvY05hbWVJbnZhbGlkEAoSFAoQRG9jVmlld0lkSW52YWxpZBALEhIKDkRvY0Rlc2NUb29Mb25nEAwSFAoQRG9jT3BlbkZpbGVFcnJvchANEhYKEkRvY0ZpbGVQYXRoSW52YWxpZBAOEhkKFUVkaXRvclVzZXJOb3RMb2dpbllldBBk');
@$core.Deprecated('Use docErrorDescriptor instead')
const DocError$json = const {
  '1': 'DocError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.DocErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `DocError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docErrorDescriptor = $convert.base64Decode('CghEb2NFcnJvchIhCgRjb2RlGAEgASgOMg0uRG9jRXJyb3JDb2RlUgRjb2RlEhAKA21zZxgCIAEoCVIDbXNn');
