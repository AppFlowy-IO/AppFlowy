///
//  Generated code. Do not modify.
//  source: ws.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use documentClientWSDataTypeDescriptor instead')
const DocumentClientWSDataType$json = const {
  '1': 'DocumentClientWSDataType',
  '2': const [
    const {'1': 'ClientPushRev', '2': 0},
  ],
};

/// Descriptor for `DocumentClientWSDataType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List documentClientWSDataTypeDescriptor = $convert.base64Decode('ChhEb2N1bWVudENsaWVudFdTRGF0YVR5cGUSEQoNQ2xpZW50UHVzaFJldhAA');
@$core.Deprecated('Use documentServerWSDataTypeDescriptor instead')
const DocumentServerWSDataType$json = const {
  '1': 'DocumentServerWSDataType',
  '2': const [
    const {'1': 'ServerAck', '2': 0},
    const {'1': 'ServerPushRev', '2': 1},
    const {'1': 'ServerPullRev', '2': 2},
    const {'1': 'UserConnect', '2': 3},
  ],
};

/// Descriptor for `DocumentServerWSDataType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List documentServerWSDataTypeDescriptor = $convert.base64Decode('ChhEb2N1bWVudFNlcnZlcldTRGF0YVR5cGUSDQoJU2VydmVyQWNrEAASEQoNU2VydmVyUHVzaFJldhABEhEKDVNlcnZlclB1bGxSZXYQAhIPCgtVc2VyQ29ubmVjdBAD');
@$core.Deprecated('Use documentClientWSDataDescriptor instead')
const DocumentClientWSData$json = const {
  '1': 'DocumentClientWSData',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'ty', '3': 2, '4': 1, '5': 14, '6': '.DocumentClientWSDataType', '10': 'ty'},
    const {'1': 'revisions', '3': 3, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
    const {'1': 'id', '3': 4, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DocumentClientWSData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentClientWSDataDescriptor = $convert.base64Decode('ChREb2N1bWVudENsaWVudFdTRGF0YRIVCgZkb2NfaWQYASABKAlSBWRvY0lkEikKAnR5GAIgASgOMhkuRG9jdW1lbnRDbGllbnRXU0RhdGFUeXBlUgJ0eRIvCglyZXZpc2lvbnMYAyABKAsyES5SZXBlYXRlZFJldmlzaW9uUglyZXZpc2lvbnMSDgoCaWQYBCABKAlSAmlk');
@$core.Deprecated('Use documentServerWSDataDescriptor instead')
const DocumentServerWSData$json = const {
  '1': 'DocumentServerWSData',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'ty', '3': 2, '4': 1, '5': 14, '6': '.DocumentServerWSDataType', '10': 'ty'},
    const {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `DocumentServerWSData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentServerWSDataDescriptor = $convert.base64Decode('ChREb2N1bWVudFNlcnZlcldTRGF0YRIVCgZkb2NfaWQYASABKAlSBWRvY0lkEikKAnR5GAIgASgOMhkuRG9jdW1lbnRTZXJ2ZXJXU0RhdGFUeXBlUgJ0eRISCgRkYXRhGAMgASgMUgRkYXRh');
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
