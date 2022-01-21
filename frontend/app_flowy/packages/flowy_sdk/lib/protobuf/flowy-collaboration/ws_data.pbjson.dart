///
//  Generated code. Do not modify.
//  source: ws_data.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use clientRevisionWSDataTypeDescriptor instead')
const ClientRevisionWSDataType$json = const {
  '1': 'ClientRevisionWSDataType',
  '2': const [
    const {'1': 'ClientPushRev', '2': 0},
    const {'1': 'ClientPing', '2': 1},
  ],
};

/// Descriptor for `ClientRevisionWSDataType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List clientRevisionWSDataTypeDescriptor = $convert.base64Decode('ChhDbGllbnRSZXZpc2lvbldTRGF0YVR5cGUSEQoNQ2xpZW50UHVzaFJldhAAEg4KCkNsaWVudFBpbmcQAQ==');
@$core.Deprecated('Use serverRevisionWSDataTypeDescriptor instead')
const ServerRevisionWSDataType$json = const {
  '1': 'ServerRevisionWSDataType',
  '2': const [
    const {'1': 'ServerAck', '2': 0},
    const {'1': 'ServerPushRev', '2': 1},
    const {'1': 'ServerPullRev', '2': 2},
    const {'1': 'UserConnect', '2': 3},
  ],
};

/// Descriptor for `ServerRevisionWSDataType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List serverRevisionWSDataTypeDescriptor = $convert.base64Decode('ChhTZXJ2ZXJSZXZpc2lvbldTRGF0YVR5cGUSDQoJU2VydmVyQWNrEAASEQoNU2VydmVyUHVzaFJldhABEhEKDVNlcnZlclB1bGxSZXYQAhIPCgtVc2VyQ29ubmVjdBAD');
@$core.Deprecated('Use clientRevisionWSDataDescriptor instead')
const ClientRevisionWSData$json = const {
  '1': 'ClientRevisionWSData',
  '2': const [
    const {'1': 'object_id', '3': 1, '4': 1, '5': 9, '10': 'objectId'},
    const {'1': 'ty', '3': 2, '4': 1, '5': 14, '6': '.ClientRevisionWSDataType', '10': 'ty'},
    const {'1': 'revisions', '3': 3, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
    const {'1': 'data_id', '3': 4, '4': 1, '5': 9, '10': 'dataId'},
  ],
};

/// Descriptor for `ClientRevisionWSData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientRevisionWSDataDescriptor = $convert.base64Decode('ChRDbGllbnRSZXZpc2lvbldTRGF0YRIbCglvYmplY3RfaWQYASABKAlSCG9iamVjdElkEikKAnR5GAIgASgOMhkuQ2xpZW50UmV2aXNpb25XU0RhdGFUeXBlUgJ0eRIvCglyZXZpc2lvbnMYAyABKAsyES5SZXBlYXRlZFJldmlzaW9uUglyZXZpc2lvbnMSFwoHZGF0YV9pZBgEIAEoCVIGZGF0YUlk');
@$core.Deprecated('Use serverRevisionWSDataDescriptor instead')
const ServerRevisionWSData$json = const {
  '1': 'ServerRevisionWSData',
  '2': const [
    const {'1': 'object_id', '3': 1, '4': 1, '5': 9, '10': 'objectId'},
    const {'1': 'ty', '3': 2, '4': 1, '5': 14, '6': '.ServerRevisionWSDataType', '10': 'ty'},
    const {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `ServerRevisionWSData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverRevisionWSDataDescriptor = $convert.base64Decode('ChRTZXJ2ZXJSZXZpc2lvbldTRGF0YRIbCglvYmplY3RfaWQYASABKAlSCG9iamVjdElkEikKAnR5GAIgASgOMhkuU2VydmVyUmV2aXNpb25XU0RhdGFUeXBlUgJ0eRISCgRkYXRhGAMgASgMUgRkYXRh');
@$core.Deprecated('Use newDocumentUserDescriptor instead')
const NewDocumentUser$json = const {
  '1': 'NewDocumentUser',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'doc_id', '3': 2, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'revision_data', '3': 3, '4': 1, '5': 12, '10': 'revisionData'},
  ],
};

/// Descriptor for `NewDocumentUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newDocumentUserDescriptor = $convert.base64Decode('Cg9OZXdEb2N1bWVudFVzZXISFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEhUKBmRvY19pZBgCIAEoCVIFZG9jSWQSIwoNcmV2aXNpb25fZGF0YRgDIAEoDFIMcmV2aXNpb25EYXRh');
