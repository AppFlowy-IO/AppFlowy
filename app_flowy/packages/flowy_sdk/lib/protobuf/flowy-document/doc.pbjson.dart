///
//  Generated code. Do not modify.
//  source: doc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createDocParamsDescriptor instead')
const CreateDocParams$json = const {
  '1': 'CreateDocParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `CreateDocParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDocParamsDescriptor = $convert.base64Decode('Cg9DcmVhdGVEb2NQYXJhbXMSDgoCaWQYASABKAlSAmlkEhIKBGRhdGEYAiABKAxSBGRhdGE=');
@$core.Deprecated('Use docDescriptor instead')
const Doc$json = const {
  '1': 'Doc',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
    const {'1': 'revision', '3': 3, '4': 1, '5': 3, '10': 'revision'},
  ],
};

/// Descriptor for `Doc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docDescriptor = $convert.base64Decode('CgNEb2MSDgoCaWQYASABKAlSAmlkEhIKBGRhdGEYAiABKAxSBGRhdGESGgoIcmV2aXNpb24YAyABKANSCHJldmlzaW9u');
@$core.Deprecated('Use updateDocParamsDescriptor instead')
const UpdateDocParams$json = const {
  '1': 'UpdateDocParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'doc_data', '3': 2, '4': 1, '5': 12, '10': 'docData'},
  ],
};

/// Descriptor for `UpdateDocParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateDocParamsDescriptor = $convert.base64Decode('Cg9VcGRhdGVEb2NQYXJhbXMSDgoCaWQYASABKAlSAmlkEhkKCGRvY19kYXRhGAIgASgMUgdkb2NEYXRh');
@$core.Deprecated('Use docChangesetDescriptor instead')
const DocChangeset$json = const {
  '1': 'DocChangeset',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `DocChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docChangesetDescriptor = $convert.base64Decode('CgxEb2NDaGFuZ2VzZXQSDgoCaWQYASABKAlSAmlkEhIKBGRhdGEYAiABKAxSBGRhdGE=');
@$core.Deprecated('Use queryDocParamsDescriptor instead')
const QueryDocParams$json = const {
  '1': 'QueryDocParams',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
  ],
};

/// Descriptor for `QueryDocParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryDocParamsDescriptor = $convert.base64Decode('Cg5RdWVyeURvY1BhcmFtcxIVCgZkb2NfaWQYASABKAlSBWRvY0lk');
