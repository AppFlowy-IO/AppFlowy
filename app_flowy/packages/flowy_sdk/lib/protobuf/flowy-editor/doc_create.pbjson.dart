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
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreateDocRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDocRequestDescriptor = $convert.base64Decode('ChBDcmVhdGVEb2NSZXF1ZXN0EhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBISCgRuYW1lGAIgASgJUgRuYW1l');
@$core.Deprecated('Use docDescriptor instead')
const Doc$json = const {
  '1': 'Doc',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'view_id', '3': 3, '4': 1, '5': 9, '10': 'viewId'},
  ],
};

/// Descriptor for `Doc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docDescriptor = $convert.base64Decode('CgNEb2MSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSFwoHdmlld19pZBgDIAEoCVIGdmlld0lk');
