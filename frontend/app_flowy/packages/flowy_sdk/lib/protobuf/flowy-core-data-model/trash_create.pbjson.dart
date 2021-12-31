///
//  Generated code. Do not modify.
//  source: trash_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use trashTypeDescriptor instead')
const TrashType$json = const {
  '1': 'TrashType',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'View', '2': 1},
    const {'1': 'App', '2': 2},
  ],
};

/// Descriptor for `TrashType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trashTypeDescriptor = $convert.base64Decode('CglUcmFzaFR5cGUSCwoHVW5rbm93bhAAEggKBFZpZXcQARIHCgNBcHAQAg==');
@$core.Deprecated('Use repeatedTrashIdDescriptor instead')
const RepeatedTrashId$json = const {
  '1': 'RepeatedTrashId',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.TrashId', '10': 'items'},
    const {'1': 'delete_all', '3': 2, '4': 1, '5': 8, '10': 'deleteAll'},
  ],
};

/// Descriptor for `RepeatedTrashId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedTrashIdDescriptor = $convert.base64Decode('Cg9SZXBlYXRlZFRyYXNoSWQSHgoFaXRlbXMYASADKAsyCC5UcmFzaElkUgVpdGVtcxIdCgpkZWxldGVfYWxsGAIgASgIUglkZWxldGVBbGw=');
@$core.Deprecated('Use trashIdDescriptor instead')
const TrashId$json = const {
  '1': 'TrashId',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'ty', '3': 2, '4': 1, '5': 14, '6': '.TrashType', '10': 'ty'},
  ],
};

/// Descriptor for `TrashId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trashIdDescriptor = $convert.base64Decode('CgdUcmFzaElkEg4KAmlkGAEgASgJUgJpZBIaCgJ0eRgCIAEoDjIKLlRyYXNoVHlwZVICdHk=');
@$core.Deprecated('Use trashDescriptor instead')
const Trash$json = const {
  '1': 'Trash',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'modified_time', '3': 3, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 4, '4': 1, '5': 3, '10': 'createTime'},
    const {'1': 'ty', '3': 5, '4': 1, '5': 14, '6': '.TrashType', '10': 'ty'},
  ],
};

/// Descriptor for `Trash`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trashDescriptor = $convert.base64Decode('CgVUcmFzaBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIjCg1tb2RpZmllZF90aW1lGAMgASgDUgxtb2RpZmllZFRpbWUSHwoLY3JlYXRlX3RpbWUYBCABKANSCmNyZWF0ZVRpbWUSGgoCdHkYBSABKA4yCi5UcmFzaFR5cGVSAnR5');
@$core.Deprecated('Use repeatedTrashDescriptor instead')
const RepeatedTrash$json = const {
  '1': 'RepeatedTrash',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Trash', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedTrash`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedTrashDescriptor = $convert.base64Decode('Cg1SZXBlYXRlZFRyYXNoEhwKBWl0ZW1zGAEgAygLMgYuVHJhc2hSBWl0ZW1z');
