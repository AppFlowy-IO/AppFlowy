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
    const {'1': 'WorkspaceNameInvalid', '2': 0},
    const {'1': 'WorkspaceIdInvalid', '2': 1},
    const {'1': 'AppColorStyleInvalid', '2': 2},
    const {'1': 'WorkspaceDescInvalid', '2': 3},
    const {'1': 'AppIdInvalid', '2': 10},
    const {'1': 'AppNameInvalid', '2': 11},
    const {'1': 'ViewNameInvalid', '2': 20},
    const {'1': 'ViewThumbnailInvalid', '2': 21},
    const {'1': 'ViewIdInvalid', '2': 22},
    const {'1': 'ViewDescInvalid', '2': 23},
    const {'1': 'ViewDataInvalid', '2': 24},
    const {'1': 'UserUnauthorized', '2': 100},
    const {'1': 'InternalError', '2': 1000},
    const {'1': 'RecordNotFound', '2': 1001},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSGAoUV29ya3NwYWNlTmFtZUludmFsaWQQABIWChJXb3Jrc3BhY2VJZEludmFsaWQQARIYChRBcHBDb2xvclN0eWxlSW52YWxpZBACEhgKFFdvcmtzcGFjZURlc2NJbnZhbGlkEAMSEAoMQXBwSWRJbnZhbGlkEAoSEgoOQXBwTmFtZUludmFsaWQQCxITCg9WaWV3TmFtZUludmFsaWQQFBIYChRWaWV3VGh1bWJuYWlsSW52YWxpZBAVEhEKDVZpZXdJZEludmFsaWQQFhITCg9WaWV3RGVzY0ludmFsaWQQFxITCg9WaWV3RGF0YUludmFsaWQQGBIUChBVc2VyVW5hdXRob3JpemVkEGQSEgoNSW50ZXJuYWxFcnJvchDoBxITCg5SZWNvcmROb3RGb3VuZBDpBw==');
@$core.Deprecated('Use workspaceErrorDescriptor instead')
const WorkspaceError$json = const {
  '1': 'WorkspaceError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.ErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

/// Descriptor for `WorkspaceError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceErrorDescriptor = $convert.base64Decode('Cg5Xb3Jrc3BhY2VFcnJvchIeCgRjb2RlGAEgASgOMgouRXJyb3JDb2RlUgRjb2RlEhAKA21zZxgCIAEoCVIDbXNn');
