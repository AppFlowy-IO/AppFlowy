///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use editorErrorCodeDescriptor instead')
const EditorErrorCode$json = const {
  '1': 'EditorErrorCode',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'EditorDBInternalError', '2': 1},
    const {'1': 'EditorDBConnFailed', '2': 2},
    const {'1': 'DocNameInvalid', '2': 10},
    const {'1': 'DocViewIdInvalid', '2': 11},
    const {'1': 'DocDescTooLong', '2': 12},
    const {'1': 'DocFileError', '2': 13},
  ],
};

/// Descriptor for `EditorErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List editorErrorCodeDescriptor = $convert.base64Decode('Cg9FZGl0b3JFcnJvckNvZGUSCwoHVW5rbm93bhAAEhkKFUVkaXRvckRCSW50ZXJuYWxFcnJvchABEhYKEkVkaXRvckRCQ29ubkZhaWxlZBACEhIKDkRvY05hbWVJbnZhbGlkEAoSFAoQRG9jVmlld0lkSW52YWxpZBALEhIKDkRvY0Rlc2NUb29Mb25nEAwSEAoMRG9jRmlsZUVycm9yEA0=');
@$core.Deprecated('Use editorErrorDescriptor instead')
const EditorError$json = const {
  '1': 'EditorError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.EditorErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `EditorError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editorErrorDescriptor = $convert.base64Decode('CgtFZGl0b3JFcnJvchIkCgRjb2RlGAEgASgOMhAuRWRpdG9yRXJyb3JDb2RlUgRjb2RlEhAKA21zZxgCIAEoCVIDbXNn');
