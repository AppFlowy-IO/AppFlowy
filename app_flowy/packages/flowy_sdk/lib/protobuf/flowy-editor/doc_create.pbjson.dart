///
//  Generated code. Do not modify.
//  source: doc_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createDocRequestDescriptor instead')
const CreateDocRequest$json = const {
  '1': 'CreateDocRequest',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `CreateDocRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDocRequestDescriptor = $convert.base64Decode('ChBDcmVhdGVEb2NSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSEgoEdGV4dBgEIAEoCVIEdGV4dA==');
@$core.Deprecated('Use docInfoDescriptor instead')
const DocInfo$json = const {
  '1': 'DocInfo',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `DocInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docInfoDescriptor = $convert.base64Decode('CgdEb2NJbmZvEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSEgoEcGF0aBgEIAEoCVIEcGF0aA==');
@$core.Deprecated('Use docDataDescriptor instead')
const DocData$json = const {
  '1': 'DocData',
  '2': const [
    const {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `DocData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docDataDescriptor = $convert.base64Decode('CgdEb2NEYXRhEhIKBHRleHQYASABKAlSBHRleHQ=');
